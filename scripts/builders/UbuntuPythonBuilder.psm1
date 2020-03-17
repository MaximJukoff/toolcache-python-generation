class UbuntuPythonBuilder : NixPythonBuilder {
    UbuntuPythonBuilder(
        [string] $platform, 
        [version] $version
    ) : Base($Platform, $Version) {

    }

    [void] Configure() {
        Write-Debug "./Configure Python $($this.Version)-$($this.Architecture) Ubuntu-$($this.PlatformVersion)"
        $_pythonBinariesLocation = $this.GetPythonToolcacheLocation()
        
        $this.PrepareEnvironment()

        ### To build Python with SO we must pass full path to lib folder to the linker
        $this.SetConfigFlags($env:LDFLAGS,"-Wl,--rpath=$_pythonBinariesLocation/lib")

        ### CPython optimizations also not supported in Python versions lower than 3.5.3
        if (($this.Version -gt "3.0.0") -and ($this.Version -lt "3.5.3")) { 
            ./configure --prefix=$_pythonBinariesLocation --enable-shared
        } else {
            ./configure --prefix=$_pythonBinariesLocation --enable-optimizations --enable-shared
        }
    }

    [void] PrepareEnvironment() {
        Write-Debug "PrepareEnvironment()"
        ### Compile with tkinter support
        if ($this.Version -gt "3.0.0") {
            sudo apt-get install -y --allow-downgrades `
            python3-tk `
            tk-dev
        } else {
            sudo apt install -y `
            python-tk `
            tk-dev
        }

        if (($this.Version -gt "3.0.0") -and ($this.Version -lt "3.5.3")) {
            ### Ubuntu older that 16.04 comes with OpenSSL 1.0.2 by default and there is no easy way to downgrade it
            ### Python 3.4 has also reached EOL so it is not being supported on Ubuntu older that 16.04
            if ($this.PlatformVersion -eq "1604") {
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
            } else {
                exit 1
            }
        } else {
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

            if ($this.PlatformVersion -eq "1804") {
                sudo apt install -y libgdbm-compat-dev
            }
        }
    }
}