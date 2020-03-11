Param (
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

    Context "Ubuntu" {

        It "Validate modules" {
            InvokePythonCode -Command "python ./python_modules.py" | Should Be 0
        }
    }
}