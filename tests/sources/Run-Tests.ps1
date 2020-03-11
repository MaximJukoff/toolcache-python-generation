Param (
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Platform,
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $ToolsDirectory
)

Describe "Toolcache tests" {

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
}