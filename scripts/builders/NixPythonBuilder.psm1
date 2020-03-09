using module "./builders/PythonBuilder.psm1"

class NixPythonBuilder : PythonBuilder {
    # Properties
    [string] $Platform
    [string] $PlatformVersion
    [string] $BuildOutputLocation

    NixPythonBuilder(
        [string] $platform,
        [version] $version
    ) : Base($version, "x64") {
        $this.Platform = $platform.Split("-")[0]
        $this.PlatformVersion = $platform.Split("-")[1]
        $this.BuildOutputLocation = Join-Path -Path $this.ArtifactLocation -ChildPath "build_output.txt"
    }

    [void] SetConfigFlags([string] $flags, [string] $value) {
        $flags = "${value} ${flags}"
    }

    [uri] GetSourceUri() {
        $_version = $this.Version
        $base = $this.GetBaseUri()

        return "${base}/${_version}/Python-${_version}.tgz"
    }

    [string] GetPythonBinary() {
        if ($this.Version.Major -eq 2) { $pythonBinary = "python" } else { $pythonBinary = "python3" }

        return $pythonBinary
    }

    [string] Download() {
        $_sourceUri = $this.GetSourceUri()
        $_tempFolderLocation = $this.TempFolderLocation
        $_artifactLocation = $this.ArtifactLocation
        $pythonSourceLocation = Join-Path -Path $_artifactLocation -ChildPath "Python-$($this.Version).tgz"

        Write-Host "Sources URI: $_sourceUri"
        Download-Source -Uri $_sourceUri -OutFile $pythonSourceLocation -ExpandArchivePath $_tempFolderLocation
        $expandedSourceLocation = Join-Path -Path $_tempFolderLocation -ChildPath "Python-$($this.Version)"

        return $expandedSourceLocation
    }

    [void] ArchiveArtifact() {
        $artifact = Join-Path -Path $this.ArtifactLocation -ChildPath $this.ArtifactName
        Archive-ToolZip -PathToArchive $this.GetPythonToolcacheLocation() -ToolZipFile $artifact 
    }

    [void] GetMissingModules() {
        $searchStringStart = "The necessary bits to build these optional modules were not found:"
        $searchStringEnd = "To find the necessary bits, look in setup.py"
        $pattern = "$searchStringStart(.*?)$searchStringEnd"
    
        $buildContent = Get-Content -Path $this.BuildOutputLocation
        $splitBuiltOutput = $buildContent -split "\n";

        $missingModulesRecordsLocation = New-Item -Path $this.ArtifactLocation -Name "missing_modules.txt" -ItemType File
    
        ### Search for missing modules that are displayed between the search strings
        $regexMatch = [regex]::match($SplitBuiltOutput, $Pattern)
        if ($regexMatch.Success)
        {
            Add-Content $missingModulesRecordsLocation -Value $regexMatch.Groups[1].Value
        }
    }

    [void] GetSysconfigDump() {
        $pythonBinary = $this.GetPythonBinary()
        $pythonBinaryPath = Join-Path -Path $this.GetPythonToolcacheLocation() -ChildPath "bin/$pythonBinary"
        $testSourcePath = "../tests/sources/python_config.py"
        $sysconfigDump = New-Item -Path $this.ArtifactLocation -Name "sysconfig.txt" -ItemType File

        Write-Debug "Invoke $pythonBinaryPath"
        & $pythonBinaryPath $testSourcePath | Out-File -FilePath $sysconfigDump
    }

    [void] CreateInstallationScript() {
        $installationScriptPath = "../installers/nix_setup_template.sh"
        Copy-Item -Path $installationScriptPath -Destination "$($this.ArtifactLocation)/setup.sh"
    }

    [void] Make() {
        Write-Debug "make Python $($this.Version)-$($this.Architecture) $($this.Platform)-$($this.PlatformVersion)"
        make | Tee-Object -FilePath $this.BuildOutputLocation
        make install
    }

    [void] Build() {
        Write-Host "Prepare Python Hostedtoolcache location..."
        $this.PreparePythonToolcacheLocation()

        Write-Host "Download Python $($this.Version)[$($this.Architecture)] sources..."
        $sourcesLocation = $this.Download()

        Push-Location -Path $sourcesLocation
            Write-Host "Configure for $($this.Platform)-$($this.PlatformVersion)..."
            $this.Configure()

            Write-Host "Make for $($this.Platform)-$($this.PlatformVersion)..."
            $this.Make()
        Pop-Location

        Write-Host "Create sysconfig file..."
        $this.GetSysconfigDump()

        Write-Host "Search for missing modules..."
        $this.GetMissingModules()

        Write-Host "Archive generated aritfact..."
        $this.ArchiveArtifact()

        Write-Host "Create installation script..."
        $this.CreateInstallationScript()
    }
}
