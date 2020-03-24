Function Pack-Zip {
    param(
        [Parameter(Mandatory=$true)]
        [String]$PathToArchive,
        [Parameter(Mandatory=$true)]
        [String]$ToolZipFile
    )

    Write-Debug "Pack $PathToArchive to $ToolZipFile"
    Push-Location -Path $PathToArchive
    zip -q -r $ToolZipFile * | Out-Null
    Pop-Location
}

Function Unpack-TarArchive {
    param(
        [Parameter(Mandatory=$true)]
        [String]$ArchivePath,
        [Parameter(Mandatory=$true)]
        [String]$OutputDirectory
    )

    Write-Debug "Unpack $ArchivePath to $OutputDirectory"
    tar -C $OutputDirectory -xzf $ArchivePath

}