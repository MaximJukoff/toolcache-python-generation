param (
    [Version] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Version,
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Platform,
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $ToolsDirectory
)

Import-Module "../../helpers/common-helpers.psm1" -DisableNameChecking

Describe "Python toolcache tests" {

    It "Python version" {
        Get-CommandExitCode "python --version" | Should -Be 0
        $pythonLocation = (Get-Command "python").Path
        $pythonLocation | Should -Not -BeNullOrEmpty
        $expectedPath = "$ToolsDirectory/Python"
        if ($Platform -eq 'windows') {
            $expectedPath = $expectedPath.Replace("/", "\")
        }
        $pythonLocation.startsWith($expectedPath) | Should -BeTrue
    }

    It "Run sample code" {
        Get-CommandExitCode -Command "python ./main.py" | Should -Be 0
    }

    It "Validate modules"  {
        if ($Platform -notmatch "windows") {
            Get-CommandExitCode -Command "python ./python_modules.py" | Should -Be 0
        }
    }

    It "Check Tkinter" {
        if ($Platform -notmatch "windows") {
            Get-CommandExitCode -Command "python ./check_tkinter.py" | Should -Be 0
        }
    }

    It "Validate Pyinstaller" {
        # Pyinstaller 3.5 does not support Python 3.8.0. Check issue https://github.com/pyinstaller/pyinstaller/issues/4311
        if ($Version -lt "3.8.0") {
            Get-CommandExitCode "pip install pyinstaller" | Should -Be 0
            Get-CommandExitCode -Command "pyinstaller --onefile ./main.py" | Should -Be 0
            Get-CommandExitCode "./dist/main" | Should -Be 0
        }
    }

    It "Pip psutil installation" {
        if ($Platform -notmatch "windows") {
            Get-CommandExitCode "bash ./psutil_install_test.sh" | Should -Be 0
        }
    }
}