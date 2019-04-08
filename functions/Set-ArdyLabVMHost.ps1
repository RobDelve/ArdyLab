<#
.Synopsis
    Set-ArdyLabVMHost
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
function Set-ArdyLabVMHost
{
  [CmdletBinding()]
  Param
  (
    [parameter()]
    [switch]
    $RunNow
  )

  DynamicParam
  {
    Invoke-Command -ScriptBlock $__DynParamConfigFile
  }

  Begin
  {
    Import-Module 'ArdyLab\internal\LabSetVMHost.ps1' -Force -Scope Local
  }

  Process
  {
    $ConfigFile = Join-Path -Path $LabManifestPath -ChildPath $($PSBoundParameters.ConfigFile)

    $ConfigData = Get-Content $ConfigFile -Raw | ConvertFrom-Json | ConvertPSObjectToHashtable

    Write-Verbose -Message 'Generating the required MOF.'
    $mofFile = LabSetVMHost -ConfigurationData $ConfigData -OutputPath $mofPath

    Write-Verbose -Message "Created file '$mofFile'."

    # Run the DSC configuration now?
    if ($RunNow)
    {
      Write-Verbose -Message 'Executing the generated MOF.'
      Start-DscConfiguration -Path $mofPath -Wait
    }
  }

  End
  {
    Remove-DscConfigurationDocument -Stage Current, Pending -Verbose
  }
}
