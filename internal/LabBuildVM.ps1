#requires -Version 4.0
#requires -Modules xHyper-V
<#
    .Synopsis
    ArdyLab Composite DSC Resource to control the build of required Virtual Machine nodes

    .Description
    Run after you have completed 'LabBuildRoleMofs' as will inject each custom MOF to the correct VHD file during build.
    .TODO
    Add Error Checking and Verbose/Debug output
    Update to work with VmWare + accept a switch to specify which 'LabBuildVm***' to run.
#>
Configuration LabBuildVM
{
    Import-DscResource -ModuleName ArdyLab
    Import-DscResource -ModuleName xHyper-V

    node localhost
    {
        # Create a custom Unattend.xml then build a new VM and inject necessary files ready for 1st boot
        foreach ($vm in $AllNodes.where{$_.NodeName -ne '*'}) {
            # Get the global Admin Name & Password to use as default values
            $GlobaladminName = ($AllNodes.where{$_.NodeName -eq '*'}).AdminName
            $GlobaladminPassword = ($AllNodes.where{$_.NodeName -eq '*'}).AdminPassword

            # Check each node config to see if AdminName / AdminPassword has been specified.
            if ($vm.AdminName -ne $null) {$_adminName = $vm.AdminName}
            else {$_adminName = $GlobaladminName}

            if ($vm.AdminPassword -ne $null) {$_adminPassword = $vm.AdminPassword}
            else {$_adminPassword = $GlobaladminPassword}

            # Populate the collection of files to be copied to the VHD of this node
            $CopyToVHD = @(
                @{
                    Label       = 'Unattend'
                    Source      = Join-Path -Path $([Environment]::GetFolderPath('MyDocuments') + $ConfigurationData.LabConfig.FilePaths.Unattend.OutputFolder) -ChildPath "$($vm.NodeName)_unattend.xml"
                    Destination = 'unattend.xml'
                    Type        = 'File'
                },

                @{
                    Label       = 'NodeMof'
                    Source      = Join-Path -Path $([Environment]::GetFolderPath('MyDocuments') + $ConfigurationData.LabConfig.FilePaths.GeneratedMOFs.RoleMOFs) -ChildPath "$($vm.NodeName).mof"
                    Destination = '\windows\system32\Configuration\Pending.mof'
                    Type        = 'File'
                },

                @{
                    Label       = 'NodeLcmMof'
                    Source      = Join-Path -Path $([Environment]::GetFolderPath('MyDocuments') + $ConfigurationData.LabConfig.FilePaths.GeneratedMOFs.RoleMOFs) -ChildPath 'localhost.meta.mof'
                    Destination = '\windows\system32\Configuration\metaconfig.mof'
                    Type        = 'File'
                },

                @{
                    Label       = 'AutoRun'
                    Source      = Join-Path -Path $([Environment]::GetFolderPath('MyDocuments')) -ChildPath $ConfigurationData.LabConfig.FilePaths.ToCopy.BootstrapFolder
                    Destination = '\ArdyLab\'
                    Type        = 'Directory'
                }
            )
            $modToCopy = @( 'xActiveDirectory',
                'xComputerManagement',
                'xDismFeature',
                'xNetworking',
                'xSQLServer',
                'xSystemSecurity',
                'xSmbShare',
                'xStorage',
                'SecurityPolicyDsc'
            )

            foreach ($modName in $modToCopy) {
                $CopyToVHD += @{
                    Label       = "$modName"
                    Source      = Join-Path -Path 'C:\Program Files\WindowsPowerShell\Modules' -ChildPath "$modName"
                    Destination = "\Program Files\WindowsPowerShell\Modules\$modName\"
                    Type        = 'Directory'
                }
            }

            # Create collection of VHD's to attach to this node
            $MountVHD = @()
            if ($vm.DataDisk) {

                # Attach the VHD(x) on the Hyper-V host to this VM
                foreach ($vhd in $vm.DataDisk) {
                    $MountVHD += $vhd
                }
            }

            # Check if this node has the 'FileServer' role & add any additional VHD's
            if ($vm.role -contains 'FileServer') {
                $MountVHD += $ConfigurationData.Roles.FileServer.MountVHD
            }

            # Create a custom Unattend.xml file for each node
            LabCreateUnattendFile "$($vm.NodeName)_UnattendFile"
            {
                NodeName      = $vm.NodeName
                IP4Addr       = $vm.Ip4Addr
                AdminName     = $_adminName
                AdminPassword = $_adminPassword
                UnattendOutputPath = Join-Path -Path $([Environment]::GetFolderPath('MyDocuments')) -ChildPath $ConfigurationData.LabConfig.FilePaths.Unattend.OutputFolder
                UnattendTemplateFile = Join-Path -Path $([Environment]::GetFolderPath('MyDocuments')) -ChildPath $ConfigurationData.LabConfig.FilePaths.Unattend.TemplateFile
            }

            # ArdyLab Resource to Create a Hyper-V Virtual Machine for the specified node and inject required files to the VHDX that is created
            LabBuildVM_HyperV "$($vm.NodeName)"
            {
                NodeName       = $vm.NodeName
                VSwitchName    = $ConfigurationData.LabConfig.VSwitch.Name
                VHDTemplate    = $vm.VHDTemplate
                ProcessorCount = $vm.ProcessorCount
                MaximumMemory  = $vm.MaximumMemory
                CopyToVHD      = $CopyToVHD
            }

            # Check if we need to attach any additonal VHD(x) files to this VM
            # Having to use workaround as xHyper-V/xVMHyperV only allows to attach a single VHD(x)
            if ($MountVHD) {
                # Attach the VHD(x) on the Hyper-V host to this VM
                foreach ($vhd in $mountVHD) {
                    if (!$vhd.Path) {
                        xVHD "CreateDataDisk_$($vhd.Name)"
                        {
                            Ensure           = 'Present'
                            Name             = "$($vm.NodeName)_$($vhd.Name)"
                            Path = Join-Path -Path $((Get-VMHost).VirtualHardDiskPath) -ChildPath $vm.NodeName
                            ParentPath       = $vhd.ParentPath
                            MaximumSizeBytes = $vhd.MaximumSizeBytes
                            Generation       = 'vhdx'
                        }

                        $path = Join-Path -Path $((Get-VMHost).VirtualHardDiskPath) -ChildPath $vm.NodeName
                        $path = Join-Path -Path $path -ChildPath "$($vm.NodeName)_$($vhd.Name).vhdx"
                    }
                    else {
                        $path = $vhd.path
                    }

                    # Put DSC code here for 'WaitForDisk' to check a disk exists before trting to mount it with LabAddVHD
                    # Check if LabAddVHD can now be replaced by xStorage updates




                    LabAddVHD "$($vhd.Name)"
                    {
                        NodeName           = $vm.NodeName
                        Path               = $path
                        ControllerType     = $vhd.ControllerParams.ControllerType
                        ControllerLocation = $vhd.ControllerParams.ControllerLocation
                        ControllerNumber   = $vhd.ControllerParams.ControllerNumber
                    }
                }
            }
        }
    }
}
