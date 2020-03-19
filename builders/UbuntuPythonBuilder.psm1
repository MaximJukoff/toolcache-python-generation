using module "./builders/NixPythonBuilder.psm1"

class UbuntuPythonBuilder : NixPythonBuilder {
    UbuntuPythonBuilder(
        [string] $platform, 
        [version] $version
    ) : Base($platform, $version) {
        
    }

    [void] Configure() {
        Write-Debug "Configure Python $($this.Version)-$($this.Architecture) Ubuntu-$($this.PlatformVersion)"
        $pythonBinariesLocation = $this.GetFullPythonToolcacheLocation()
        
        ### Prepare Ubuntu system environment by installing required packages
        Write-Host "Prepare environment..."
        $this.PrepareEnvironment()

        ### To build Python with SO we must pass full path to lib folder to the linker
        Append-EnvironmentVariable -variableName "LDFLAGS", -value "-Wl,--rpath=$pythonBinariesLocation/lib"

        $configureString = "./configure --prefix=$pythonBinariesLocation --enable-shared"
        ### CPython optimizations also not supported in Python versions lower than 3.5.3
        if (($this.Version -lt "3.0.0") -and ($this.Version -gt "3.5.3")) { 
            $configureString = $configureString, "--enable-optimizations" -join " "
        }
        $this.ExecuteCommand($configureString)
    }

    [void] PrepareEnvironment() {
        ### Compile with tkinter support
        if ($this.Version -gt "3.0.0") {
            $this.ExecuteCommand("sudo apt-get install -y --allow-downgrades python3-tk tk-dev")
        } else {
            $this.ExecuteCommand("sudo apt install -y python-tk tk-dev")
        }

        if (($this.Version -gt "3.0.0") -and ($this.Version -lt "3.5.3")) {
            ### Ubuntu older that 16.04 comes with OpenSSL 1.0.2 by default and there is no easy way to downgrade it
            ### Python 3.4 has also reached EOL so it is not being supported on Ubuntu older that 16.04
            if ($this.PlatformVersion -eq "1604") {
                @(
                    "build-essential",
                    "libbz2-dev",
                    "libdb-dev",
                    "libffi-dev",
                    "libgdbm-dev",
                    "liblzma-dev",
                    "libncursesw5-dev",
                    "libreadline-dev",
                    "libsqlite3-dev",
                    "libssl-dev=1.0.2g-1ubuntu4.15",
                    "zlib1g-dev"
                ) | ForEach-Object {
                    $this.ExecuteCommand("sudo apt-get install -y --allow-downgrades $_")
                }

            } else {
                Write-Host "Python 3.4 is not supported on Ubuntu older that 16.04"
                exit 1
            }
        } else {
            @(
                "make",
                "build-essential",
                "libssl-dev",
                "zlib1g-dev",
                "libbz2-dev",
                "libsqlite3-dev",
                "libncursesw5-dev",
                "libreadline-dev",
                "libgdbm-dev"
            ) | ForEach-Object {
                $this.ExecuteCommand("sudo apt install -y $_")
            }

            if ($this.PlatformVersion -ne "1604") {
                ### On Ubuntu-1804, libgdbm-compat-dev has older modules that are no longer in libgdbm-dev
                $this.ExecuteCommand("sudo apt install -y libgdbm-compat-dev")
            }
        }
    }
}
