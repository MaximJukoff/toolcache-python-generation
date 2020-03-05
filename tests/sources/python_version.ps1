Param (
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Platform,
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $ToolsDirectory
)

& python --version
& which python
$whichPython = & which python
$expectedPath = "$ToolsDirectory/Python"
if ($Platform -eq 'windows') {
  $expectedPath = $expectedPath.Replace("C:/", "/c/")
}
$isCorrectPath = $whichPython.startsWith($expectedPath)

if (-not $isCorrectPath) {
  Write-Host "Python version is not overridden"
  exit 1
}