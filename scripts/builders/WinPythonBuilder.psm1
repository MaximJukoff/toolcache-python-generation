class WinPythonBuilder : PythonBuilder {
    [string] $Platform

    WinPythonBuilder(
        [string] $platfrom,
        [version] $version,
        [string] $architecture
    ) : Base($Version, $Architecture) {
        $this.Platform = $platfrom
    }

    [string] hidden GetPythonExtension() {
        $_version = $this.Version
        $extension = if ($_version -lt "3.5" -and $_version -ge "2.5") { ".msi" } else { ".exe" }

        return $extension
    }

    [string] hidden GetArchitectureExtension() {
        $_architecture = $this.Architecture
        $archExtension = if ($_architecture -eq "x64") { "-amd64" } else { "" }

        return $archExtension
    }

    [uri] GetSourceUri() {
        $_base = $this.GetBaseUri()
        $_arch = $this.GetArchitectureExtension()
        $_version = $this.Version
        $_extension = $this.GetPythonExtension()

        $uri = "${_base}/${_version}/python-${_version}${_arch}${_extension}"

        return $uri
    }

    [string] Download() {
        $_sourceUri = $this.GetSourceUri()
        $_artifactLocation = $this.ArtifactLocation

        Write-Host "Sources URI: $_sourceUri"
        $sourcesLocation = Download-File -Uri $_sourceUri -BinPathFolder $_artifactLocation

        return $sourcesLocation
    }
}