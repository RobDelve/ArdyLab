#requires -Version 4.0
<#
    .Synopsis
    ArdyLab DSC Resource to Build FileServer on a node.

    .Description
    blah, blah
    
    .TODO
    Add Error Checking and Verbose/Debug output
#>
Configuration LabDeployFileServer
{
  param             
  ( 
    [Parameter(Mandatory)]             
    [psobject]
    $MountVHD       
  )

  Import-DscResource -ModuleName xSmbShare
  Import-DscResource -ModuleName StorageDSC 
  Import-DscResource -ModuleName PSDesiredStateConfiguration
        
  foreach ($VHD in $MountVHD)
  {   
    
    if(!$vhd.Path)
    {
      # Mounting a newly created Data Disk, so will need to Initialise & Format            
      disk $vhd.Name
      {
        DiskID      = $vhd.DiskNumber
        DriveLetter = $vhd.DriveLetter             
        FSLabel     = $vhd.Name              
      }
    }
    else
    {
      # Mounting an existing Data Disk, so just bring it online                              
      disk $vhd.Name
      {
        DiskId      = $vhd.DiskNumber
        DriveLetter = $vhd.DriveLetter              
      }
    }
    
        
    # Create a share for the mounted disk
    xSmbShare $VHD.Name
    {
      Name      = $VHD.Name
      Path      = "$($VHD.DriveLetter):\"
      Ensure    = 'Present'

      DependsOn = "[Disk]$($VHD.Name)"
    }
  }
}