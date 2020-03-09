@{
    RootModule = "PythonBuilder.psm1"
    ScriptsToProcess = @(
        "NixPythonBuilder.psm1",
        "WinPythonBuilder.psm1",
        "UbuntuPythonBuilder.psm1",
        "macOSPythonBuilder.psm1"
    )

    FunctionsToExport = @(
        "Get-PythonBuilder"
    )
}