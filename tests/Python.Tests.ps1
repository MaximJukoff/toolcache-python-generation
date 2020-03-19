param (
    [Version] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Version,
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Platform,
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $ToolsDirectory
)

Import-Module "../helpers/common-helpers.psm1"

Describe "Python toolcache tests" {

    It "Python version" {
        Get-CommandExitCode "python --version" | Should -Be 0
        $pythonLocation = (Get-Command "python").Path
        $pythonLocation | Should -Not -BeNullOrEmpty
        $expectedPath = Join-Path -Path $ToolsDirectory -ChildPath "Python"
        $pythonLocation.startsWith($expectedPath) | Should -BeTrue
    }

    It "Run simple code" {
        Get-CommandExitCode -Command "python ./simple_test.py" | Should -Be 0
    }

    if (IsNixPlatform $Platform) {
        It "Check if all the python modules are installed"  {
            Get-CommandExitCode -Command "python ./python_modules.py" | Should -Be 0
        }

        It "Check Tkinter" {
            Get-CommandExitCode -Command "python ./check_tkinter.py" | Should -Be 0
        }

        It "Check if shared libraries was linked correctly" {
            Get-CommandExitCode "bash ./psutil_install_test.sh" | Should -Be 0
        }
    }

    # Pyinstaller 3.5 does not support Python 3.8.0. Check issue https://github.com/pyinstaller/pyinstaller/issues/4311
    if ($Version -lt "3.8.0") {
        It "Validate Pyinstaller" {
            Get-CommandExitCode "pip install pyinstaller" | Should -Be 0
            Get-CommandExitCode -Command "pyinstaller --onefile ./simple_test.py" | Should -Be 0
            Get-CommandExitCode "./dist/simple_test" | Should -Be 0
        }
    }
}