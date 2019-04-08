#requires -Version 5.0
#requires -modules SqlServerDSC

<#
    .Synopsis
    ArdyLab DSC Resource to install & Configure Microsoft SQL Server and .Net 3.5 & .Net 4.5

    .Description
    blah, blah
    
    .TODO
    Add Error Checking and Verbose/Debug output
#>
Configuration LabDeploySQL
{
    param             
    ( 
        [Parameter(Mandatory)]
        [string]
        $SqlServer,
      
        [Parameter(Mandatory)]
        [string]
        $SxsPath,

        [Parameter(Mandatory)]
        [string]
        $SourcePath,

        [Parameter()]
        [pscredential]
        $SetupCredential,

        [Parameter()]
        [pscredential]
        $SqlServiceCredential,

        [Parameter()]
        [string]
        $Instance = 'MSSQLSERVER',

        [Parameter()]
        [string]
        $Features = 'SQLENGINE, SSMS, ADV_SSMS',

        [Parameter()]
        [string]
        $SecurityMode = 'SQL',

        [Parameter()]
        [string]
        $Collation = 'Latin1_General_CI_AS',

        [Parameter()]
        [pscredential]
        $SAPassword,

        [Parameter()]
        [pscredential[]]
        $SQLUsers,

        [Parameter()]
        [hashtable[]]
        $SQLDatabases,

        [Parameter()]
        [hashtable[]]
        $InstallPath
    )

    Import-DscResource -ModuleName SqlServerDSC
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    WindowsFeature InstallNET35 {
        Name   = 'NET-Framework-Core'
        Ensure = 'Present'
        Source = $SxsPath
    }
     
    WindowsFeature InstallNET45 {
        Name   = 'NET-Framework-45-Core'
        Ensure = 'Present'
    }
  

    SqlSetup InstallSqlServer {
        SQLSvcAccount        = $SqlServiceCredential
        InstanceName         = $Instance
        Action               = 'Install'
        ForceReboot          = $true
        SourcePath           = $SourcePath
        Features             = $Features
        SQLSysAdminAccounts  = $SetupCredential.UserName
        SecurityMode         = $SecurityMode
        SAPwd                = $SAPassword
        SQLCollation         = $Collation
        InstallSharedDir     = $InstallPath.InstallSharedDir
        InstallSharedWOWDir  = $InstallPath.InstallSharedWOWDir
        InstanceDir          = $InstallPath.InstanceDir
        InstallSQLDataDir    = $InstallPath.InstallSQLDataDir
        SQLUserDBDir         = $InstallPath.SQLUserDBDir
        SQLUserDBLogDir      = $InstallPath.SQLUserDBLogDir
        SQLTempDBDir         = $InstallPath.SQLTempDBDir
        SQLTempDBLogDir      = $InstallPath.SQLTempDBLogDir
        SQLBackupDir         = $InstallPath.SQLBackupDir

        PsDscRunAsCredential = $SetupCredential

        DependsOn            = '[WindowsFeature]InstallNET35', '[WindowsFeature]InstallNET45' 
    }

  
    SqlWindowsFirewall SqlFirewall {
        Ensure       = 'Present'
        SourcePath   = $SourcePath
        InstanceName = $Instance
        Features     = $Features

        DependsOn    = '[SqlSetup]InstallSqlServer'
    }

 
    foreach ($user in $SQLUsers) { 
        SqlServerLogin "AddSQLUser_$($user.username)" {
            Ensure                         = 'Present'
            Name                           = $user.username
            LoginType                      = 'SqlLogin'
            LoginCredential                = $user
            ServerName                     = $SqlServer
            InstanceName                   = $Instance
            LoginMustChangePassword        = $false
            LoginPasswordExpirationEnabled = $false
            LoginPasswordPolicyEnforced    = $false

            DependsOn                      = '[SqlSetup]InstallSqlServer'
        }
    }

    foreach ($db in $SqlDatabases) {
    
        SqlDatabase "AddSqlDatabase_$($db.name)" {
            Name         = $db.Name
            Ensure       = 'present'
            ServerName   = $SqlServer
            InstanceName = $Instance

            DependsOn    = '[SqlSetup]InstallSqlServer'
        }

        SqlDatabaseRecoveryModel "SetSqlDatabaseRecoveryModel_$($db.name)" {
            Name          = $db.Name
            RecoveryModel = $db.RecoveryModel
            ServerName    = $SqlServer
            InstanceName  = $Instance

            DependsOn     = "[SqlDatabase]AddSqlDatabase_$($db.name)"
        }
  
        SqlDatabaseOwner "SetDbOwner_$($db.name)" {
            Name         = $db.Owner
            Database     = $db.name
            ServerName   = $SqlServer
            InstanceName = $Instance

            DependsOn    = "[SqlDatabase]AddSqlDatabase_$($db.name)", "[SqlServerLogin]AddSqlUser_$($db.Owner)"
        }
    }
}