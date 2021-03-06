#requires -Version 4.0
<#
    .Synopsis
    ArdyLab DSC Resource to Configure a LocalGroup on a node.

    .Description
    Populate Local Groups with custom User/Groups
    Add required entries to the array $LocalAdminGroupMembers
    
    .TODO
    Add Error Checking and Verbose/Debug output
#>

Configuration LabConfigureLocalGroup
{
  param             
  (   
    # Name of the Local Group to configure
    [Parameter(Mandatory)]             
    [string]
    $GroupName,

    # Credential for user account with permissions to configure the Local Group
    [Parameter(Mandatory)]             
    [pscredential]
    $Credential,

    # Domain that contains the User/Group accounts in $MembersToInclude. If $null then will use Local Accounts 
    [Parameter()]             
    [string]
    $DomainName,

    # Collection of User/Group accounts to apply to the Local Group
    [Parameter()]             
    [psobject]
    $MembersToInclude,

    [Parameter()]             
    [string]
    $Ensure = 'Present'

  )

  Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
        
  $localAdminGroupMembers = @()

  foreach ($principal in $MembersToInclude)
  {
    $LocalAdminGroupMembers += "$(($DomainName -split '\.')[0])\$($principal)"
  }       

  if ($LocalAdminGroupMembers)
  {
    Group $GroupName
    {
      GroupName        = $GroupName
      MembersToInclude = $localAdminGroupMembers
      Ensure           = $Ensure
      Credential       = $Credential
    }
  }
}
