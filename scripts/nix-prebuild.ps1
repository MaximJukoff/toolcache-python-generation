param(
    [Parameter (Mandatory=$true)] [ValidateNotNullOrEmpty()]
    [String] $Version,
    [Parameter (Mandatory=$true)] [ValidateNotNullOrEmpty()]
    [String] $DestinationPath,
    [Parameter (Mandatory=$true)] [ValidateNotNullOrEmpty()]
    [String] $Platform,
    [Parameter (Mandatory=$true)] [ValidateSet("x64", "x86")]
    [String] $Architecture = "x64"
)

Import-Module "${env:BUILD_SOURCESDIRECTORY}/common/helpers/common-helpers.psm1" -DisableNameChecking
Import-Module "${env:BUILD_SOURCESDIRECTORY}/common/helpers/nix-helpers.psm1" -DisableNameChecking
Import-Module "${env:BUILD_SOURCESDIRECTORY}/common/helpers/npm-helpers.psm1" -DisableNameChecking
Import-Module "${env:BUILD_SOURCESDIRECTORY}\python\scripts\Python.psm1" -DisableNameChecking

Function Build-Python {
    param(
        [System.String]$SrcPath,
        [System.String]$ToPath,
        [System.String]$Platform,
        [System.String]$Architecture,
        [System.Version]$Version
    )
    Push-Location -Path $srcPath

    if ($Platform -eq "macos-1013")
    {
        ### OS X 10.11, Apple no longer provides header files for the deprecated system version of OpenSSL.
        ### Solution is to install these libraries from a third-party package manager,
        ### and then add the appropriate paths for the header and library files to configure command.
        ### Link to documentation (https://cpython-devguide.readthedocs.io/setup/#build-dependencies)
        if ($Version -lt "3.7.0")
        {
            $env:CFLAGS="-I$(brew --prefix openssl)/include $CFLAGS"
            $env:LDFLAGS="-L$(brew --prefix openssl)/lib $LDFLAGS"
            ./configure --prefix=$toPath --enable-optimizations --enable-shared
        }
        else
        {
            ./configure --prefix=$toPath --with-openssl=/usr/local/opt/openssl --enable-optimizations --enable-shared
        }
    }

    if ($Platform.StartsWith("ubuntu"))
    {
        ### To build Python with SO we must pass full path to lib folder to the linker
        $env:LDFLAGS="-Wl,--rpath=$env:AGENT_TOOLSDIRECTORY/Python/$Version/$Architecture/lib"

        ### Python versions from 3.0 to 3.5.2 are not compatible with OpenSSL 1.1.0. We have to downgrade it to 1.0.2.
        ### CPython optimizations also not supported.


        if (($Version -gt "3.0.0"))
        {
            sudo apt-get install -y --allow-downgrades `
            python3-tk `
            tk-dev
        }
        else 
        {
            sudo apt install -y `
            python-tk `
            tk-dev
        }

        if (($Version -lt "3.5.3") -and ($Version -gt "3.0.0"))
        { 
            if ($Platform -eq "ubuntu-1804")
            {
                ### Ubuntu 18.04 comes with OpenSSL 1.0.2 by default and there is no easy way to downgrade
                ### Python 3.4 has also reached EOL so it is not being supported on Ubuntu 18.04
                return 1;
            }

            sudo apt-get install -y --allow-downgrades `
            build-essential `
            libbz2-dev `
            libdb-dev `
            libffi-dev `
            libgdbm-dev `
            liblzma-dev `
            libncursesw5-dev `
            libreadline-dev `
            libsqlite3-dev `
            libssl-dev=1.0.2g-1ubuntu4.15 `
            zlib1g-dev

            ./configure --prefix=$toPath --enable-shared
        }
        else
        {
            sudo apt install -y `
            make `
            build-essential `
            libssl-dev `
            zlib1g-dev `
            libbz2-dev `
            libsqlite3-dev `
            libncursesw5-dev `
            libreadline-dev `
            libgdbm-dev

            if ($Platform -eq "ubuntu-1804")
            {
                ### On Ubuntu-1804, libgdbm-compat-dev has older modules that are no longer in libgdbm-dev
                sudo apt install -y libgdbm-compat-dev
            }

            ./configure --prefix=$toPath --enable-optimizations --enable-shared
        }
    }

    $BuildOutputFile = "$env:AGENT_BUILDDIRECTORY/build_output.txt"
    make | Tee-Object -FilePath $BuildOutputFile
    make install
    Pop-Location
}

Function Record-MissingModules {
    param(
        [String]$PathToArchive
    )

    $SearchStringStart = "The necessary bits to build these optional modules were not found:"
    $SearchStringEnd = "To find the necessary bits, look in setup.py"
    $Pattern = "$SearchStringStart(.*?)$SearchStringEnd"

    $RecordsFile = $PathToArchive + "/missing_modules.txt"
    $BuildOutputFile = "$env:AGENT_BUILDDIRECTORY/build_output.txt"
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

Function New-SysconfigFile {
    param(
        [String]$ToolPath,
        [String]$DestinationPath,
        [Version]$Version
    )

    if ($Version.Major -eq 2) {
        $PythonBinary = "python2"
    } else {
        $PythonBinary = "python3"
    }

    $PythonPath = Join-Path -Path $ToolPath -ChildPath "bin/$PythonBinary"
    $TestSourcePath = "$env:BUILD_SOURCESDIRECTORY/python/tests/sources/python_config.py"
    
    $sysconfigDump = New-Item -Path $DestinationPath -Name "Sysconfig.txt" -ItemType File
    & $PythonPath $TestSourcePath | Out-File -FilePath $sysconfigDump
}

Write-Host "Clear old toolcache folder"
$ToolsDirectory = $env:AGENT_TOOLSDIRECTORY
if (Test-Path "$ToolsDirectory/Python/$Version") {
    Remove-Item "$ToolsDirectory/Python/$Version" -Recurse -Force
}

# PATH
$pythonVerArchPath = $DestinationPath

Write-Host "Download sources"
$uri = Get-PythonUri -Platform $Platform -Version $Version -Architecture $Architecture
Write-Host "Download uri: $uri"
$expandArchivePath = $env:BUILD_STAGINGDIRECTORY
$pythonFile = Join-Path -Path $pythonVerArchPath -ChildPath "python-${Version}.tgz"
Download-Source -Uri $uri -OutFile $pythonFile -ExpandArchivePath $expandArchivePath

Write-Host "Build Python"
# Expand archive directory
$srcPath = Join-Path -Path $expandArchivePath -ChildPath "Python-${Version}"
# Installation directory
$toPath = Join-Path -Path $expandArchivePath -ChildPath Python
$toolInstallationPath = Join-Path -Path $env:AGENT_TOOLSDIRECTORY -ChildPath "Python/$Version/$Architecture"
Build-Python -SrcPath $srcPath -ToPath $toolInstallationPath -Platform $Platform -Architecture $Architecture -Version $Version

Write-Host "Create setup.sh file"
$Template = "${env:BUILD_SOURCESDIRECTORY}/python/tools/nix_setup_template.sh"
$ToolCachePath = "${ToolsDirectory}/Python"
New-SetupPackageFile `
    -ShPath $pythonVerArchPath `
    -TemplatePath $Template `
    -Version $Version `
    -ToolCachePath $ToolCachePath

# Log any modules that were not found during the build process
Write-Output "Search for missing modules"
Record-MissingModules -PathToArchive $pythonVerArchPath

# Copy compiled binaries to staging folder
$pythonToolZip = Join-Path -Path $pythonVerArchPath -ChildPath "tool.zip"
Archive-ToolZip -PathToArchive $toolInstallationPath -ToolZipFile $pythonToolZip 

# Artifact sources must be located in Python root due to compliance reasons
Move-Item -Path $pythonFile -Destination $pythonVerArchPath

# Create sysconfig file
New-SysconfigFile -DestinationPath $pythonVerArchPath -Version $Version -ToolPath $toolInstallationPath

Write-Host "Create package.json"
$PackageName = Get-PackageName -ToolName "python" -Platform $Platform -Architecture $Architecture
$InstallScript = "chmod +x ./setup.sh && ./setup.sh"
New-PackageJson `
    -PackageName $PackageName `
    -PackageVersion $Version `
    -PackagePath $pythonVerArchPath `
    -InstallScript $InstallScript `
    -TemplateName "python" `
    -Platform $Platform

Write-Host "Create README.md file"
New-Readme -OutputDirectory $pythonVerArchPath

Write-Host "Create tool structure dump"
New-ToolStructureDump -ToolPath $toolInstallationPath -OutputFolder $pythonVerArchPath
