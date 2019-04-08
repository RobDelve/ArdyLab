#requires -Version 4.0
# Sample LabAutoRun.ps1

# Last Updated: R Delve - 06 Feb 2018

# If running PowerShell v4, remove the version folder from the Modules that were injected during build
if ($PSVersionTable.PSVersion.Major -eq 4)
{
  # As this is PS v4 the only Modules in the \Program Files\WindowsPowerShell\Modules are those that have been injected during build
  # No need to worry about multiple versions (being lazy!) - Assuming that only one version will be injected at build time...    
    
  Write-Output -InputObject 'Applying fixes for PowerShell v4...'
  $modCollection = (Get-ChildItem -Path "$env:SystemDrive\Program Files\WindowsPowerShell\Modules").FullName

  foreach ($modPath in $modCollection)
  {
    $modName = ($modPath -split '\\')[-1]        

    Write-Output -InputObject ("Checking paths for module '{0}'." -f $modName)
        
    # Lazy! checking if result matches 0.0.0.0 version naming
    # Will return False if first path returned not a match
    # Not an issue as should only ever be 1 version of a Module injected during build
    if ((Get-ChildItem -Path $modPath)[0].Name -match '\d*.\d*.\d*.\d*' -eq $true  )
    {
      Write-Output -InputObject (" ...Fixing path names for the module '{0}'" -f $modName)
      Copy-Item -Path "$modPath\*\*" -Destination $modPath -Recurse
    }
  }

  # Enable PSRemoting
  Write-Output -InputObject 'Enabling PS Remoting.'
  Enable-PSRemoting -Force
}
elseif ($PSVersionTable.PSVersion.Major -gt 4)
{
  Write-Output -InputObject ("PowerShell v{0} - no need to fix module paths or run 'Enable-PSRemoting'" -f $PSVersionTable.PSVersion.Major)
}


# TEST!!!
Set-WSManQuickConfig -SkipNetworkProfileCheck -Verbose -Force
Set-Item WSMan:\localhost\MaxEnvelopeSizekb -Value 4096


schtasks.exe /Create /SC ONSTART /TN "\Ardy\ArdyLab\Desired State Configuration\DSCRestartBootTask" /RU System /F /TR "PowerShell.exe -NonInt -Command 'Invoke-CimMethod -ComputerName localhost -Namespace root/Microsoft/Windows/DesiredStateConfiguration -ClassName MSFT_DSCLocalConfigurationManager -MethodName PerformRequiredConfigurationChecks -Arg @{Flags = [System.UInt32]1 }"



