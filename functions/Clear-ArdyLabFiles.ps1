<#
.Synopsis
    Clear up all previously generated MOF and Unattend.xml files from the local ArdyLab repository.
.DESCRIPTION
    ..
.EXAMPLE

.EXAMPLE

.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Custom PowerShell Object
.LINK
    http://www.ardy.co.uk
.NOTES
  Created by Rob Delve (rob@ardy.co.uk) 2016
#>
function Clear-ArdyLabFiles {
    [CmdletBinding()]
    Param()

    Write-Verbose -Message 'Cleaning up the ArdyLab generated files.'
    Write-Verbose -Message "Removing generated 'unattend.xml' and 'MOF' files."
    Remove-Item -Path "$unattendPath\*"
    Remove-Item -Path "$mofPath\*" -Include '*.mof'
    Remove-Item -Path "$mofPath\ToBeInjected\*"

    Write-Verbose -Message "Copying the 'localhost.meta.mof' from the Template '$templatePath'"
    Copy-Item -Path "$templatePath\LCM\localhost.meta.mof" -Destination "$mofPath\ToBeInjected\" -Force
}
