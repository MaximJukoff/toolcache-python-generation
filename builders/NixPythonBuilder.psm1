using module "./builders/PythonBuilder.psm1"

class NixPythonBuilder : PythonBuilder {
    # Properties
    [string] $Platform
    [string] $PlatformVersion
    [string] $InstallationTemplateName
    [string] $InstallationScriptName
    [string] $PythonConfigScriptLocation
    [string] $OutputArtifactName

    NixPythonBuilder(
        [string] $platform,
        [version] $version
    ) : Base($version, "x64") {
        $this.Platform = $platform.Split("-")[0]
        $this.PlatformVersion = $platform.Split("-")[1]

        $this.InstallationTemplateName = "nix_setup_template.sh"
        $this.InstallationScriptName = "setup.sh"
        $this.PythonConfigScriptLocation = Join-Path -Path $PSScriptRoot -ChildPath "../tests/python_config.py"

        $this.OutputArtifactName = "tool.zip"
    }

    [uri] GetSourceUri() {
        $base = $this.GetBaseUri()

        return "${base}/$($this.Version)/Python-$($this.Version).tgz"
    }

    [string] GetPythonBinary() {
        if ($this.Version.Major -eq 2) { $pythonBinary = "python" } else { $pythonBinary = "python3" }

        return $pythonBinary
    }

    [string] Download() {
        $sourceUri = $this.GetSourceUri()
        Write-Host "Sources URI: $sourceUri"

        $archiveFilepath = Download-File -Uri $sourceUri -OutputFolder $this.ArtifactLocation
        Unpack-TarArchive -ArchivePath $archiveFilepath -OutputDirectory $this.TempFolderLocation
        $expandedSourceLocation = Join-Path -Path $this.TempFolderLocation -ChildPath "Python-$($this.Version)"
        Write-Debug "Done; Sources location: $expandedSourceLocation"

        return $expandedSourceLocation
    }

    [void] ArchiveArtifact([string] $pythonToolLocation) {
        $artifact = Join-Path -Path $this.ArtifactLocation -ChildPath $this.OutputArtifactName
        Pack-Zip -PathToArchive $pythonToolLocation -ToolZipFile $artifact 
        Write-Debug "Done; Artifact location: $artifact"
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
        Write-Debug "Done; Modules record location: $missingModulesRecordsLocation"
    }

    [void] GetSysconfigDump() {
        $pythonBinary = $this.GetPythonBinary()
        $pythonBinaryPath = Join-Path -Path $this.GetFullPythonToolcacheLocation() -ChildPath "bin/$pythonBinary"
        $testSourcePath = $this.PythonConfigScriptLocation
        $sysconfigDump = New-Item -Path $this.ArtifactLocation -Name "sysconfig.txt" -ItemType File

        Write-Debug "Invoke $pythonBinaryPath"
        & $pythonBinaryPath $testSourcePath | Out-File -FilePath $sysconfigDump

        Write-Debug "Done; Sysconfig dump location: $sysconfigDump"
    }

    [void] CreateInstallationScript() {
        $installationScriptPath = Join-Path -Path $this.ArtifactLocation -ChildPath $this.InstallationScriptName
        $templateLocation = Join-Path -Path $this.InstallationTemplatesLocation -ChildPath $this.InstallationTemplateName

        $majorVersion = $this.Version.Major
        $minorVersion = $this.Version.Minor
        $buildVersion = $this.Version.Build

        $templateSetupSh = Get-Content -Path $templateLocation -Raw
        $setupSh = $templateSetupSh -f $majorVersion, $minorVersion, $buildVersion
        $setupSh | Out-File -FilePath $installationScriptPath -Encoding utf8
        Write-Debug "Done; Installation script location: $installationScriptPath"
    }

    [string] Make() {
        Write-Debug "make Python $($this.Version)-$($this.Architecture) $($this.Platform)-$($this.PlatformVersion)"
        $buildOutputLocation = New-Item -Path $this.ArtifactLocation -Name "build_output.txt" -ItemType File
        Write-Host "-----debug-----"
        Get-ChildItem
        Write-Host "-----debug-----"
        Execute-Command -Command "make 2>&1 | tee $buildOutputLocation" -ErrorAction Continue
        Write-Host "-----debug---after---make-----"
        Get-ChildItem
        Write-Host "-----debug-----"

        Execute-Command -Command "make install" -ErrorAction Continue
        
        Write-Debug "Done; Make log location: $buildOutputLocation"

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
        $buildOutputLocation = $this.Make()
        Pop-Location

        New-ToolStructureDump -ToolPath $this.GetFullPythonToolcacheLocation() -OutputFolder $this.ArtifactLocation

        Write-Host "Create sysconfig file..."
        $this.GetSysconfigDump()

        Write-Host "Search for missing modules..."
        $this.GetMissingModules($buildOutputLocation)

        Write-Host "Archive generated artifact..."
        $this.ArchiveArtifact($this.GetFullPythonToolcacheLocation())

        Write-Host "Create installation script..."
        $this.CreateInstallationScript()
    }
}
