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

#-----------------------------------------------------------[Execution]------------------------------------------------------------

# Execute Appcleanup
Remove-BuiltInApps
