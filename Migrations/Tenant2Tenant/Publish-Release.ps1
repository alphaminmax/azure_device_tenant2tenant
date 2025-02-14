#Package Release 
#Uses Dependency "Install-Module -Name "IntuneWin32App" -AcceptLicense"
#Source https://github.com/MSEndpointMgr/IntuneWin32App

#First we will move the old release to the release folder
$sourcePath = "C:\Users\%userprofile%\Downloads\IntuneMigration-main\Output\StartMigrate-v*.intunewin"
$destinationPath = "C:\Users\%userprofile\Downloads\IntuneMigration-main\Output\Releases"

# Get the latest version of the file based on the pattern
$latestFile = Get-ChildItem -Path $sourcePath | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Check if a file was found
if ($latestFile -ne $null) {
    # Copy the latest version of the file to the destination
    Move-Item -Path $latestFile.FullName -Destination $destinationPath
    Write-Host "File moved successfully: $($latestFile.Name)"
} else {
    Write-Host "No file found matching the pattern."
}

# Package MSI as .intunewin file
$SourceFolder = "C:\Users\%userprofile%\Downloads\IntuneMigration-main\IntuneMigration-main"
$SetupFile = "StartMigrate.ps1"
$OutputFolder = "C:\Users\%userprofile%\Downloads\IntuneMigration-main\Output"
New-IntuneWin32AppPackage -SourceFolder $SourceFolder -SetupFile $SetupFile -OutputFolder $OutputFolder -Verbose

#Rename the new build file with version number
# Define the directory containing previous releases
$releasesDir = "C:\Users\%userprofile%\Downloads\IntuneMigration-main\Output\Releases"

# Define the path to the new package (before renaming)
$newPackagePath = "C:\Users\%userprofile%\Downloads\IntuneMigration-main\Output\StartMigrate.intunewin"

# Find the highest version number in existing files
$latestVersion = Get-ChildItem -Path "$releasesDir\StartMigrate-v*.intunewin" | 
    ForEach-Object {
        if ($_.Name -match 'StartMigrate-v(\d+\.\d+\.\d+)\.intunewin') {
            [version]$matches[1]
        }
    } | Sort-Object -Descending | Select-Object -First 1

# If a previous version exists, increment the version number
if ($latestVersion -ne $null) {
    $newVersion = [version]::new($latestVersion.Major, $latestVersion.Minor, $latestVersion.Build + 1)
} else {
    # If no previous versions are found, start with version 0.0.1
    $newVersion = [version]::new(0, 0, 1)
}

# Construct the new file name with the incremented version number
$newFileName = "StartMigrate-v$newVersion.intunewin"
$newFilePath = Join-Path -Path (Split-Path -Path $newPackagePath) -ChildPath $newFileName

# Rename the new package with the new version number
Rename-Item -Path $newPackagePath -NewName $newFileName

Write-Host "New package renamed to: $newFileName and kept in the Output folder."
