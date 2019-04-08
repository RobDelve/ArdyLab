# Private Helper functions for handling File operations

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
function ardyNewFolder {
    param (
        [parameter(mandatory)]
        [string] $Path,
      
        [parameter(mandatory)]
        [string] $Name
    )
    
    try {
        $null = New-Item -Path $Path -Name $Name -ItemType Directory -ErrorAction Stop
        Write-Verbose -Message "Created folder '$Path\$Name'"
    } catch {
        Write-Warning -Message "Folder '$Path\$Name' already exists"
    }
}

# Private Helper function
function ardyCopyFolder {
    param (
        [parameter(mandatory)]
        [string] $Path,
      
        [parameter(mandatory)]
        [string] $Destination
    )
    
    try {
        $null = Copy-Item -Path $Path -Destination $Destination -Recurse -ErrorAction Stop
        Write-Verbose -Message "Copied folder contents '$Path' to '$Destination'"
    } catch {
        Write-Warning -Message "File '$(($Path -split '\\')[-1])' already exists in '$Destination'"
    }
}
