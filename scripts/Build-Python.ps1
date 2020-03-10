using module "./builders/WinPythonBuilder.psm1"
using module "./builders/NixPythonBuilder.psm1"
using module "./builders/UbuntuPythonBuilder.psm1"
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

    $ConfigLocation = "./config.json"

    $Platform = $Platform.ToLower()  
    if ($Platform -match 'windows') {
        $builder = [WinPythonBuilder]::New($ConfigLocation, $Platform, $Version, $Architecture)
    } elseif ($Platform -match 'ubuntu') {
        $builder = [UbuntuPythonBuilder]::New($ConfigLocation, $Platform, $Version)
    } elseif ($Platform -match 'macos') {
        $builder = [macOSPythonBuilder]::New($ConfigLocation, $Platform, $Version)
    } else {
        Write-Host "##vso[task.logissue type=error;] Invalid platform: $Platform"
        exit 1
    }

    return $builder
}

$Builder = Get-PythonBuilder -Version $Version -Platform $Platform -Architecture $Architecture
$Builder.Build()
