#Required intune appregistration permissions are
#Name = IntuneHWIDScript
#supported account types = Single Tenant
#Permissions are Graph Application Permissions
#DeviceManagementConfiguration.ReadWrite.All
#DeviceManagementServiceConfig.ReadWrite.All
#Redirect URI is web -  "https://localhost/"

#Define Variables
$TenantID = "YOUR_TENANT_ID"
$ApplicationID = "YOUR_APP_ID"
$ApplicationSecret = "YOUR_APP_SECRET"

#Install Nuget
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
# Install Get-WindowsAutoPilotInfo module
Install-Script -Name Get-WindowsAutopilotInfo -Force

# Set execution policy to unrestricted
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force

#Wait 20 Seconds 
Start-Sleep -Seconds 20

# Execute Get-WindowsAutoPilotInfo command
Get-WindowsAutoPilotInfo.ps1 -Online -TenantId $TenantID -AppId $ApplicationID -AppSecret $ApplicationSecret #-GroupTag "HWIDScript" 
