Function Execute-Command {
    [CmdletBinding()]
    param(
        [string] $Command
    )

    Write-Debug "Execute $Command"

    try {
        Invoke-Expression $Command | ForEach-Object { Write-Host $_ }
    }
    catch {
        Write-Host "Error happened during command execution: $Command"
        Write-Host "##vso[task.logissue type=error;] $_"
    }
}


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

function IsNixPlatform {
    param(
        [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
        $Platform
    )

    return ($Platform -match "macos") -or ($Platform -match "ubuntu")
}