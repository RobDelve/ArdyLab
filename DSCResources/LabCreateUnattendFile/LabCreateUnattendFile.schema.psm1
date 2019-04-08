#requires -Version 4.0
<#
    .Synopsis
    blah

    .Description
    blah, blah
#>
configuration LabCreateUnattendFile {
  Param 
  (
    [Parameter(Mandatory)]
    [string]
    $UnattendTemplateFile,

    [Parameter(Mandatory)]
    [string]
    $UnattendOutputPath,

    [Parameter(Mandatory)]
    [string]
    $NodeName,

    [Parameter(Mandatory)]
    [string]
    $IP4Addr,
           
    [Parameter(Mandatory)]
    [string]
    $AdminName,

    [Parameter(Mandatory)]
    [string]
    $AdminPassword
  )

  Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
   
  Script CreateUnattendFile
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
      [xml]$unattendFile = Get-Content -Path $using:UnattendTemplateFile
            
      ## FIX to find correct section by name, rather than index !!
      Write-Verbose -Message "Generating a custom 'unattend.xml' for '$using:NodeName'."
      
      $specialize = $unattendFile.unattend.settings.Where{$_.pass -eq 'specialize'}
      $oobe = $unattendFile.unattend.settings.Where{$_.pass -eq 'oobe'}
      $setupInfo = $specialize.component.Where{$_.name -eq 'Microsoft-Windows-Shell-Setup'}
      $tcpInfo = $specialize.component.Where{$_.name -eq 'Microsoft-Windows-TCPIP'}.Interfaces.Interface.UnicastIpAddresses

      
      $setupInfo.ForEach{ $_.ComputerName = $using:NodeName }

      $unattendFile.unattend.settings.Where{$_.pass -eq 'specialize'}.component.Where{$_.name -eq 'Microsoft-Windows-TCPIP'}.Interfaces.Interface.UnicastIpAddresses.IpAddress.'#text' = $using:IP4Addr
      #$unattendFile.unattend.settings.component[1].Interfaces.Interface.UnicastIpAddresses.IpAddress.'#text' = $using:IP4Addr
      $unattendFile.unattend.settings.component[3].UserAccounts.AdministratorPassword.Value = $using:AdminPassword
            
      $unattendFile.unattend.settings.component[3].UserAccounts.LocalAccounts.LocalAccount.Name = $using:AdminName
      $unattendFile.unattend.settings.component[3].UserAccounts.LocalAccounts.LocalAccount.Password.Value = $using:AdminPassword
      $unattendFile.unattend.settings.component[3].UserAccounts.LocalAccounts.LocalAccount.DisplayName = $using:AdminName

      $unattendFile.unattend.settings.component[3].AutoLogon.Password.Value = $using:AdminPassword
      $unattendFile.unattend.settings.component[3].AutoLogon.Username = $using:AdminName

      
      $customUnattendFile = "$(Join-Path -Path $($using:UnattendOutputPath) -ChildPath "$($using:NodeName)_unattend.xml")"
      Write-Verbose -Message "Saving the generated 'unattend.xml' file as '$customUnattendFile'."      
      $unattendFile.Save($customUnattendFile)                
    } 
  }
}