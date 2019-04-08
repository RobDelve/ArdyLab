#requires -Version 4.0

<#
    .Description
     DSC Resource to Configure common PreReqs for an EPM Server  
#>
Configuration LabPreReqEPM
{
    param             
    (  
        [Parameter()]
        [string]
        $UacSetting = $null,

        [Parameter()]
        [string]
        $PowerPlan,

        [Parameter()]
        [string]
        $EpmSvcIdentity,
    
        [Parameter()]             
        [psobject]
        $PageFile = $null        
    )

    Import-DscResource -ModuleName xSystemSecurity
    Import-DscResource -ModuleName ComputerManagementDSC
    Import-DscResource -ModuleName SecurityPolicyDsc
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    if ($UacSetting) {
        xUac 'ConfigureUAC' {
            Setting = $UacSetting    # AlwaysNotify | NotifyChanges | NotifyChangesWithoutDimming | NeverNotify | NeverNotifyAndDisableAll
        }
    }

    if ($PageFile) {
        VirtualMemory 'ConfigurePageFile' {
            Drive       = $PageFile.Drive
            Type        = $PageFile.Type    # SystemManagedSize | NoPagingFile | CustomSize | AutoManagePagingFile
            InitialSize = $PageFile.InitialSize
            MaximumSize = $PageFile.MaxSize
        }
    }

    if ($PowerPlan) {
        PowerPlan 'ConfigurePowerPlan' {
            Name             = $PowerPlan
            IsSingleInstance = 'Yes'
        }
    }

    xIEEsc 'DisableAdminUsers' {
        UserRole  = 'Administrators'
        IsEnabled = $false
    }

    UserRightsAssignment  'LogonAsService' {
        Policy   = 'Log_on_as_a_service'
        Identity = $EpmSvcIdentity
    }

}