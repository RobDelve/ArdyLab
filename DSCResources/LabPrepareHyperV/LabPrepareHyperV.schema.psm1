#requires -Version 4.0
#requires -modules xDismFeature,xHyper-V,xNetworking

<#
    .Synopsis
    DSC Resource to Install the Hyper-V Windows Feature, then create & configure a Hyper-V Virtual Switch.

    .Description
    Uses the DSC Module 'xHyper-v' to create a Virtual Switch.
    Uses the DSC Module 'xNetworking' to configure the Virtual Switch
#>
Configuration LabPrepareHyperV
{
    param             
    (  
        [Parameter(Mandatory)]
        [string]
        $VSwitchName,

        [Parameter(Mandatory)]
        [string]
        $VSwitchType,    
    
        [Parameter(Mandatory)]
        [string]
        $VSwitchIP4Address
    )

    Import-DscResource -ModuleName xDismFeature 
    Import-DscResource -ModuleName xHyper-V
    Import-DscResource -ModuleName xNetworking
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    # Ensure the Hyper-V Windows Feature is Enabled
    xDismFeature InstallHyperV-All {
        Name   = 'Microsoft-Hyper-V-All'
        Ensure = 'Present'
    }
  
    # Create a Hyper-V Virtual Switch
    xVMSwitch $VSwitchName {
        Name   = $VSwitchName
        Ensure = 'Present'
        Type   = $VSwitchType
    }

    # Configure the new Ethernet Adapter created by the Virtual Switch.
    xNetConnectionProfile $VSwitchName {
        InterfaceAlias  = "vEthernet ($VSwitchName)"
        NetworkCategory = 'Private'		
        DependsOn       = "[xVMSwitch]$VSwitchName"
    }

    xIPAddress $VSwitchName {
        IPAddress      = $VSwitchIP4Address
        InterfaceAlias = "vEthernet ($VSwitchName)"		
        AddressFamily  = 'IPV4'
        DependsOn      = "[xVMSwitch]$VSwitchName"
    }

    xDhcpClient $VSwitchName {
        State          = 'Disabled'
        InterfaceAlias = "vEthernet ($VSwitchName)"
        AddressFamily  = 'IPV4'
        DependsOn      = "[xVMSwitch]$VSwitchName"
    }
}
