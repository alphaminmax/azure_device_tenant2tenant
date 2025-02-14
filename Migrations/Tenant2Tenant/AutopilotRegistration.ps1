# Start and append post-migration log file
Start-Transcript -Append "C:\ProgramData\IntuneMigration\post-migration.log" -Verbose
Write-Host "BEGIN LOGGING FOR AUTOPILOTREGISTRATION..."
# Install for NUGET
Install-PackageProvider -Name NuGet -Confirm:$false -Force

# Install and import required modules
$requiredModules = @(
    'Microsoft.Graph.Intune'
    'WindowsAutopilotIntune'
)

foreach($module in $requiredModules)
{
    Install-Module -Name $module -AllowClobber -Force
}

foreach($module in $requiredModules)
{
    Import-Module $module
}

# Construct path to .env file
$envFile = "C:\ProgramData\IntuneMigration\.env"

if (Test-Path $envFile) {
    Write-Host "Loading environment variables from $envFile..."
    $envContent = Get-Content $envFile
    foreach ($line in $envContent) {
        # Skip comments and empty lines
        if (-not ($line -match '^\s*#') -and $line -match '\S') {
            $key, $value = $line -split '=', 2
            $key = $key.Trim()  # Trim whitespace from the key
            $value = $value.Trim()  # Trim whitespace from the value
            New-Variable -Name $key -Value $value -Scope Script  # Create variable in script's scope
            Write-Host "Variable '$key' loaded."
        }
    }
} else {
    Write-Host "Warning: .env file not found."
}

# Tenant B App reg

<#PERMISSIONS NEEDED:
Device.ReadWrite.All
DeviceManagementApps.ReadWrite.All
DeviceManagementConfiguration.ReadWrite.All
DeviceManagementManagedDevices.PrivilegedOperations.All
DeviceManagementManagedDevices.ReadWrite.All
DeviceManagementServiceConfig.ReadWrite.All
#>


$clientSecureSecret = ConvertTo-SecureString -String $targetclientSecret -AsPlainText -Force
$targetclientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $targetclientId, $clientSecureSecret

# Authenticate to graph and add Autopilot device
Connect-MgGraph -targettenantid $targettenantid -targetclientSecretCredential $targetclientSecretCredential

# Get Autopilot device info
$hwid = ((Get-WmiObject -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'").DeviceHardwareData)

$ser = (Get-WmiObject win32_bios).SerialNumber
if([string]::IsNullOrWhiteSpace($ser)) { $ser = $env:COMPUTERNAME}

# Retrieve group tag info
[xml]$memConfig = Get-Content "C:\ProgramData\IntuneMigration\MEM_Settings.xml"

$tag = $memConfig.Config.GroupTag

Add-AutopilotImportedDevice -serialNumber $ser -hardwareIdentifier $hwid -groupTag $tag
Start-Sleep -Seconds 5

#now delete scheduled task
Disable-ScheduledTask -TaskName "AutopilotRegistration"
Write-Host "Disabled AutopilotRegistration scheduled task"

Write-Host "END LOGGING FOR AUTOPILOTREGISTRATION..."
Stop-Transcript