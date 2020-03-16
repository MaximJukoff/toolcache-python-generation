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
        Write-Debug "Done; Sources location: $sourcesLocation"

        return $sourcesLocation
    }

    [void] CreateInstallationScript() {
        $sourceUri = $this.GetSourceUri()
        $pythonExecName = $sourceUri.AbsoluteUri.Split("/")[-1]
        $installationTemplateLocation = Join-Path -Path $this.InstallationTemplatesLocation -ChildPath $this.InstallationTemplateName
        $installationTemplate = Get-Content -Path $installationTemplateLocation -Raw
        $installationScriptLocation = New-Item -Path $this.ArtifactLocation -Name $this.InstallationScriptName -ItemType File

        $installationTemplate = $installationTemplate.Replace("__ARCHITECTURE__", $this.Architecture)
        $installationTemplate = $installationTemplate.Replace("__VERSION__", $this.Version)
        $installationTemplate = $installationTemplate.Replace("__PYTHON_EXEC_NAME__", $pythonExecName)

        $installationTemplate | Out-File -FilePath $installationScriptLocation
        Write-Debug "Done; Installation script location: $installationScriptLocation)"
    }

    [void] Build() {
        Write-Host "Download Python $($this.Version)[$($this.Architecture)] executable..."
        $this.Download()

        Write-Host "Create installation script..."
        $this.CreateInstallationScript()
    }
}
