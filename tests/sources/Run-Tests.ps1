Param (
    [Version] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Version,
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Platform,
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $ToolsDirectory
)

function InvokePythonCode {
    Param (
      [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
      $Command
    )
  
    $null = Invoke-Expression -Command $Command
    return $LASTEXITCODE
}

Describe "Python toolcache tests" {

    It "Python version" {
        & python --version
        & which python
        $whichPython = & which python
        $expectedPath = "$ToolsDirectory/Python"
        if ($Platform -eq 'windows') {
            $expectedPath = $expectedPath.Replace("C:/", "/c/")
        }
        $whichPython.startsWith($expectedPath) | Should -BeTrue
    }

    It "Run sample code" {
        InvokePythonCode -Command "python ./main.py" | Should Be 0
    }

    It "Validate modules"  {
        if (($Platform -eq 'ubuntu-1604') -or ($Platform -eq 'ubuntu-1804')) {
            InvokePythonCode -Command "python ./python_modules.py" | Should Be 0
        }
    }

    It "Check Tkinter" {
        if ($Platform -notmatch "windows") {
            InvokePythonCode -Command "python ./check_tkinter.py" | Should Be 0
        }
    }

    It "Validate Pyinstaller" {
        # Pyinstaller 3.5 does not support Python 3.8.0. Check issue https://github.com/pyinstaller/pyinstaller/issues/4311
        if ($Version -lt "3.8.0") {
            Invoke-Expression "pip install pyinstaller"
            InvokePythonCode -Command "pyinstaller --onefile ./main.py" | Should Be 0
            Invoke-Expression "./dist/main" | Should Be 0
        }
    }
    
}