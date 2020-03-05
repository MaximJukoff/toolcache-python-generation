class PythonBuilder {
    [version] $Version
    [string] $Architecture
    [string] $HostedToolcacheLocation
    [string] $TempFolderLocation
    [string] $ArtifactLocation

    PythonBuilder(
        [version] $Version,
        [string] $Architecture
    ) {
        $this.Version = $Version
        $this.Architecture = $Architecture

        $this.HostedToolcacheLocation = $env:AGENT_TOOLSDIRECTORY
        $this.TempFolderLocation = $env:BUILD_STAGINGDIRECTORY
        $this.ArtifactLocation = $env:BUILD_BINARIESDIRECTORY
    }

    [uri] GetBaseUri() {
        return "https://www.python.org/ftp/python"
    }

    [string] GetVersion() {
        return $this.Version
    }

    [string] GetArchitecture() {
        return $this.Architecture
    }

    [string] GetHostedToolcacheLocation() {
        return $this.HostedToolcacheLocation
    }

    [string] GetTempFolderLocation() {
        return $this.TempFolderLocation
    }

    [string] GetArtifactLocation() {
        return $this.ArtifactLocation
    }

    [string] GetPythonVersionArchitectureLocation() {
        $_version = $this.Version
        $_architecture = $this.Architecture
        $_hostedToolcacheLocation = $this.HostedToolcacheLocation

        $location = "${_hostedToolcacheLocation}/Python/${_version}/${_architecture}"

        return $location
    }

    [void] CreateToolStructureDump() {
        ### TODO
    }

    [void] Make() {
        $_artifactLocation = $this.GetArtifactLocation()
        $buildOutputFile = "${_artifactLocation}/build_output.txt"
        make | Tee-Object -FilePath $buildOutputFile
        make install
    }

}

<#
Wrapper for class constructor to simplify importing PythonBuilder
#>

function Get-PythonBuilder {
    param (
        [version] $Version,
        [string] $Platform,
        [string] $Architecture
    )
    
    if ($Platform -match 'windows') {
        $builder = [WinPythonBuilder]::New($Version, $Platform, $Architecture)
    } else {
        $builder = [NixPythonBuilder]::New($Version, $Platform)
    }

    return $builder
}
