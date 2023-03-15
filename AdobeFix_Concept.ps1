$osver = (Get-WmiObject Win32_OperatingSystem).Version
elevate
function Show-Menu
{
    param (
        [string]$Title = 'AdobeFix'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    Write-Host "1: Install Acrobat DC and Creative Cloud"
    Write-Host "2: Remove old Acrobat 2017"
    Write-Host "3: Perform Windows 7 Hotfix for Creative Cloud"
    Write-Host "A: Run this as Admin"
    Write-Host "Q: Press 'Q' to quit."
}

function removeAcro2017
{
        Write-Host "Please wait..."
        try {
        killOfficeApps
            
        } catch {

        } finally {
           Write-Host "Executing Acrobat 2017 uninstaller..."
           Start-Process "C:\Windows\System32\msiexec.exe" ` -ArgumentList "/x {AC76BA86-1033-FFFF-7760-0E1108756300} /passive /norestart" -Wait
           ##Start-Process "C:\Windows\System32\msiexec.exe" ` -ArgumentList "/x $($product.IdentifyingNumber) /quiet /noreboot" -Wait

        }
}
function Delete-VMs
{
        Write-Host "Script Block to Delete VM"
}

function killOfficeApps {
Write-Host "Closing Office processes if they're open..."
##Get-Process winword | Stop-Process -Force -Wait | Out-Null

@("Winword","Outlook","Excel","PowerPnt") | 
    Foreach-Object {
    if (Get-Process $_ -ErrorAction SilentlyContinue) { 
       Write-Output "$_ is running, killing..."
       Get-Process $_ | Stop-Process -Force
    } else { 
       Write-Output "$_ is not running" 
    }
 }

}

function win7hotfix {
    if ($osver -eq "6.1.7601") {
        $hotfixURL = "https://download.microsoft.com/download/0/6/5/0658B1A7-6D2E-474F-BC2C-D69E5B9E9A68/MicrosoftEasyFix51044.msi"
        $outPath = "$env:HOMEDRIVE\$env:HOMEPATH\temp"
        $outFile = "$env:HOMEDRIVE\$env:HOMEPATH\temp\MicrosoftEasyFix51044.msi"
        mkdir $outPath -Force
        Write-Host "Downloading Hotfix from Microsoft"
        (New-Object System.Net.WebClient).DownloadFile($hotfixURL, $outFile)
        Write-Host "Executing Hotfix silently!" 
        & $outFile /passive
        
        ##Start-Process "C:\Windows\System32\msiexec.exe" -ArgumentList '/i $outFile' 
        

    } else {
        Write-Host "This doesn't look like Windows 7, hotfix isn't compatible!"
    }
}

function elevate {
# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
 if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
  $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
  Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
  Exit
 }
}
}

if ($osver -eq "6.1.7601") {
do
{
    Show-Menu –Title 'AdobeFix v0.1'
    $input = Read-Host "what do you want to do?"
    switch ($input)
    {
        '1' {               
                Down-Inst
            }
        '2' {
                removeAcro2017
            }
        '3' {
                win7hotfix
            }
        'q' {
                 return
            }
    }
}
until ($input -eq 'q')
} else {
do
{
    Show-Menu –Title 'AdobeFix v0.1'
    $input = Read-Host "what do you want to do?"
    switch ($input)
    {
        '1' {               
                Down-Inst
            }
        '2' {
                removeAcro2017
            }
        '3' {
                win7hotfix
            }
        'a' {
                elevate
            }
        'q' {
                 return
            }
    }
    pause
}
until ($input -eq 'q')
}
