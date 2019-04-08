<#
.Synopsis
    Builds Virtual Machines using details from the selected Configuration Data file.
.DESCRIPTION
    Currently only builds the VM and VHD files for Hyper-V platform.
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
function Start-ArdyLabBuildVM
{
  [CmdletBinding()]
  Param
  (
    [parameter(Position = 2)]
    [switch]
    $RunNow
  )

  DynamicParam
  {
    $attributes =
    New-Object -TypeName System.Management.Automation.ParameterAttribute
    $attributes.ParameterSetName = '__AllParameterSets'
    $attributes.Mandatory = $true
    $attributeCollection =
    New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
    $attributeCollection.Add($attributes)
    $_Values =
    (Get-ChildItem -Path $LabManifestPath).name
    $ValidateSet =
    New-Object -TypeName System.Management.Automation.ValidateSetAttribute -ArgumentList ($_Values)
    $attributeCollection.Add($ValidateSet)
    $dynParam1 =
    New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList (
    'ConfigFile', [string], $attributeCollection)
    $paramDictionary =
    New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
    $paramDictionary.Add('ConfigFile', $dynParam1)

    return $paramDictionary
  }

  Begin
  {
    #Import-Module 'ArdyLab\Private\LabBuildVM.ps1' -Force -Scope Local
  }

  Process
  {
    $ConfigFile = Join-Path -Path $LabManifestPath -ChildPath $($PSBoundParameters.ConfigFile)

    $ConfigData = Get-Content $ConfigFile -Raw | ConvertFrom-Json | ConvertPSObjectToHashtable

    Write-Verbose -Message 'Generating a MOF that can be run on the Hyper-V host computer to create the required VMs'
    $mofFile = LabBuildVM -ConfigurationData $ConfigData -OutputPath $mofPath

    Write-Verbose -Message "Created file '$mofFile'."

    # Run the DSC configuration now?
    if ($RunNow)
    {
      Write-Verbose -Message 'Executing the generated MOF.'
      Start-DscConfiguration -Path $mofPath -Wait

      # Remove the configuration
      Remove-DscConfigurationDocument -Stage Current, Pending -Verbose
    }
  }
}
