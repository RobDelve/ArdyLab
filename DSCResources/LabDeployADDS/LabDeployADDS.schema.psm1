#requires -Version 4.0
<#
    .Synopsis
    ArdyLab DSC Resource to install & Configure Microsoft ADDS and required services.

    .Description
    ArdyLab DSC Resource that uses ... blah, blah
    
    .TODO
    Add Error Checking and Verbose/Debug output
#>
Configuration LabDeployADDS
{
  param             
  (    
    [Parameter(Mandatory)]             
    [string]
    $DomainName,

    [Parameter(Mandatory)]             
    [pscredential]
    $DomainAdmin,

    [Parameter()]             
    [pscredential]
    $SafeModeAdmin = $DomainAdmin,

    [Parameter()]             
    [psobject]
    $DomainOUs = $null,

    [Parameter()]             
    [psobject]
    $DomainGroups = $null,

    [Parameter()]             
    [psobject]
    $DomainUsers = $null
  )

  Import-DscResource -ModuleName xActiveDirectory
  Import-DscResource -ModuleName PSDesiredStateConfiguration
         
  WindowsFeature InstallADDS             
  {             
    Ensure = 'Present'             
    Name = 'AD-Domain-Services'             
  }            
            
  # Optional GUI tools            
  WindowsFeature InstallADDSTools
  {             
    Ensure = 'Present'             
    Name = 'RSAT-ADDS'             
  }            
                       
  xADDomain CreateDomain             
  {             
    DomainName = $DomainName             
    DomainAdministratorCredential = $DomainAdmin             
    SafemodeAdministratorPassword = $SafeModeAdmin                     
    DependsOn = '[WindowsFeature]InstallADDS'          
  } 

  xWaitForADDomain $DomainName
  {
    DomainName = $DomainName
    RetryCount = 20
    RetryIntervalSec = 5      
  }

  xADUser SetAdministrator
  {
    DomainName = $DomainName
    UserName = (($DomainAdmin.UserName) -split '\\')[-1]
    Password = $DomainAdmin
  }

  foreach ($ou in $DomainOUs)
  {
    # Check if a value for 'Path' has been provided for this $ou
    if ($ou.path -notlike '') 
    {
      $ouPath = "$($ou.Path),DC=$(($DomainName -split '\.')[0]),DC=$(($DomainName -split '\.')[1])" 
    }
    else 
    {
      $ouPath = "DC=$(($DomainName -split '\.')[0]),DC=$(($DomainName -split '\.')[1])" 
    }

    xADOrganizationalUnit $ou.Name
    {
      Name = $ou.Name
      Path = $ouPath
      ProtectedFromAccidentalDeletion = $ou.ProtectedFromAccidentalDeletion
      Description = $ou.Description
      Ensure = $ou.Ensure
      DependsOn = "[xWaitForADDomain]$DomainName"
    }
  }

  foreach ($user in $DomainUsers)
  {
    # Prepare user credentials
    $userpw = ConvertTo-SecureString -String $user.Password -AsPlainText -Force
    $userCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($user.UserName, $userpw)
        
    # Check if a value for 'Path' has been provided for this $user
    if ($user.path -notlike '') 
    {
      $userPath = "$($user.Path),DC=$(($DomainName -split '\.')[0]),DC=$(($DomainName -split '\.')[1])" 
    }
    else 
    {
      $userPath = "OU=Users, DC=$(($DomainName -split '\.')[0]),DC=$(($DomainName -split '\.')[1])" 
    }

    xADUser $user.UserName
    { 
      DomainName = $DomainName
      UserName = $user.UserName
      Password = $userCred
      UserPrincipalName = "$($user.UserName)@$($DomainName)"
      GivenName = $user.UserName
      Surname = $user.Surname 
      DisplayName = $user.DisplayName
      PasswordNeverExpires = $user.PasswordNeverExpires
      Enabled = $user.Enabled
      Path = "$($user.Path),DC=$(($DomainName -split '\.')[0]),DC=$(($DomainName -split '\.')[1])"
      Ensure = $user.Ensure  
      DependsOn = "[xADOrganizationalUnit]$($ou.Name)"
    }
  } 

  foreach ($group in $DomainGroups)
  {   
    # Check if a value for 'Path' has been provided for this $group  
    if ($group.path -notlike '') 
    {
      $groupPath = "$($group.Path),DC=$(($DomainName -split '\.')[0]),DC=$(($DomainName -split '\.')[1])" 
    }
    else 
    {
      $groupPath = "DC=$(($DomainName -split '\.')[0]),DC=$(($DomainName -split '\.')[1])" 
    }

    xADGroup $group.GroupName
    { 
      GroupName = $group.GroupName
      GroupScope = $group.GroupScope
      Description = $group.Description
      MembersToInclude = $group.IncludeMembers
      DisplayName = $group.DisplayName        
      Path = $groupPath
      Ensure = $group.Ensure  
      DependsOn = "[xADOrganizationalUnit]$($ou.Name)", "[xADUser]$($user.UserName)"
    }
  }
}