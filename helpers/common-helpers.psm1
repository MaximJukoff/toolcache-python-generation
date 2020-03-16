function New-ToolStructureDump {
    param(
        [String]$ToolPath,
        [String]$OutputFolder
    )

    $outputFile = Join-Path $OutputFolder "tools_structure.txt"

    $folderContent = Get-ChildItem -Path $ToolPath -Recurse | Sort-Object | Select-Object -Property FullName, Length
    $folderContent | ForEach-Object {
        $relativePath = $_.FullName.Replace($ToolPath, "");
        $fileSize = $_.Length
        return "${relativePath} : ${fileSize} bytes"
    } | Out-File -FilePath $outputFile
}

function Get-CommandExitCode {
    Param (
      [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
      $Command
    )
  
    $null = Invoke-Expression -Command $Command
    return $LASTEXITCODE
}

function IsNixPlatform {
    param(
        [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
        $Platform
    )

    return ($Platform -match "macos") -or ($Platform -match "ubuntu")
}