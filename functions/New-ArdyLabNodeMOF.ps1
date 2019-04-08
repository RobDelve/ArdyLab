<#
.Synopsis
    ..
.DESCRIPTION
    ...
.EXAMPLE

.EXAMPLE

.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Custom PowerShell Object
.LINK
    http://www.ardy.co.uk
.NOTES
  Created by Rob Delve (rob@ardy.co.uk) 2016
#>
function New-ArdyLabNodeMOF {
    [CmdletBinding()]
    Param()

    DynamicParam {
        Invoke-Command -ScriptBlock $__DynParamConfigFile
    }

    Begin {
        #Import-Module 'ArdyLab\Private\LabCreateNodeMOF.ps1' -Force -Scope Local
    }

    Process {
        $ConfigFile = Join-Path -Path $LabManifestPath -ChildPath $($PSBoundParameters.ConfigFile)

        $ConfigData = Get-Content $ConfigFile -Raw | ConvertFrom-Json | ConvertPSObjectToHashtable

        Write-Verbose -Message 'Generating a custom MOF for each VM, that will be injected during VM creation'
        $mofFile = LabCreateNodeMOF -ConfigurationData $ConfigData -OutputPath $mofPath\ToBeInjected\

        foreach ($file in $mofFile) {
            Write-Verbose -Message "Created file '$file'."
        }
    }
}