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
        $extension = if ($this.Version -lt "3.5" -and $this.Version -ge "2.5") { ".msi" } else { ".exe" }

        return $extension
    }

    [string] hidden GetArchitectureExtension() {
        $architectureExtension = if ($this.Architecture -eq "x64") { "-amd64" } else { "" }

        return $architectureExtension
    }

    [uri] GetSourceUri() {
        $base = $this.GetBaseUri()
        $architecture = $this.GetArchitectureExtension()
        $extension = $this.GetPythonExtension()

        $uri = "${base}/$($this.Version)/python-$($this.Version)${architecture}${extension}"

        return $uri
    }

    [string] Download() {
        $sourceUri = $this.GetSourceUri()

        Write-Host "Sources URI: $sourceUri"
        $sourcesLocation = Download-File -Uri $sourceUri -BinPathFolder $this.ArtifactLocation

        return $sourcesLocation
    }

    [void] CreateInstallationScript() {
        $installationScriptPath = "./installers/win_setup_template.ps1"
        Copy-Item -Path $installationScriptPath -Destination "$($this.ArtifactLocation)/setup.ps1"
    }

    [void] Build() {
        Write-Host "Download Python $($this.Version)[$($this.Architecture)] executable..."
        $this.Download()

        Write-Host "Create installation script..."
        $this.CreateInstallationScript()
    }
}
