#requires -Version 4.0
<#
    .Synopsis
    blah

    .Description
    blah, blah
#>
configuration LabAddVHD {
  Param 
  (
    [Parameter(Mandatory)]
    [string]
    $NodeName,

    [Parameter(Mandatory)]
    [string]
    $Path,
         
    [Parameter(Mandatory)]
    [string]
    $ControllerType,

    [Parameter(Mandatory)]
    [string]
    $ControllerLocation,

    [Parameter(Mandatory)]
    [string]
    $ControllerNumber
  )

  Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
   
  Script AddVHD
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
      Write-Verbose -Message "Adding VHD to  '$using:NodeName'."
      Add-VMHardDiskDrive -VMName $using:NodeName -ControllerType $using:ControllerType -ControllerNumber $using:ControllerNumber -ControllerLocation $using:ControllerLocation -Path $using:Path
    } 
  }
}