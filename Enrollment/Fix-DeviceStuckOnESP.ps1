#source https://call4cloud.nl/2021/06/autopilot-account-setup-identifying-security-policies/ Step 6

$Name = get-childitem -path HKLM:\software\microsoft\enrollments\ -Recurse | where { $_.Property -match 'SkipUserStatusPage' }
if ($Name)
{
$Converted = Convert-Path $Name.PSPath
New-ItemProperty -Path Registry::$Converted -Name SkipUserStatusPage  -Value 4294967295 -PropertyType DWORD -Force | Out-Null
}
