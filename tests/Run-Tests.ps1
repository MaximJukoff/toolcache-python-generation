param (
    [Version] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Version,
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Platform,
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $ToolsDirectory
)

Install-Module Pester -Force -Scope CurrentUser

Set-Location 'tests/sources'
Import-Module Pester
Invoke-Pester -Script @{Path='./Python.Tests.ps1'; Parameters=@{Version=$Version; Platform=$Platform; ToolsDirectory=$ToolsDirectory}} -OutputFile 'test_results.xml' -OutputFormat NUnitXml
