function Execute-Command {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
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

function Download-File {
    param(
        [Parameter(Mandatory=$true)]
        [Uri]$Uri,
        [Parameter(Mandatory=$true)]
        [String]$OutputFolder
    )

    $targetFilename = [IO.Path]::GetFileName($Uri)
    $targetFilepath = Join-Path $OutputFolder $targetFilename

    Write-Debug "Download source from $Uri to $OutFile"
    try {
        (New-Object System.Net.WebClient).DownloadFile($Uri, $targetFilepath)
        return $targetFilepath
    } catch {
        "$_"
        break
    }    
}

function New-ToolStructureDump {
    param(
        [Parameter(Mandatory=$true)]
        [String]$ToolPath,
        [Parameter(Mandatory=$true)]
        [String]$OutputFolder
    )

    $outputFile = Join-Path $OutputFolder "tools_structure.txt"

    $folderContent = Get-ChildItem -Path $ToolPath -Recurse | Sort-Object | Select-Object -Property FullName, Length
    $folderContent | ForEach-Object {
        $relativePath = $_.FullName.Replace($ToolPath, "");
        return "${relativePath}"
    } | Out-File -FilePath $outputFile
}

function IsNixPlatform {
    param(
        [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]
        [String]$Platform
    )

    return ($Platform -match "macos") -or ($Platform -match "ubuntu")
}