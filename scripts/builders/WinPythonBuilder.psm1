using module "./builders/PythonBuilder.psm1"

class WinPythonBuilder : PythonBuilder {
    # Properties
    [string] $InstallationTemplateName
    [string] $InstallationScriptName

    WinPythonBuilder(
        [version] $version,
        [string] $architecture
    ) : Base($version, $architecture) {
        $this.InstallationTemplateName = "win_setup_template.ps1"
        $this.InstallationScriptName = "setup.ps1"
    }

    [string] GetPythonExtension() {
        $extension = if ($this.Version -lt "3.5" -and $this.Version -ge "2.5") { ".msi" } else { ".exe" }

        return $extension
    }

    [string] GetArchitectureExtension() {
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
        $sourceUri = $this.GetSourceUri()
        $pythonExecName = $sourceUri.AbsoluteUri.Split("/")[-1]
        $installationTemplateLocation = Join-Path -Path $this.InstallationTemplatesLocation -ChildPath $this.InstallationTemplateName
        $installationScript = Get-Content -Path $installationTemplateLocation -Raw

        $installationScript = $installationScript.Replace("__ARCHITECTURE__", $this.Architecture)
        $installationScript = $installationScript.Replace("__VERSION__", $this.Version)
        $installationScript = $installationScript.Replace("__PYTHON_EXEC_NAME__", $pythonExecName)

        $installationScript | Out-File -Path "$($this.ArtifactLocation)/$($this.InstallationScriptName)"
    }

    [void] Build() {
        Write-Host "Download Python $($this.Version)[$($this.Architecture)] executable..."
        $this.Download()

        Write-Host "Create installation script..."
        $this.CreateInstallationScript()
    }
}
