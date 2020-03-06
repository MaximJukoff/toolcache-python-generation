class NixPythonBuilder : PythonBuilder {
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
        $_base = $this.GetBaseUri()
        $_version = $this.Version

        return "${_base}/${_version}/Python-${_version}.tgz"
    }

    [string] Download() {
        $_sourceUri = $this.GetSourceUri()
        $_tempFolderLocation = $this.TempFolderLocation
        $_artifactLocation = $this.ArtifactLocation
        $_pythonSourceLocation = Join-Path -Path $_artifactLocation -ChildPath "Python-$($this.Version).tgz"

        Write-Host "Sources URI: $_sourceUri"
        Download-Source -Uri $_sourceUri -OutFile $_pythonSourceLocation -ExpandArchivePath $_tempFolderLocation
        $expandedSourceLocation = Join-Path -Path $_tempFolderLocation -ChildPath "Python-$($this.Version)"

        return $expandedSourceLocation
    }

    [void] ArchiveArtifact() {
        Write-Debug "ArchiveArtifact()"
        $artifact = Join-Path -Path $this.ArtifactLocation -ChildPath $this.ArtifactName
        Archive-ToolZip -PathToArchive $this.GetPythonToolcacheLocation() -ToolZipFile $artifact 
    }

    [void] GetMissingModules() {
        Write-Debug "GetMissingModules()"

        $SearchStringStart = "The necessary bits to build these optional modules were not found:"
        $SearchStringEnd = "To find the necessary bits, look in setup.py"
        $Pattern = "$SearchStringStart(.*?)$SearchStringEnd"
    
        $RecordsFile = $this.ArtifactLocation + "/missing_modules.txt"
        $BuildOutputFile = $this.ArtifactLocation + "/build_output.txt"
        $BuildContent = Get-Content -Path $BuildOutputFile
        New-Item $RecordsFile
        $SplitBuiltOutput = $BuildContent -split "\n";
    
        ### Search for missing modules that are displayed between the search strings
        $RegexMatch = [regex]::match($SplitBuiltOutput, $Pattern)
        if ($RegexMatch.Success)
        {
            Add-Content $RecordsFile -Value $RegexMatch.Groups[1].Value
        }
    }

    [void] GetSysconfigDump() {
        Write-Debug "GetSysconfigDump()"
            
        $_pythonBinaryPath = Join-Path -Path $this.GetPythonToolcacheLocation() -ChildPath "bin/python"
        $_testSourcePath = "../../tests/sources/python_config.py"
        
        $sysconfigDump = New-Item -Path $this.ArtifactLocation -Name "sysconfig.txt" -ItemType File
        & $_pythonBinaryPath $_testSourcePath | Out-File -FilePath $sysconfigDump
    }

    [void] Make() {
        Write-Debug "make Python $($this.Version)-$($this.Architecture) $($this.Platform)-$($this.PlatformVersion)"
        $outputFile = Join-Path -Path $this.ArtifactLocation -ChildPath "build_output.txt"
        make | Tee-Object -FilePath $outputFile
        make install
    }

    [void] Build() {
        Write-Host "Prepare Python Hostedtoolcache location..."
        $this.PreparePythonToolcacheLocation()

        Write-Host "Download Python $($this.Version)[$($this.Architecture)] sources..."
        $_sourcesLocation = $this.Download()

        Push-Location -Path $_sourcesLocation
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
    }
}