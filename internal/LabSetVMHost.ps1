#requires -Version 4.0

<#
    .Synopsis
    ArdyLab DSC Resource to build a custom MOF for the computer 'locaclhost' to configure Hyper-V
    VMware & VirtualBox to be added later

    .Description
    Run this to create a MOF to ....
    .TODO
    Add Error Checking and Verbose/Debug output

#>
Configuration LabSetVMHost
{
  Import-DscResource -ModuleName ArdyLab

  Write-Verbose -Message 'Creating a MOF to configure a Hyper-V host.' 
        
  node localhost
  {
    # ArdyLab Resource that Installs Hyper-V Features on the LocalHost and Configure an 'Internal' vSwitch
    LabPrepareHyperV VmHost 
    {
      VSwitchName = $ConfigurationData.LabConfig.VSwitch.Name
      VSwitchType = $ConfigurationData.LabConfig.VSwitch.Type
      VSwitchIP4Address = $ConfigurationData.LabConfig.VSwitch.IP4Addr
      #VSwitchIP4PrefixLength = ($ConfigurationData.LabConfig.VSwitch.IP4Addr -split '/')[1]
    }
  }
}
