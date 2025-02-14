# Start and append post-migration log file
$postMigrationLog = "C:\ProgramData\IntuneMigration\post-migration.log"
Start-Transcript -Append $postMigrationLog -Verbose

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

$ErrorActionPreference = 'SilentlyContinue'
# Check if migrating data
Write-Host "Checking for Data Migration Flag..."
$dataMigrationFlag = "C:\ProgramData\IntuneMigration\MIGRATE.txt"

if(Test-Path $dataMigrationFlag)
{
    Write-Host "Data Migration Flag Found"
    Write-Host "Begin data restore..."
    # Get current active user profile
    $activeUsername = (Get-WMIObject Win32_ComputerSystem | Select-Object username).username
    $currentUser = $activeUsername -replace '.*\\'

    # Get backed up locations
    [xml]$memSettings = Get-Content "C:\ProgramData\IntuneMigration\MEM_Settings.xml"
    $memConfig = $memSettings.Config
    $dataLocations = $memConfig.Locations

    $locations = $dataLocations.Location
    #$sourceOneDriveCompanyName = "Vorano"

    # Restore user data
    foreach($location in $locations)
    {
        $userPath = "C:\Users\$($currentUser)\$($location)"
        $publicPath = "C:\Users\Public\Temp\$($location)"
        Write-Host "Initiating data restore of $($location)"
        robocopy $publicPath $userPath /E /ZB /R:0 /W:0 /V /XJ /FFT
    }

    # Special handling for "Onedrive - Vorano" after it's moved to the user's profile
    $onedriveUserPath = "C:\Users\$($currentUser)\OneDrive - $sourceOneDriveCompanyName"
    if(Test-Path $onedriveUserPath)
    {
        Write-Host "OneDrive - $sourceOneDriveCompanyName directory found in user's profile. Initiating special handling for subfolders."

        # Specify subfolders to move
        $subFolders = @("Documents", "Desktop", "My Documents", "Pictures") # Add more folders as needed

        foreach($subFolder in $subFolders)
        {
            $sourcePath = Join-Path $onedriveUserPath $subFolder
            $destinationPath = "C:\Users\$($currentUser)\$subFolder"
            
            Write-Host "Moving $subFolder from Onedrive - Vorano to $destinationPath"
            robocopy $sourcePath $destinationPath /E /ZB /R:0 /W:0 /V /XJ /FFT /IS
        }
    }
}
else 
{
    Write-Host "Data Migration flag not found. Data will not be restored"
}

Start-Sleep -Seconds 3

# Renable the GPO so the user can see the last signed-in user on logon screen
try {
    Set-ItemProperty -Path "HKLM:Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name dontdisplaylastusername -Value 0 -Type DWORD
    Write-Host "$(Get-TimeStamp) - Disable Interactive Logon GPO"
} 
catch {
    Write-Host "$(Get-TimeStamp) - Failed to disable GPO"
}

# Disable RestoreProfile Task
Disable-ScheduledTask -TaskName "RestoreProfile"
Write-Host "Disabled RestoreProfile scheduled task"

Write-Host "Rebooting machine in 30 seconds"
Shutdown -r -t 30

Stop-Transcript
