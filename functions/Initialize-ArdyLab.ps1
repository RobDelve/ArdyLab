<#
.Synopsis
    Initializes parameters required for the ArdyLab scripts.
.DESCRIPTION
    If not already available locally, Use the switch '-InstallModules' to download the required versions of MSFT DSC Resources from the PSGallery.

.EXAMPLE

.EXAMPLE

.INPUTS
    None.
.OUTPUTS
    Custom PowerShell Object
.LINK
    http://www.ardy.co.uk
.NOTES
  Created by Rob Delve (rob@ardy.co.uk) 2016
#>
function Initialize-ArdyLab {
    [CmdletBinding()]
    Param
    (
        # Will install all required Microsoft DSC resources from the PS Gallery
        [parameter()]
        [switch]
        $InstallDscModules,

        # Create ArdyLab folders structure in users 'My Documents\ArdyLab'
        [parameter()]
        [switch]
        $CreateLabFolders
    )

    if ($CreateLabFolders) {
        #Import-Module -Name (Join-Path -Path $modulePath -ChildPath (Join-Path -Path 'Private' -ChildPath 'FileHandlers.ps1'))

        $FolderPaths = @(
            'LabManifest'
            'Templates'
            'Data\GeneratedMOFs\ToBeInjected'
            'Data\windows\unattend'
        )

        Write-Verbose -Message "Creating ArdyLab Resource folders in '$($UserLabPath)'"

        # Create parent folders
        ardyNewFolder -Path $MyDocsPath -Name ($UserLabPath -split '\\')[-1]

        # Create child folders
        foreach ($path in $FolderPaths) {
            ardyNewFolder -Path $UserLabPath -Name $path
        }

        # Copy Template files to LabResources folders
        ardyCopyFolder -Path $(Join-Path -Path $LabSourcePath -ChildPath 'LCM') -Destination $(Join-Path -Path $UserLabPath -ChildPath 'Templates')
        ardyCopyFolder -Path $(Join-Path -Path $LabSourcePath -ChildPath  'windows\bootstrap') -Destination $(Join-Path -Path $UserLabPath -ChildPath 'Data\windows')
        ardyCopyFolder -Path $(Join-Path -Path $LabSourcePath -ChildPath  'windows\unattend') -Destination $(Join-Path -Path $UserLabPath -ChildPath 'Templates')
        ardyCopyFolder -Path $(Join-Path -Path $LabSourcePath -ChildPath  'LabManifest\*') -Destination $LabManifestPath
        #$(Join-Path -Path $UserLabPath -ChildPath 'LabManifest')

        Copy-Item -Path "$UserLabPath\Templates\LCM\localhost.meta.mof" -Destination "$UserLabPath\Data\GeneratedMOFs\ToBeInjected"
    }

    # Install required DSC modules from PSGallery
    if ($InstallDscModules) {
        Write-Verbose -Message "Installing required modules from the 'PSGallery'"

        Install-Module -Name 'xDismFeature' -Repository 'PSGallery' -RequiredVersion '1.2.0.0'
        Install-Module -Name 'xActiveDirectory' -Repository 'PSGallery' -RequiredVersion '2.16.0.0'
        Install-Module -Name 'xNetworking' -Repository 'PSGallery' -RequiredVersion '5.4.0.0'
        Install-Module -Name 'xComputerManagement' -Repository 'PSGallery' -RequiredVersion '2.1.0.0'
        Install-Module -Name 'xSQLServer' -Repository 'PSGallery' -RequiredVersion '7.1.0.0'
        Install-Module -Name 'xSystemSecurity' -Repository 'PSGallery' -RequiredVersion '1.3.0.0'
        Install-Module -Name 'xStorage' -Repository 'PSGallery' -RequiredVersion '2.9.0.0'
        Install-Module -Name 'xSmbShare' -Repository 'PSGallery' -RequiredVersion '2.0.0.0'
        Install-Module -Name 'xHyper-V' -Repository 'PSGallery' -RequiredVersion '3.10.0.0'
        Install-Module -Name 'SecurityPolicyDsc' -Repository 'PSGallery' -RequiredVersion '2.2.0.0'
    }
}
