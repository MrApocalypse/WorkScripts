Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

Write-Verbose -Message "Killing Explorer before fun!"
#Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoRestartShell -Value 0
Stop-Process -ProcessName explorer -Force

If (Test-Path "C:\parktv\ptv2.xml" -PathType Leaf) { 
Write-Host "Config file found!"
Write-Host "Loading values!"
[xml]$ConfigFile = Get-Content "C:\parktv\ptv2.xml"
$gfs = $ConfigFile.Settings.GFS.Path
} Else { 
Write-Host "Config file missing, using defaults!"
$gfs = "J:\Team Drives\ParkTV\ParkTV-100-Houston"
}



#region begin GUI{ 

$Form = New-Object system.Windows.Forms.Form
$Form.ClientSize = '408,523'
$Form.text = "PTV2"
$Form.TopMost = $false
$Form.StartPosition = 'CenterScreen'
$Form.FormBorderStyle = 'Fixed3D'
$Form.MaximizeBox = $false

$actLabel = New-Object system.Windows.Forms.Label
$actLabel.text = "Actions"
$actLabel.AutoSize = $true
$actLabel.width = 25
$actLabel.height = 10
$actLabel.location = New-Object System.Drawing.Point(9, 8)
$actLabel.Font = 'Microsoft Sans Serif,12,style=Bold,Underline'

$grabit = New-Object system.Windows.Forms.Button
$grabit.text = "grab latest from gfs!"
$grabit.width = 142
$grabit.height = 40
$grabit.location = New-Object System.Drawing.Point(8, 32)
$grabit.Font = 'Microsoft Sans Serif,10'

$runit = New-Object system.Windows.Forms.Button
$runit.text = "run it!"
$runit.width = 205
$runit.height = 37
$runit.location = New-Object System.Drawing.Point(9, 79)
$runit.Font = 'Microsoft Sans Serif,10'

If (Test-Path "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe" -PathType Leaf) { 
Write-Host "Yay! I found VLC!"
[xml]$ConfigFile = Get-Content "C:\parktv\ptv2.xml"
$gfs = $ConfigFile.Settings.GFS.Path
} Else { 
Write-Host "VLC not found, install it!"
$runit.Enabled = $false
$runit.text = "VLC not found, install it!"
}


$Form.controls.AddRange(@($actLabel, $grabit,$runit))

#region gui events {
$runit.Add_Click( { 
        $ErrorActionPreference = 'silentlycontinue'
        $theargs = 'C:\Users\cedwards.PARK\Videos\parktv\', '--fullscreen', '--no-mouse-events', '--loop', '--no-osd', '--qt-continue=0', '--video-on-top', '--disable-screensaver', '--image-duration=20'
        Start-Process -FilePath "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe" -ArgumentList $theargs
})
$grabit.Add_Click( { 
        $ErrorActionPreference = 'silentlycontinue'
        #robocopy "J:\Team Drives\ParkTV\ParkTV-100-Houston" "C:\Users\cedwards.PARK\Videos\parktv" /e /z /SEC /MIR
        
        Copy-WithProgress -Source $gfs -Destination "C:\Users\cedwards.PARK\Videos\parktv"
        #Copy-WithProgress -Source "J:\Team Drives\ParkTV\ParkTV-100-Houston" -Destination "C:\Users\cedwards.PARK\Videos\parktv"
})

Function Get-Folder($initialDirectory)

{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select a folder"
    $foldername.rootfolder = "MyComputer"

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
    }
    return $folder
}

function Copy-WithProgress {
    [CmdletBinding()]
    param (
            [Parameter(Mandatory = $true)]
            [string] $Source
        , [Parameter(Mandatory = $true)]
            [string] $Destination
        , [int] $Gap = 200
        , [int] $ReportGap = 2000
    )
    # Define regular expression that will gather number of bytes copied
    $RegexBytes = '(?<=\s+)\d+(?=\s+)';

    #region Robocopy params
    # MIR = Mirror mode
    # NP  = Don't show progress percentage in log
    # NC  = Don't log file classes (existing, new file, etc.)
    # BYTES = Show file sizes in bytes
    # NJH = Do not display robocopy job header (JH)
    # NJS = Do not display robocopy job summary (JS)
    # TEE = Display log in stdout AND in target log file
    $CommonRobocopyParams = '/MIR /NP /NDL /NC /BYTES /NJH /NJS /SEC /e /z';
    #endregion Robocopy params

    #region Robocopy Staging
    Write-Verbose -Message 'Analyzing robocopy job ...';
    $StagingLogPath = '{0}\temp\{1} robocopy staging.log' -f $env:windir, (Get-Date -Format 'yyyy-MM-dd HH-mm-ss');

    $StagingArgumentList = '"{0}" "{1}" /LOG:"{2}" /L {3}' -f $Source, $Destination, $StagingLogPath, $CommonRobocopyParams;
    Write-Verbose -Message ('Staging arguments: {0}' -f $StagingArgumentList);
    Start-Process -Wait -FilePath robocopy.exe -ArgumentList $StagingArgumentList -NoNewWindow;
    # Get the total number of files that will be copied
    $StagingContent = Get-Content -Path $StagingLogPath;
    $TotalFileCount = $StagingContent.Count - 1;

    # Get the total number of bytes to be copied
    [RegEx]::Matches(($StagingContent -join "`n"), $RegexBytes) | % { $BytesTotal = 0; } { $BytesTotal += $_.Value; };
    Write-Verbose -Message ('Total bytes to be copied: {0}' -f $BytesTotal);
    #endregion Robocopy Staging

    #region Start Robocopy
    # Begin the robocopy process
    $RobocopyLogPath = '{0}\temp\{1} robocopy.log' -f $env:windir, (Get-Date -Format 'yyyy-MM-dd HH-mm-ss');
    $ArgumentList = '"{0}" "{1}" /LOG:"{2}" /ipg:{3} {4}' -f $Source, $Destination, $RobocopyLogPath, $Gap, $CommonRobocopyParams;
    Write-Verbose -Message ('Beginning the robocopy process with arguments: {0}' -f $ArgumentList);
    $Robocopy = Start-Process -FilePath robocopy.exe -ArgumentList $ArgumentList -Verbose -PassThru -NoNewWindow;
    Start-Sleep -Milliseconds 100;
    #endregion Start Robocopy

    #region Progress bar loop
    while (!$Robocopy.HasExited) {
        Start-Sleep -Milliseconds $ReportGap;
        $BytesCopied = 0;
        $LogContent = Get-Content -Path $RobocopyLogPath;
        $BytesCopied = [Regex]::Matches($LogContent, $RegexBytes) | ForEach-Object -Process { $BytesCopied += $_.Value; } -End { $BytesCopied; };
        $CopiedFileCount = $LogContent.Count - 1;
        Write-Verbose -Message ('Bytes copied: {0}' -f $BytesCopied);
        Write-Verbose -Message ('Files copied: {0}' -f $LogContent.Count);
        $Percentage = 0;
        if ($BytesCopied -gt 0) {
           $Percentage = (($BytesCopied/$BytesTotal)*100)
        }
        Write-Progress -Activity Robocopy -Status ("Copied {0} of {1} files; Copied {2} of {3} bytes" -f $CopiedFileCount, $TotalFileCount, $BytesCopied, $BytesTotal) -PercentComplete $Percentage
    }
    #endregion Progress loop

    #region Function output
    [PSCustomObject]@{
        BytesCopied = $BytesCopied;
        FilesCopied = $CopiedFileCount;
    };
    #endregion Function output
}

[void]$Form.ShowDialog()