class WinPythonBuilder : PythonBuilder {
    [string] $Platform

    WinPythonBuilder(
        [version] $Version,
        [string] $Architecture,
        [string] $Platform
    ) : base ($Version, $Architecture) {
        $this.Platform = $Platform  
    }

    [string] hidden GetPythonExtension() {
        $_version = $this.GetVersion()
        $extension = if ($_version -lt "3.5" -and $_version -ge "2.5") { ".msi" } else { ".exe" }
        return $extension
    }

    [string] hidden GetArchitectureExtension() {
        $_architecture = $this.GetArchitecture()
        $extension = if ($_architecture -eq "x64") { "-amd64" } else { "" }
        return $extension
    }

    [uri] GetSourceUri() {
        $_base = $this.GetBaseUri()
        $_arch = $this.GetArchitectureExtension()
        $_version = $this.GetVersion()
        $_extension = $this.GetPythonExtension()
        
        $uri = "${_base}/${_version}/python-${_version}${_arch}${_extension}"

        return $uri
    }

    [void] DownloadSources() {
        $_sourceUri = $this.GetSourceUri()

        # TODO
    }

    ### TODO
}