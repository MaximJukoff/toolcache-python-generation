class PythonBuilder {
    # Properties
    [version] $Version
    [string] $Architecture
    [string] $HostedToolcacheLocation
    [string] $TempFolderLocation
    [string] $ArtifactLocation
    [string] $InstallationTemplatesLocation

    PythonBuilder ([version] $version, [string] $architecture) {
        $this.Version = $version
        $this.Architecture = $architecture

        $this.HostedToolcacheLocation = $env:AGENT_TOOLSDIRECTORY
        $this.TempFolderLocation = $env:BUILD_STAGINGDIRECTORY
        $this.ArtifactLocation = $env:BUILD_BINARIESDIRECTORY
        $this.InstallationTemplatesLocation = Join-Path -Path $PSScriptRoot -ChildPath "../installers"
    }

    [uri] GetBaseUri() {
        return "https://www.python.org/ftp/python"
    }

    [string] GetPythonToolcacheLocation() {
        return "$($this.HostedToolcacheLocation)/Python"
    }

    [string] GetFullPythonToolcacheLocation() {
        $pythonToolcacheLocation = $this.GetPythonToolcacheLocation()
        return "$pythonToolcacheLocation/$($this.Version)/$($this.Architecture)"
    }

    [void] PreparePythonToolcacheLocation() {
        $pythonBinariesLocation = $this.GetFullPythonToolcacheLocation()

        if (Test-Path $pythonBinariesLocation) {
            Write-Host "Purge $pythonBinariesLocation folder..."

            Remove-Item $pythonBinariesLocation -Recurse -Force
        } else {
            Write-Host "Create $pythonBinariesLocation folder..."

            New-Item -ItemType Directory -Path $pythonBinariesLocation 
        }
    }
}
