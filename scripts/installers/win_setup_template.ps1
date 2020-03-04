param(
    [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    [String]$Architecture,
    [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    [Version]$Version,
    [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    [String]$PythonExecName
)

$PythonToolcachePath = Join-Path -Path $env:AGENT_TOOLSDIRECTORY -ChildPath "Python"
$PythonVersionPath = Join-Path -Path $PythonToolcachePath -ChildPath $Version.ToString()
$PythonArchPath = Join-Path -Path $PythonVersionPath -ChildPath $Architecture

$MajorVersion = $Version.Major
$MinorVersion = $Version.Minor

$IsMSI = $PythonExecName -match "msi"

if (-Not (Test-Path $PythonToolcachePath)) {
    Write-Host "Create Python toolcache folder"
    New-Item -ItemType Directory -Path $env:AGENT_TOOLSDIRECTORY -Name "Python" | Out-Null
}

Write-Host "Check if current Python version is installed..."
$VersionIsInstalled = Get-ChildItem -Path $PythonToolcachePath -Filter "${MajorVersion}.${MinorVersion}.*"

if ($VersionIsInstalled) {

    if ($Architecture -eq 'x86') {
        $ArchFilter = "32-bit"
    } else {
        $ArchFilter = "64-bit"
    }

    Write-Host "Check for installed Python${MajorVersion}.${MinorVersion} ${ArchFilter} WMI..."
    
    ### Python 2.7 and 3.4 have no architecture postfix
    if ((($MinorVersion -eq 4) -or $IsMSI) -and $Architecture -eq "x86") {
        $filterPython = "(Name like '%Python%%$MajorVersion.$MinorVersion%') and (not (Name like '%64-bit%'))"
    } else {
        $filterPython = "Name like '%Python%%$MajorVersion.$MinorVersion%%$ArchFilter%'"
    }

    Get-WmiObject Win32_Product -Filter $filterPython | Foreach-Object {$_.Uninstall() | Out-Null }

    if (Test-Path -Path "$($VersionIsInstalled.FullName)/${Architecture}") {
        Write-Host "Python${MajorVersion}.${MinorVersion}/${Architecture} was found in ${PythonToolcachePath}"

        Remove-Item -Path "$($VersionIsInstalled.FullName)/${Architecture}" -Recurse -Force
        Remove-Item -Path "$($VersionIsInstalled.FullName)/${Architecture}.complete" -Force

        Write-Host "Python${MajorVersion}.${MinorVersion} deleted"
    }
} else {
    Write-Host "No Python${MajorVersion}.${MinorVersion}.* found"
}

Write-Host "Create Python ${Version} folder in ${PythonToolcachePath}"
New-Item -ItemType Directory -Path $PythonArchPath -Force | Out-Null

Write-Host "Copy Python binaries to ${PythonArchPath}"
Copy-Item -Path ./$PythonExecName -Destination $PythonArchPath | Out-Null

Write-Host "Install Python ${Version} in ${PythonToolcachePath}..."
if ($IsMSI) {
    $ExecParams = "TARGETDIR=$PythonArchPath ALLUSERS=1"
}
else {
    $ExecParams = "DefaultAllUsersTargetDir=$PythonArchPath InstallAllUsers=1"
}

cmd.exe /c "cd $PythonArchPath && call $PythonExecName $ExecParams /quiet"
if ($LASTEXITCODE -ne 0) {
    Throw "Error happened during Python installation"
}

cmd.exe /c "cd $PythonArchPath && python.exe -m ensurepip && python.exe -m pip install --upgrade pip"

Write-Host "Create complete file"
New-Item -ItemType File -Path $PythonVersionPath -Name "$Architecture.complete" | Out-Null
