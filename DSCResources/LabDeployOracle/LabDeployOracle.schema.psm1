#requires -Version 4.0
<#
    .Synopsis
    ArdyLab DSC Resource to install & Configure Oracle Database server

    .Description
    blah, blah
    
    .TODO
    Add Error Checking and Verbose/Debug output
#>
Configuration LabDeployOracle
{
  param             
  ( 
    [Parameter(Mandatory)]             
    [string]
    $SourcePath,

    [Parameter(Mandatory)]             
    [pscredential]
    $SetupCredential,

    [Parameter()]             
    [string]
    $ResponseFile
  )

  Import-DscResource -ModuleName PSDesiredStateConfiguration
     
  Script DeployOracle
  {
    GetScript = {
      # do nothing for now
    }
    TestScript = {
      # just return $false for now - forces 'SetScript' to run everytime
      $false
    }
    SetScript = 
    {
      Write-Verbose -Message "Starting Oracle setup.exe with Response File '$using:ResponseFile'."
     # Start-Process -FilePath "$($)"
    } 
  }
}