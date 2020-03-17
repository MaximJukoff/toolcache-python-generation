class PythonBuilder {
    [version] $Version
    [string] $Architecture
    [string] $HostedToolcacheLocation
    [string] $TempFolderLocation
    [string] $ArtifactLocation
    [string] $ArtifactName 

    PythonBuilder ([version] $version, [string] $architecture) {
        $this.Version = $version
        $this.Architecture = $architecture

        $this.HostedToolcacheLocation = $env:AGENT_TOOLSDIRECTORY
        $this.TempFolderLocation = $env:BUILD_STAGINGDIRECTORY
        $this.ArtifactLocation = $env:BUILD_BINARIESDIRECTORY

        $this.ArtifactName = "tool.zip"
    }

    [uri] GetBaseUri() {
        return "https://www.python.org/ftp/python"
    }

    [string] GetPythonToolcacheLocation() {
        return "$($this.HostedToolcacheLocation)/Python/$($this.Version)/$($this.Architecture)"
    }

    [void] PreparePythonToolcacheLocation() {
        $_pythonBinariesLocation = $this.GetPythonToolcacheLocation()

        if (Test-Path $_pythonBinariesLocation) {
            Write-Host "Purge $_pythonBinariesLocation folder..."

            Remove-Item $_pythonBinariesLocation -Recurse -Force
        } else {
            Write-Host "Create $_pythonBinariesLocation folder..."

            New-Item -ItemType Directory -Path $_pythonBinariesLocation 
        }
    }
}

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