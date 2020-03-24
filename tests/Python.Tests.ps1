param (
    [Version] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Version,
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Platform,
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $ToolsDirectory
)

Import-Module (Join-Path $PSScriptRoot "../helpers/pester-assertions.psm1")
Import-Module (Join-Path $PSScriptRoot "../helpers/common-helpers.psm1")

Describe "Tests" {

    It "Python version" {
        "python --version" | Should -ReturnZeroExitCode
        $pythonLocation = (Get-Command "python").Path
        $pythonLocation | Should -Not -BeNullOrEmpty
        $expectedPath = Join-Path -Path $ToolsDirectory -ChildPath "Python"
        $pythonLocation.startsWith($expectedPath) | Should -BeTrue
    }

    It "Run simple code" {
        "python ./simple_test.py" | Should -ReturnZeroExitCode
    }

    if (IsNixPlatform $Platform) {
        It "Check if all python modules are installed"  {
            "python ./python_modules.py" | Should -ReturnZeroExitCode
        }

        It "Check Tkinter module is available" {
            "python ./check_tkinter.py" | Should -ReturnZeroExitCode
        }

        It "Check if shared libraries are linked correctly" {
            "bash ./psutil_install_test.sh" | Should -ReturnZeroExitCode
        }
    }

    # Pyinstaller 3.5 does not support Python 3.8.0. Check issue https://github.com/pyinstaller/pyinstaller/issues/4311
    if ($Version -lt "3.8.0") {
        It "Validate Pyinstaller" {
            "pip install pyinstaller" | Should -ReturnZeroExitCode
            "pyinstaller --onefile ./simple_test.py" | Should -ReturnZeroExitCode
            "./dist/simple_test" | Should -ReturnZeroExitCode
        }
    }
}