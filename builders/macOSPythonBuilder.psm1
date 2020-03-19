using module "./builders/NixPythonBuilder.psm1"

class macOSPythonBuilder : NixPythonBuilder {
    macOSPythonBuilder(
        [string] $platform,
        [version] $version
    ) : Base($platform, $version) {
        
    }

    [void] Configure() {
        Write-Debug "Configure Python $($this.Version)-$($this.Architecture) macOS-$($this.PlatformVersion)"
        $pythonBinariesLocation = $this.GetFullPythonToolcacheLocation()

        $configureString = "./configure --prefix=$pythonBinariesLocation --enable-optimizations --enable-shared"

        ### OS X 10.11, Apple no longer provides header files for the deprecated system version of OpenSSL.
        ### Solution is to install these libraries from a third-party package manager,
        ### and then add the appropriate paths for the header and library files to configure command.
        ### Link to documentation (https://cpython-devguide.readthedocs.io/setup/#build-dependencies)
        if ($this.Version -lt "3.7.0") {
            Append-EnvironmentVariable -variableName "CFLAGS", -value "-I$(brew --prefix openssl)/include"
            Append-EnvironmentVariable -variableName "LDFLAGS", -value "-L$(brew --prefix openssl)/lib"

        } else {
            $configureString = $configureString, "--with-openssl=/usr/local/opt/openssl" -join " "
        }

        $this.ExecuteCommand($configureString)
    }
}
