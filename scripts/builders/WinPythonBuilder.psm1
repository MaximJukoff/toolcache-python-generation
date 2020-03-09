using module "./builders/PythonBuilder.psm1"

class WinPythonBuilder : PythonBuilder {
    # Properties
    [string] $Platform

    WinPythonBuilder(
        [string] $platfrom,
        [version] $version,
        [string] $architecture
    ) : Base($version, $architecture) {
        $this.Platform = $platfrom
    }

    [string] hidden GetPythonExtension() {
        $_version = $this.Version
        $extension = if ($_version -lt "3.5" -and $_version -ge "2.5") { ".msi" } else { ".exe" }

        return $extension
    }

    [string] hidden GetArchitectureExtension() {
        $_architecture = $this.Architecture
        $architectureExtension = if ($_architecture -eq "x64") { "-amd64" } else { "" }

        return $architectureExtension
    }

    [uri] GetSourceUri() {
        $_version = $this.Version
        $base = $this.GetBaseUri()
        $architecture = $this.GetArchitectureExtension()
        $extension = $this.GetPythonExtension()

        $uri = "${base}/${_version}/python-${_version}${architecture}${extension}"

        return $uri
    }

    [string] Download() {
        $_artifactLocation = $this.ArtifactLocation
        $sourceUri = $this.GetSourceUri()

        Write-Host "Sources URI: $sourceUri"
        $sourcesLocation = Download-File -Uri $sourceUri -BinPathFolder $_artifactLocation

        return $sourcesLocation
    }

    [void] CreateInstallationScript() {
        $installationScriptPath = "../installers/win_setup_template.ps1"
        Copy-Item -Path $installationScriptPath -Destination "$($this.ArtifactLocation)/setup.ps1"
    }

    [void] Build() {
        Write-Host "Download Python $($this.Version)[$($this.Architecture)] executable..."
        $this.Download()

        Write-Host "Create installation script..."
        $this.CreateInstallationScript()
    }
}
