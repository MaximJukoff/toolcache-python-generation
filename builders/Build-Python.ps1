using module "./builders/WinPythonBuilder.psm1"
using module "./builders/UbuntuPythonBuilder.psm1"
using module "./builders/macOSPythonBuilder.psm1"

param(
    [Parameter (Mandatory=$true)]
    [version] $Version,
    [string] $Architecture = "x64",
    [Parameter (Mandatory=$true)]
    [string] $Platform
)

$DebugPreference = 'Continue'
$VerbosePreference = 'Continue'

Import-Module (Join-Path $PSScriptRoot "../helpers" | Join-Path -ChildPath "common-helpers.psm1") -DisableNameChecking
Import-Module (Join-Path $PSScriptRoot "../helpers" | Join-Path -ChildPath "nix-helpers.psm1") -DisableNameChecking

<#
Wrapper for class constructor to simplify importing PythonBuilder
#>

function Get-PythonBuilder {
    param (
        [version] $Version,
        [string] $Architecture,
        [string] $Platform
    )

    $Platform = $Platform.ToLower()  
    if ($Platform -match 'windows') {
        $builder = [WinPythonBuilder]::New($Version, $Architecture)
    } elseif ($Platform -match 'ubuntu') {
        $builder = [UbuntuPythonBuilder]::New($Platform, $Version)
    } elseif ($Platform -match 'macos') {
        $builder = [macOSPythonBuilder]::New($Platform, $Version)
    } else {
        Write-Host "##vso[task.logissue type=error;] Invalid platform: $Platform"
        exit 1
    }

    return $builder
}

$Builder = Get-PythonBuilder -Version $Version -Platform $Platform -Architecture $Architecture
$Builder.Build()
