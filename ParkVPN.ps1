########Functions HERE#######
Function test-psversion {

}

Function add-parkvpn {
Start-Sleep -Milliseconds 3000
$encodedSecret = ""
$blah = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("QDBhNGs3c2E="))
Write-Host "Decrypting provided shared key..."
Start-Sleep -Milliseconds 3000
Add-VpnConnection -Name "ParkVPN" -ServerAddress "pfi-thgrnwpnqc.dynamic-m.com" -TunnelType L2tp -L2tpPsk $blah -Force -AuthenticationMethod MSChapv2 -EncryptionLevel Required
Write-Host "Complete!!"
}

Function test-FW {
$a = test-netconnection  pfi-thgrnwpnqc.dynamic-m.com  -CommonTCPPort HTTP -InformationLevel Quiet
return $a
}

#####END FUNCTIONS#############

#################################################Everything else############################################################################
Write-Host "Copyright (C) 2018-2019 Corey Edwards. All Rights Reserved."
Write-Host "ParkVPN v0.1.7 ALPHA"
Start-Sleep -Milliseconds 5000
Write-Host "-------------------------------------------------------------"
Write-Host "Checking for domain membership"
Start-Sleep -Milliseconds 5000
$domain = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
if ($domain -eq "PARK") {
    Write-Host "PARK domain memberhip verified"
    Start-Sleep -Milliseconds 5000
    Write-Host "Please wait...communicating with ParkHQ Firewall"
    $canSeeFW = test-FW
    if ($canSeeFW) {
        Write-Host "Connection with ParkHQ Firewall is good."
        Write-Host "Attempting fun!"
        add-parkvpn
    } else {
        Write-Host "Connection with ParkHQ failed, check internet connection!"
    }
        
Start-Sleep -Milliseconds 3000
} elseif ($domain -eq $false) {
Write-Host "Domain membership un-verified. Please add it to the domain"
}
