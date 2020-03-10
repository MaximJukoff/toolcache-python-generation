using module "./builders/PythonBuilder.psm1"

class NixPythonBuilder : PythonBuilder {
    # Properties
    [string] $Platform
    [string] $PlatformVersion

    NixPythonBuilder(
        [string] $platform,
        [version] $version
    ) : Base($version, "x64") {
        $this.Platform = $platform.Split("-")[0]
        $this.PlatformVersion = $platform.Split("-")[1]
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
        $pythonSourceLocation = Join-Path -Path $this.ArtifactLocation -ChildPath "Python-$($this.Version).tgz"

        Write-Host "Sources URI: $_sourceUri"
        Download-Source -Uri $_sourceUri -OutFile $pythonSourceLocation -ExpandArchivePath $this.TempFolderLocation
        $expandedSourceLocation = Join-Path -Path $this.TempFolderLocation -ChildPath "Python-$($this.Version)"

        return $expandedSourceLocation
    }

    [void] ArchiveArtifact([string] $pythonToolLocation) {
        $artifact = Join-Path -Path $this.ArtifactLocation -ChildPath $this.ArtifactName
        Archive-ToolZip -PathToArchive $pythonToolLocation -ToolZipFile $artifact 
    }

    [void] GetMissingModules([string] $buildOutputLocation) {
        $searchStringStart = "The necessary bits to build these optional modules were not found:"
        $searchStringEnd = "To find the necessary bits, look in setup.py"
        $pattern = "$searchStringStart(.*?)$searchStringEnd"
    
        $buildContent = Get-Content -Path $buildOutputLocation
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
        $installationScriptPath = "./installers/nix_setup_template.sh"
        Copy-Item -Path $installationScriptPath -Destination "$($this.ArtifactLocation)/setup.sh"
    }

    [string] Make() {
        Write-Debug "make Python $($this.Version)-$($this.Architecture) $($this.Platform)-$($this.PlatformVersion)"

        $buildOutputLocation = Join-Path -Path $this.ArtifactLocation -ChildPath "build_output.txt"

        make | Tee-Object -FilePath $buildOutputLocation
        make install

        return $buildOutputLocation
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
        $buildOutput = $this.Make()
        Pop-Location

        Write-Host "Create sysconfig file..."
        $this.GetSysconfigDump()

        Write-Host "Search for missing modules..."
        $this.GetMissingModules($buildOutput)

        Write-Host "Archive generated aritfact..."
        $this.ArchiveArtifact($this.GetPythonToolcacheLocation())

        Write-Host "Create installation script..."
        $this.CreateInstallationScript()
    }
}
