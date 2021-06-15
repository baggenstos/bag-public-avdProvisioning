param(
     [string]$languageDownloadUrl
)

<#
.SYNOPSIS
  <Script for provisioning AVD session hosts>
.DESCRIPTION
  <Automation script for installing apps, language packs and removing Windows bloatware.>
.INPUTS
  <None>
.OUTPUTS
  <None>
.NOTES
  Version:        <1.0>
  Author:         <Lukas rottach>
  Creation Date:  <10.06.2021>
  Purpose/Change: Initial script development
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>
#---------------------------------------------------------[Initialisations]--------------------------------------------------------

# Create local working directory
Start-Transcript -Path C:\Windows\Temp\SessionHost-Provisioning.log

#----------------------------------------------------------[Declarations]----------------------------------------------------------

# Example
# Declare Variables in this area

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Remove-BuiltInApps {
    # Get a list of all apps
    $AppArrayList = Get-AppxPackage | Select-Object -Property Name, PackageFullName | Sort-Object -Property Name
 
    # Loop through the list of apps
    foreach ($App in $AppArrayList) {
        # Exclude apps
        if (($App.Name -in "Microsoft.WindowsCalculator", "Microsoft.WindowsAlarms", "Microsoft.Windows.Photos", "Microsoft.WindowsStore", "Microsoft.Office.OneNote", "Microsoft.ScreenSketch")) {
            Write-Output -InputObject "Skipping essential Windows app: $($App.Name)"
        }
    
        # Remove AppxPackage and AppxProvisioningPackage
        else {
            
            try {
                # Gather package names
                $AppPackageFullName = Get-AppxPackage -Name $App.Name -ErrorAction Stop | Select-Object -ExpandProperty PackageFullName
                $AppProvisioningPackageName = Get-AppxProvisionedPackage -Online -ErrorAction Stop | Where-Object { $_.DisplayName -like $App.Name } | Select-Object -ExpandProperty PackageName
            }
            catch {
                Write-Output -InputObject "Failed to gather package names for: $($App.Name)"
            }

            # Attempt to remove AppxPackage
            try {
                Write-Output -InputObject "Removing AppxPackage: $($AppPackageFullName)"
                Remove-AppxPackage -Package $AppPackageFullName -ErrorAction SilentlyContinue
            }
            catch {
                Write-Host "Failed remove AppxPackage: $($AppPackageFullName)" -ForegroundColor Yellow
            }

            # Attempt to remove AppxProvisioningPackage
            try {
                Write-Output -InputObject "Removing AppxProvisioningPackage: $($AppProvisioningPackageName)"
                Remove-AppxProvisionedPackage -PackageName $AppProvisioningPackageName -Online -ErrorAction SilentlyContinue
            }
            catch {
                Write-Host "Failed to remove AppxProvisioningPackage: $($AppProvisioningPackageName)" -ForegroundColor Yellow
            } 
        }
    }    
}

function Install-LanguageFeatures {
	param (
		$downloadUrl
	)

	Write-Output "Downloading language specific files using the URL: $($downloadUrl)"

	# Split URL to get file name
	$fileName = $downloadUrl.Split('/')[4]
	Write-Output "Got .zip archive $($fileName) from archive"
	$filePath = ".\" + $fileName
	Write-Output "Build full file path $($filePath)"

	# Extract .zip archive
	Write-Output "Extracting .zip file"
	Expand-Archive -Path $filePath

	Write-Output "Searching for cabinet files under the following path $($filePath.Split('.z')[1])"
	$languageCabinetFiles = Get-ChildItem -Path $filePath.Split('.z')[1] | Where-Object Name -Like "*.cab"
  	$languageAppFile = (Get-ChildItem -Path $filePath.Split('.z')[1] | Where-Object Name -Like "*.appx")[0]
  	$languageAppLicenseFile = (Get-ChildItem -Path $filePath.Split('.z')[1] | Where-Object Name -Like "*.xml")[0]

  # Importing cabinet files .cab
	foreach ($languageFile in $languageCabinetFiles) {
	  	Write-Output "Processing file: $($languageFile.Name)"
    		Add-WindowsPackage -Online -PackagePath $languageFile.FullName
	}

  # Importing language experience pack
  Add-AppProvisionedPackage -Online -PackagePath $languageAppFile.FullName -LicensePath $languageAppLicenseFile.FullName

}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

# Call function for installing language features
Install-LanguageFeatures -downloadUrl $languageDownloadUrl

# Manipulate the Windows language list
$languageList = Get-WinUserLanguageList
$languageList.Clear()
$languageList.Add("de-CH")
Set-WinUserLanguageList $languageList -Force

# Execute Appcleanup
Remove-BuiltInApps

# Stop logging
Stop-Transcript
exit 0
