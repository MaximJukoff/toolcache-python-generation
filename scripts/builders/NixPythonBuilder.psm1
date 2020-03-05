Import-Module "./PythonBuilder.psm1" -Force -DisableNameChecking
Import-Module "../../helpers/nix-helpers.psm1" -DisableNameChecking

class NixPythonBuilder : PythonBuilder {
    [string] $Platform

    NixPythonBuilder(
        [version] $Version,
        [string] $Platform
    ) : base ($Version, "x64") {
        $this.Platform = $Platform  
    }

    ### Artifacts

    [uri] GetSourceUri() {
        $_base = $this.GetBaseUri()
        $_version = $this.GetVersion()

        $uri = "${_base}/${_version}/Python-${_version}.tgz"

        return $uri
    }

    [string] DownloadSources() {
        $_version = $this.GetVersion()
        $_sourceUri = $this.GetSourceUri()
        $_tempFolderLocation = $this.GetTempFolderLocation()
        $_artifactLocation = $this.GetArtifactLocation()

        $_pythonSourceLocation = Join-Path -Path $_artifactLocation -ChildPath "python-${_version}.tgz"

        Write-Host "Download Python ${_version} from ${_sourceUri}..."
        Download-Source -Uri $_sourceUri -OutFile $_pythonSourceLocation -ExpandArchivePath $_tempFolderLocation

        return Join-Path -Path $_tempFolderLocation -ChildPath "Python-${_version}"
    }

    ### Build

    [void] ConfigureMacos() {
        $_pythonToolcacheLocation = $this.GetPythonVersionArchitectureLocation()

        if ($this.GetVersion() -lt "3.7.0")
        {
            $this.SetConfigFlags($env:CFLAGS, "-I$(brew --prefix openssl)/include")
            $this.SetConfigFlags($env:LDLAGS, "-L$(brew --prefix openssl)/lib")
            ./configure --prefix=$_pythonToolcacheLocation --enable-optimizations --enable-shared
        }
        else
        {
            ./configure --prefix=$_pythonToolcacheLocation --with-openssl=/usr/local/opt/openssl --enable-optimizations --enable-shared
        }
    }

    [void] ConfigureUbuntu() {
        $_pythonToolcacheLocation = $this.GetPythonVersionArchitectureLocation()
        
        ### To build Python with SO we must pass full path to lib folder to the linker
        $this.SetConfigFlags($env:LDFLAGS, "-Wl,--rpath=${_pythonToolcacheLocation}/lib")

        ### Python versions from 3.0 to 3.5.2 are not compatible with OpenSSL 1.1.0. We have to downgrade it to 1.0.2.
        ### CPython optimizations also not supported.

        ### ADD PACKAGE MANAGMENT

        if (($this.GetVersion() -lt "3.5.3") -and ($this.GetVersion() -gt "3.0.0")) {
            ./configure --prefix=$_pythonToolcacheLocation --enable-shared
        } else {
            ./configure --prefix=$_pythonToolcacheLocation --enable-optimizations --enable-shared
        }
    }

    [void] Build() {
        Write-Host "Download sources..."
        $pythonSourcesPath = $this.DownloadSources()

        Push-Location -Path $pythonSourcesPath
            Write-Host "Configure..."
            if ($this.Platform -match "macos") {
                $this.ConfigureMacos()
            } elseif ($this.Platform -match "ubuntu") {
                $this.ConfigureUbuntu()
            }

            else {
                exit 1
            }

            Write-Host "Make..."
            $this.Make()
        Pop-Location
    }

    ### Additional
    [void] SetConfigFlags([string] $flags, [string] $value) {
        $flags = "${value} ${flags}"
    }

    [void] CreateSysconfigFile() {
        ### TODO
    }
}
