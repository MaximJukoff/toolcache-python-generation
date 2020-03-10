using module "./builders/WinPythonBuilder.psm1"
using module "./builders/NixPythonBuilder.psm1"
using module "./builders/macOSPythonBuilder.psm1"

param(
    [Parameter (Mandatory=$true)]
    [version] $Version,
    [string] $Architecture = "x64",
    [Parameter (Mandatory=$true)]
    [string] $Platform
)

$ErrorActionPreference = "Stop"

Import-Module "../helpers/common-helpers.psm1" -DisableNameChecking -Force
Import-Module "../helpers/nix-helpers.psm1" -DisableNameChecking -Force
Import-Module "../helpers/win-helpers.psm1" -DisableNameChecking -Force

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
        $builder = [WinPythonBuilder]::New($Platform, $Version, $Architecture)
    } elseif ($Platform -match 'ubuntu') {
        $builder = [UbuntuPythonBuilder]::New($Platform, $Version)
    } elseif ($Platform -match 'macos') {
        $builder = [macOSPythonBuilder]::New($Platform, $Version)
    } else {
        exit 1
    }

    return $builder
}

$Builder = Get-PythonBuilder -Version $Version -Platform $Platform -Architecture $Architecture
$Builder.Build()
