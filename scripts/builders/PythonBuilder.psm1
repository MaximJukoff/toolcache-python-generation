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

    ### Build

    [void] Make() {
        $outputFile = Join-Path -Path $this.ArtifactLocation -ChildPath "build_output.txt"
        make | Tee-Object -FilePath $outputFile
        make install
    }

    [void] CreateToolStructureDump() {
        $outputFile = Join-Path -Path $this.GetPythonVersionArchitectureLocation() "tools_structure.txt"

        $folderContent = Get-ChildItem -Path $this.ArtifactLocation -Recurse | Sort-Object | Select-Object -Property FullName, Length
        $folderContent | ForEach-Object {
            $relativePath = $_.FullName.Replace($ToolPath, "");
            $fileSize = $_.Length
            return "${relativePath} : ${fileSize} bytes"
        } | Out-File -FilePath $outputFile
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
