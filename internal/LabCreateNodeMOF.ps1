#requires -Version 4.0
#requires -Modules StorageDSC
<#
    .Synopsis
    ArdyLab DSC Resource to build a custom MOF for each Node specified in the ConfigurationData.

    .Description
    Run this to create the MOFs BEFORE building the VM's with 'LabBuildVM'
    .TODO
    Add logic + configuration for all Role types
    Add Error Checking and Verbose/Debug output
#>
Configuration LabCreateNodeMOF
{
    Import-DscResource -ModuleName ArdyLab
    Import-DscResource -ModuleName StorageDSC

    $script:DomainOUs = $ConfigurationData.Roles.PrimaryDC.DomainConfig.AdOUs
    $script:DomainUsers = $ConfigurationData.Roles.PrimaryDC.DomainConfig.AdUsers
    $script:DomainGroups = $ConfigurationData.Roles.PrimaryDC.DomainConfig.AdGroups

    $script:DnsIpAddress = $((($ConfigurationData.AllNodes.Where{$_.role -contains 'PrimaryDC'}).IP4Addr -split '/')[0])

    $script:MountVHD = $ConfigurationData.Roles.FileServer.MountVHD

    $script:Net35Source = $ConfigurationData.Roles.SQLServer.Net35Source
    $script:SQLSetup = $ConfigurationData.Roles.SQLServer.Setup
    $script:SQLDatabase = $ConfigurationData.Roles.SQLServer.Databases
    $script:SQLUser = $ConfigurationData.Roles.SQLServer.SQLUsers

    $script:EpmServer = $ConfigurationData.Roles.EpmServer


    node $AllNodes.NodeName
    {
        # Create credential object for DomainAdmin
        $domainAdminName = "$(($node.DomainName -split '\.')[0])\$($ConfigurationData.Roles.PrimaryDC.DomainConfig.Credentials.DomainAdminName)"
        $domainAdminPassword = ConvertTo-SecureString -String $ConfigurationData.Roles.PrimaryDC.DomainConfig.Credentials.DomainAdminPassword -AsPlainText -Force
        $domainAdminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $domainAdminName, $domainAdminPassword

        # Are we joining a Domain OU??
        if (-not [string]::IsNullOrWhiteSpace($node.DomainOU)) {
            # Populate $DomainOU
            $DomainOU = "OU=$($node.DomainOU),DC=$(($node.DomainName -split '\.')[0]),DC=$(($node.DomainName -split '\.')[1])"
        }
        else {
            $DomainOU = $null
        }

        # Any additonal 'local' Disks to add??
        if ($node.Datadisk) {
            foreach ($vhd in $node.DataDisk) {
                if ([string]::IsNullOrWhiteSpace($vhd.Path)) {
                    # Mounting a newly created Data Disk, so will need to Initialise & Format

                    disk $vhd.Name {
                        DiskID      = $vhd.DiskNumber
                        DriveLetter = $vhd.DriveLetter
                        FSLabel     = $vhd.Name
                    }
                }
                else {
                    # Mounting an existing Data Disk, so just bring it online

                    ## !!! Curently xStorage/xDisk is failing to bring an exiting disk online and set drive letter correctly.
                    ## !!! Will bring disk online, then check existing volumes for matching drive letter & size (will fail)
                    ## !!! So tries to crate a new volume on that disk with drive letter and all available space (as no size set below)
                    ## !!! Removing functionality for now, as can be added via the 'File Server' role

                    disk $vhd.Name {
                        DiskId      = $vhd.DiskNumber
                        DriveLetter = $vhd.DriveLetter
                    }
                }
            }
        }


        # Process the specificed Role(s) of this node in turn
        foreach ($role in $node.Role) {
            switch ($role) {
                'PrimaryDC' {
                    # Custom Composite Resources to Install & Configure ADDS
                    LabDeployADDS $node.NodeName {
                        DomainName    = $node.DomainName
                        DomainAdmin   = $domainAdminCredential
                        SafeModeAdmin = $domainAdminCredential
                        DomainOUs     = @($DomainOUs)
                        DomainUsers   = @($DomainUsers)
                        DomainGroups  = @($DomainGroups)
                    }

                    # TBI
                    #LabConfigureDNS $node.NodeName
                    #{
                    #
                    #}
                }

                'DomainMember' {
                    # Join a Domain
                    LabJoinDomain $node.NodeName {
                        NodeName             = $node.NodeName
                        DomainName           = $node.DomainName
                        JoinOU               = $DomainOU # Fix This!!! - suspect fault in format
                        DomainJoinCredential = $domainAdminCredential
                        DnsIPAddress         = $DnsIpAddress
                    }
                }

                'FileServer' {
                    LabDeployFileServer $node.NodeName {
                        MountVHD = $MountVHD
                    }
                }

                'SQLServer' {
                    $SqlServer = "$($node.NodeName).$($node.DomainName)"

                    # Create credential object for SQLInstall
                    if ($SQLSetup.Credential.username) {
                        $sqlInstallUserName = "$(($node.DomainName -split '\.')[0])\$($SQLSetup.Credential.UserName)"

                        $sqlInstallPassword = ConvertTo-SecureString -String $SQLSetup.Credential.Password -AsPlainText -Force
                    }
                    else {
                        $InstallUserName = $(($DomainUsers.Where{$_.Tag -contains 'sql-install'}).UserName)
                        $sqlInstallUserName = "$(($node.DomainName -split '\.')[0])\$($InstallUserName)"

                        $sqlInstallPassword = ConvertTo-SecureString -String $(($DomainUsers.where{$_.UserName -eq $InstallUserName}).Password) -AsPlainText -Force
                    }
                    $sqlInstallCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $sqlInstallUserName, $sqlInstallPassword

                    # Create credential object for SQLService
                    $SvcUserName = $(($DomainUsers.Where{$_.Tag -contains 'sql-service'}).UserName)
                    $sqlServiceUserName = "$(($node.DomainName -split '\.')[0])\$($SvcUserName)"
                    $sqlServicePassword = ConvertTo-SecureString -String $(($DomainUsers.where{$_.UserName -eq $SvcUsername}).Password) -AsPlainText -Force
                    $sqlServiceCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $sqlServiceUserName, $sqlServicePassword

                    # Create a credential object for each SQL User to add
                    $SQLUserCredentials = @()
                    foreach ($user in $SQLUser) {
                        $credpwd = ConvertTo-SecureString -String $user.Password -AsPlainText -Force
                        $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user.name, $credpwd

                        $SQLUserCredentials += $cred
                    }

                    # Create our SQL SA user credential
                    $SACredPassword = ConvertTo-SecureString -String $SQLSetup.SaPassword -AsPlainText -Force
                    $SACred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'sa', $SACredPassword

                    LabDeploySQL $node.NodeName {
                        SqlServer            = $SqlServer
                        SxsPath              = $Net35Source.Path
                        SourcePath           = $SQLSetup.SourcePath
                        SetupCredential      = $sqlInstallCredential
                        SqlServiceCredential = $sqlServiceCredential
                        Instance             = $SQLSetup.Instance
                        Features             = $SQLSetup.Features
                        SecurityMode         = $SQLSetup.SecurityMode
                        SAPassword           = $SACred
                        SQLUsers             = $SQLUserCredentials
                        SQLDatabases         = $SQLDatabase
                        InstallPath          = $SQLSetup.InstallPath
                    }
                }

                'OracleServer' {
                    # Install Oracle Database

                    LabDeployOracle $node.NodeName {
                        # Temp removed code to update
                    }

                }

                'EPMServer' {
                    $_name = $(($DomainUsers.Where{$_.Tag -contains 'epm-service'}).UserName)
                    $SvcIdentity = "$(($node.DomainName -split '\.')[0])\$($_name)"

                    LabPreReqEPM $node.NodeName {
                        UacSetting     = $EpmServer.UacSetting
                        PageFile       = @($EpmServer.PageFile)
                        EpmSvcIdentity = $SvcIdentity
                    }
                }
            }
        } #END Foreach $role


        # Add any entries in the $node.AddtoAdminGroup to the Local 'Administrators' group of this node
        # Running this after the (foreach) above does mean that domain users not added to a local group until all other process have been completed
        # i.e. have to wait for SQL server to be installed before logging in via RDP as a domain user.
        if ($node.AddToAdminGroup) {
            LabConfigureLocalGroup $node.NodeName {
                GroupName        = 'Administrators'
                DomainName       = $node.DomainName
                MembersToInclude = $node.AddToAdminGroup
                Credential       = $domainAdminCredential
            }
        }
    }
}