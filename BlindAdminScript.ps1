
    #$objRand = New-Object random
    #$num = $objRand.Next(10000,99999)
    #$Password = ([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..9 | sort {Get-Random})[0..8] -join ''
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web
    #$pass = "KraP" + [system.web.security.membership]::GeneratePassword(4,1)
    #Set-ADAccountPassword blindadmin -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $pass -Force -Verbose) -PassThru
    #Write-Output "blindadmin new password:" "$pass"
    #regen-pass

function regen-pass
{
 $z = "KraP" + [system.web.security.membership]::GeneratePassword(4,1)
 #Write-Output "blindadmin new password:" "$z"
 $textBox.Text = $z
 #return $z
}

function set-pass {
#Param ([string]$p)
$p = $textBox.Text
Set-ADAccountPassword blindadmin -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $p -Force) -PassThru
$label2.Text = "blindadmin set to:" + "$p"
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Blind Admin PassGen'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'Fixed3D'
$form.MaximizeBox = $false

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(75,120)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = 'regen!'
#$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
#$form.AcceptButton = $OKButton
$OKButton.Add_Click({regen-pass})
$form.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(150,120)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = 'set!'
$CancelButton.Add_Click({set-pass})
#$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
#$form.CancelButton = $CancelButton
$form.Controls.Add($CancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'blindadmin new pass:'
$form.Controls.Add($label)

$label2 = New-Object System.Windows.Forms.Label
$label2.Location = New-Object System.Drawing.Point(50,70)
$label2.Size = New-Object System.Drawing.Size(280,20)
$form.Controls.Add($label2)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10,40)
$textBox.Size = New-Object System.Drawing.Size(260,20)
$textBox.Text = $z
#$textBox.Enabled = $false
$form.Controls.Add($textBox)

$randCheckbox = New-Object System.Windows.Forms.Checkbox
$randCheckbox.Location = New-Object System.Drawing.Size(70,90)
$randCheckbox.Size = New-Object System.Drawing.Size(500,20)
$randCheckbox.Text = "autorandom!"
#$form.Controls.Add($randCheckbox)

$form.Topmost = $true

$y

#$form.Add_Shown({$textBox.Select()})
$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    #$x = $textBox.Text
    #$x
    $y = regen-pass
    set-pass -p $y
    $textBox.Text = $y

}

if ($result -eq [System.Windows.Forms.DialogResult]::Cancel)
{
    #$x = $textBox.Text
    #$x
    set-pass -p $y
    #$textBox.Text = $y

}
#$objChkBoxClick_OnClick = {
#if ($randCheckbox.Checked -eq $true) 
#{
#    #$z = "KraP" + [system.web.security.membership]::GeneratePassword(4,1)
#    #$textBox.Text = $z
#    $textBox.Enabled = $false
#}
#}
#$randCheckbox.Add_Click({$textBox.Enabled = $false})

