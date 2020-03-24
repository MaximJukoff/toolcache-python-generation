Function New-SetupFile {
    param(
        [String]$ShPath,
        [String]$TemplatePath,
        [Version]$Version,
        [String]$ToolCachePath
    )

    $majorVersion = $Version.Major
    $minorVersion = $Version.Minor
    $buildVersion = $Version.Build
    
    $templateSetupSh = Get-Content -Path $TemplatePath -Raw
    $setupSh = $TemplateSetupSh -f $majorVersion, $minorVersion, $buildVersion, $ToolCachePath
    
    $setupSh | Out-File -FilePath $ShPath -Encoding utf8
}

Function Archive-Zip {
    param(
        [String]$PathToArchive,
        [String]$ToolZipFile
    )

    Push-Location -Path $PathToArchive
    zip -q -r $ToolZipFile * | Out-Null
    Pop-Location
}

Function Download-Source {
    param(
        [Uri]$Uri,
        [String]$OutFile
    )

    Write-Debug "Download source from $Uri to $OutFile"
    try {
        (New-Object System.Net.WebClient).DownloadFile($Uri, $OutFile)
    } catch {
        "$_"
        break
    }    
}

Function Unpack-TarArchive {
    [CmdletBinding()]
    param(
        [String]$OutFile,
        [String]$ExpandArchivePath = $env:BUILD_STAGINGDIRECTORY,
        [String]$TarCommands = "xvzf"
    )

    Write-Debug "Unpack $OutFile to $ExpandArchivePath"
    tar -C $ExpandArchivePath -$TarCommands $OutFile
}

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
