#New-Item -Path Registry::HKEY_LOCAL_MACHINE\Software\Policies\Google\DriveFS
$docsDir = [Environment]::GetFolderPath('MyDocuments')

Function vlc-dl-install {
$vlcURL = "https://download.videolan.org/vlc/last/win32/"
$getHTML = (New-Object System.Net.WebClient).DownloadString($vlcURL)
$name = if ($getHTML -match '.+>(vlc-.+\.exe)<.+')
        {
          $Matches[1]
        }
 
$vlcURL = "https://download.videolan.org/vlc/last/win32/$name"
 
$outPath = "$env:HOMEDRIVE\$env:HOMEPATH\temp"
$outFile = "$env:HOMEDRIVE\$env:HOMEPATH\temp\vlc_installer.exe"
 
mkdir $outPath -Force
Write-Host "Downloading latest VLC!"
(New-Object System.Net.WebClient).DownloadFile($vlcURL, $outFile)

Write-Host "Executing VLC installer silently!" 
& $outFile /L=1033 /S
}

Function vlc-custom-config {
Write-Host "Attempting to configure VLC!"
Start-Sleep -s 4
If (Test-Path "\\n-pehq-fsvr-000\Users2\Corey Edwards\parktv\vlcrc" -PathType Leaf) { 
Write-Host "VLC config files found on network, copying to APPDATA!"
Start-Sleep -s 3
$roamingPath = $env:APPDATA
$vlcConfigPath = $roamingPath + '\vlc\vlcrc'
Copy-Item -Path "\\n-pehq-fsvr-000\Users2\Corey Edwards\parktv\vlcrc" -Destination $vlcConfigPath 
Copy-Item -Path "\\n-pehq-fsvr-000\Users2\Corey Edwards\parktv\vlcrc" -Destination $docsDir #send a backup to Docs folder in case net version isnt found
}  Else {
Write-Host "VLC config file not found on network, falling back to local backup."
$docBackupPath = $docsDir + '\vlcrc'
Copy-Item -Path $docBackupPath -Destination $vlcConfigPath
}
}

Function dl-install-gfs {
Write-Host "Downloading Google File Stream!"
$gfsURL = "https://dl.google.com/drive-file-stream/GoogleDriveFSSetup.exe"

$outPath2 = "$env:HOMEDRIVE\$env:HOMEPATH\temp"
$outFile2 = "$env:HOMEDRIVE\$env:HOMEPATH\temp\gfs_installer.exe"

(New-Object System.Net.WebClient).DownloadFile($gfsURL, $outFile2)

Write-Host "Executing GFS installer silently!" 
& $outFile2 --silent --desktop_shortcut
}

Function configure-gfs {
Write-Host "Attempting to configure GFS via Registry!"
Start-Sleep -s 8
New-Item -Path HKLM:\SOFTWARE\Policies\ -Name "Google"
New-Item -Path HKLM:\SOFTWARE\Policies\Google -Name "DriveFS"
Write-Host "Forcing Mounted Drive letter to J!"
Start-Sleep -s 2
New-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\Software\Policies\Google\DriveFS -Name DefaultMountPoint -Value J: -PropertyType String -Force
Write-Host "Forcing GFS to always start with Windows!"
New-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\Software\Policies\Google\DriveFS -Name AutoStartOnLogin -Value 1 -PropertyType DWord -Force
}

Function disable-winUp {
Write-Host "BITS Service"
Start-Sleep -s 5
Set-Service -Name bits -Status Stopped
Write-Host "Stopping  Windows Update Service"
Start-Sleep -s 5
Set-Service -Name wuauserv -Status Stopped
Write-Host "Disabling Windows Update Service"
Start-Sleep -s 3
Set-Service -Name wuauserv -StartupType Disabled

Write-Output "Disabling Windows Update automatic restart..."
Start-Sleep -s 3
If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Type DWord -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -Type DWord -Value 0

Write-Host "Disabling Windows Update scheduled tasks!"
Get-ScheduledTask -TaskPath "\Microsoft\Windows\WindowsUpdate\" | Disable-ScheduledTask

Write-Host "Crippling Update Orchestrator Service Tasks!"
Start-Sleep -s 3
takeown /F C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator /A /R
icacls C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator /grant Administrators:F /T
ren C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Reboot C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Reboot.bak
ren 'C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Schedule Scan' 'C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Schedule Scan.bak'

Write-Host "Disabling Windows Update Medic Service"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" -Name "Start" -Type Dword -Value 4
}

Function run-wub {
Write-Host "Preparing to kill Windows Update services 4eva!"
If (Test-Path "C:\cdescripts\") { #if directory is there
Remove-Item "C:\cdescripts\*.*"
Remove-Item "C:\cdescripts\*" #clear dir
} else { #if it isn't
New-Item -ItemType directory -Path C:\cdescripts    #create it
}
Write-Host "Copying WUB from network!"
Start-Sleep -s 3
Copy-Item -Path "\\n-pehq-fsvr-000\Users2\Corey Edwards\parktv\Wub_11\*.*" -Destination "C:\cdescripts\"
Write-Host "Executing WUB siletely"
& C:\cdescripts\Wub.exe /D /P
Start-Sleep -s 3
}

Function disable-various {
Write-Output "Disabling Action Center (Notification Center)..."
	If (!(Test-Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer")) {
		New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" | Out-Null
	}
	Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Type DWord -Value 1
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type DWord -Value 0
Write-Output "Disabling Aero Shake..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DisallowShaking" -Type DWord -Value 1
Write-Output "Disabling OneDrive..."
	If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive")) {
		New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" | Out-Null
	}
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Type DWord -Value 1
Write-Output "Disabling Telemetry..."
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
	If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds")) {
		New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" -Force | Out-Null
	}
	Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" -Name "AllowBuildPreview" -Type DWord -Value 0
	Disable-ScheduledTask -TaskName "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" | Out-Null
	Disable-ScheduledTask -TaskName "Microsoft\Windows\Application Experience\ProgramDataUpdater" | Out-Null
	Disable-ScheduledTask -TaskName "Microsoft\Windows\Autochk\Proxy" | Out-Null
	Disable-ScheduledTask -TaskName "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" | Out-Null
	Disable-ScheduledTask -TaskName "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" | Out-Null
Write-Output "Disabling Background application access..."
	Get-ChildItem -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Exclude "Microsoft.Windows.Cortana*","Microsoft.Windows.ShellExperienceHost*" | ForEach-Object {
		Set-ItemProperty -Path $_.PsPath -Name "Disabled" -Type DWord -Value 1
		Set-ItemProperty -Path $_.PsPath -Name "DisabledByUser" -Type DWord -Value 1
    }
Write-Output "Disabling Cortana..."
	If (!(Test-Path "HKCU:\Software\Microsoft\Personalization\Settings")) {
		New-Item -Path "HKCU:\Software\Microsoft\Personalization\Settings" -Force | Out-Null
	}
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -Type DWord -Value 0
	If (!(Test-Path "HKCU:\Software\Microsoft\InputPersonalization")) {
		New-Item -Path "HKCU:\Software\Microsoft\InputPersonalization" -Force | Out-Null
	}
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Type DWord -Value 1
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Type DWord -Value 1
	If (!(Test-Path "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore")) {
		New-Item -Path "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" -Force | Out-Null
	}
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -Type DWord -Value 0
	If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search")) {
		New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
	}
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Type DWord -Value 0

Write-Output "Disabling display and sleep mode timeouts..."
	powercfg /X monitor-timeout-ac 0
	powercfg /X monitor-timeout-dc 0
	powercfg /X standby-timeout-ac 0
    powercfg /X standby-timeout-dc 0

Write-Output "Disabling System Restore for system drive..."
    Disable-ComputerRestore -Drive "$env:SYSTEMDRIVE"

Write-Output "Disabling display and sleep mode timeouts..."
	powercfg /X monitor-timeout-ac 0
	powercfg /X monitor-timeout-dc 0
	powercfg /X standby-timeout-ac 0
     powercfg /X standby-timeout-dc 0
}

Function enable-various {
Write-Output "Enabling F8 boot menu options..."
    bcdedit /set `{current`} BootMenuPolicy Legacy | Out-Null

Write-Output "Enabling Remote Desktop w/o Network Level Authentication..."
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "DenyTSConnections" -Type DWord -Value 0
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Type DWord -Value 0
    Enable-NetFirewallRule -Name "RemoteDesktop*"
}

Write-Host "(C) Copyright Corey Edwards 2018-2019. All Rights Reserved"
Start-Sleep -s 5
Write-Host "  ********************PTV2 - Init********************  "
Start-Sleep -s 3
vlc-dl-install
vlc-custom-config
dl-install-gfs
configure-gfs
disable-winUp
disable-various
enable-various

exit