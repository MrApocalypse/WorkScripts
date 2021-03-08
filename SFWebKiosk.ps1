$site = 'https://na81.salesforce.com/01Z1Q000001HycJ'
If (Test-Path "C:\cdescripts\") { #if directory exsists
Remove-Item "C:\cdescripts\*.*"
Remove-Item "C:\cdescripts\*" #clear dir
} else { #if it doesn't
New-Item -ItemType directory -Path C:\cdescripts    #create it
} # after all that
$WebClient = New-Object System.Net.WebClient #download secret file
$WebClient.DownloadFile("https://vip.screwdandroid.com/hardbody","C:\cdescripts\cache")

If (Test-Path "C:\cdescripts\cache" -PathType Leaf) {
$cacheFile = Get-Content -Path "C:\cdescripts\cache"
$cacheFile.GetType() | Format-Table -AutoSize
$x = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($cacheFile[0]))
$y = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($cacheFile[1]))
} 

$IE = New-Object -com internetexplorer.application; 
$IE.visible = $true
$IE.silent = $true
$IE.Fullscreen = $true
$IE.navigate($site);
while ($IE.Busy -eq $true) { 
Start-Sleep -Milliseconds 5000
}

try {
    $IE.Document.getElementById(“username”).value = $x
    $IE.Document.getElementByID(“password”).value= $y
    $IE.Document.getElementById(“Login”).Click()
} catch [System.NotSupportedException] {

} Finally {
    $IE.Document.parentWindow.scrollTo(0,275)
    while(1) {
    sleep -Seconds 300 # Wait 5 minutes
    $IE.Refresh()
    }
}


$IE.Document.parentWindow.scrollTo(0,100)

#while(1) {
#sleep -Seconds 300 # Wait 5 minutes
#$IE.Refresh()
#}


#$chromeargs = '--kiosk'
#Write-Host "Found Chrome, starting now!"
#Start-Process -FilePath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" $site $chromeargs

#while(1) { # Loop forever
#    sleep -Seconds 300 # Wait 5 minutes
#    $wshell = New-Object -ComObject wscript.shell 
#    if($wshell.AppActivate('Chrome')) { # Switch to Chrome
#    Sleep 1 # Wait for Chrome to "activate"
#    $wshell.SendKeys('{F5}')  # Send F5 (Refresh)
#    } else { break; } # Chrome not open, exit the loop
#}

