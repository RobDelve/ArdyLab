
# Set up variables used throghout this ArdyLab module

$script:modulePath = $PSScriptRoot
$script:LabSourcePath = "$env:ProgramFiles\WindowsPowerShell\Modules\ArdyLab\resources\Templates"
$script:MyDocsPath = "$([Environment]::GetFolderPath("MyDocuments"))"
$script:UserLabPath = $(Join-Path -Path $MyDocsPath -ChildPath 'ArdyLab')

$script:LabManifestPath = $(Join-Path -Path $script:UserLabPath -ChildPath 'LabManifest')
$script:unattendPath = Join-Path -Path $UserLabPath -ChildPath 'Data\windows\Unattend'
$script:mofPath = Join-Path -Path $UserLabPath -ChildPath 'Data\GeneratedMOFs'
$script:templatePath = Join-Path -Path $UserLabPath -ChildPath 'Templates'

$script:__DynParamConfigFile = {$atr = New-Object -TypeName System.Management.Automation.ParameterAttribute
    $atr.ParameterSetName = '__AllParameterSets'
    $atr.Mandatory = $true
    $atrCol = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
    $atrCol.Add($atr)
    $value = (Get-ChildItem -Path $LabManifestPath).name
    $valSet = New-Object -TypeName System.Management.Automation.ValidateSetAttribute -ArgumentList ($value)
    $atrCol.Add($valSet)
    $param = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList ('ConfigFile', [string], $atrCol)
    $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
    $paramDictionary.Add('ConfigFile', $param)

    return $paramDictionary
}

$functionFolders = @('functions', 'internal')
ForEach ($folder in $functionFolders)
{
    $folderPath = Join-Path -Path $PSScriptRoot -ChildPath $folder
    If (Test-Path -Path $folderPath)
    {
        Write-Verbose -Message "Importing from $folder"
        $functions = Get-ChildItem -Path $folderPath -Filter '*.ps1'
        ForEach ($function in $functions)
        {
            Write-Verbose -Message "  Importing $($function.BaseName)"
            . $function.PSPath
        }
    }
}
$publicFunctions = (Get-ChildItem -Path "$PSScriptRoot\functions" -Filter '*.ps1').BaseName
Export-ModuleMember -Function $publicFunctions

