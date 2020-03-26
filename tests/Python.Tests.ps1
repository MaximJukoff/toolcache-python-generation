param (
    [Version] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Version,
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Platform
)

Import-Module (Join-Path $PSScriptRoot "../helpers/pester-extensions.psm1")
Import-Module (Join-Path $PSScriptRoot "../helpers/common-helpers.psm1")

function Get-CommandExitCode {
    Param (
      [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
      $Command
    )
  
    $null = Invoke-Expression -Command $Command
    return $LASTEXITCODE
}

Describe "Tests" {
    It "Python version" {
        "python --version" | Should -ReturnZeroExitCode
        $pythonLocation = (Get-Command "python").Path
        $pythonLocation | Should -Not -BeNullOrEmpty
        $expectedPath = Join-Path -Path $env:AGENT_TOOLSDIRECTORY -ChildPath "Python"
        $pythonLocation.startsWith($expectedPath) | Should -BeTrue
    }

    It "Run simple code" {
        "python ./simple_test.py" | Should -ReturnZeroExitCode
    }

    if (IsNixPlatform $Platform) {
        It "Check if all python modules are installed"  {
            $ArtifactLocation = $env:BUILD_BINARIESDIRECTORY
            $buildOutputLocation = Join-Path $ArtifactLocation "missing_modules.txt"
            $buildOutPutContent = Get-Content $buildOutputLocation
            $buildOutPutContent | Should Be $null 
            "python ./python_modules.py" | Should -ReturnZeroExitCode
        }

        It "Check python lib" {
            Get-CommandExitCode -Command "python ./python_config_test.py" | Should -ReturnZeroExitCode
        }

        It "Check Tkinter module is available" {
            Get-CommandExitCode -Command "python ./check_tkinter.py" | Should -ReturnZeroExitCode
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