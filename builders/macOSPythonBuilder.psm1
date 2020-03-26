using module "./builders/NixPythonBuilder.psm1"

class macOSPythonBuilder : NixPythonBuilder {
    macOSPythonBuilder(
        [string] $platform,
        [version] $version
    ) : Base($platform, $version) {
        
    }

    [void] Configure() {
        $pythonBinariesLocation = $this.GetFullPythonToolcacheLocation()

        Write-Host "Prepare environment..."
        $this.PrepareEnvironment()

        $configureString = "./configure --prefix=$pythonBinariesLocation --enable-optimizations --enable-shared"

        ### OS X 10.11, Apple no longer provides header files for the deprecated system version of OpenSSL.
        ### Solution is to install these libraries from a third-party package manager,
        ### and then add the appropriate paths for the header and library files to configure command.
        ### Link to documentation (https://cpython-devguide.readthedocs.io/setup/#build-dependencies)
        if ($this.Version -lt "3.7.0") {
            $env:CFLAGS="-I$(brew --prefix openssl)/include"
            $env:LDFLAGS="-L$(brew --prefix openssl)/lib"
        } else {
            $configureString += " --with-openssl=/usr/local/opt/openssl"
        }

        Execute-Command -Command $configureString
    }

    [void] PrepareEnvironment() {
        ### reinstall header files to Avoid issue with X11 headers on Mojave
        $pkgName = "/Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg"
        Execute-Command -Command "sudo installer -pkg $pkgName -target /"
    }
}
