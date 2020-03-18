$Architecture = "{{__ARCHITECTURE__}}"
$Version = "{{__VERSION__}}"
$PythonExecName = "{{__PYTHON_EXEC_NAME__}}"

function Get-ArchitectureFilter {
    if ($Architecture -eq 'x86') {
      "32-bit"
    } else {
      "64-bit"
    }
}

function Get-PythonFilter {
    param(
        [Parameter (Mandatory = $true)]
        [String]$ArchFilter
    )

    ### Python 2.7 have no architecture postfix
    if ($IsMSI -and $Architecture -eq "x86") {
      "(Name like '%Python%%$MajorVersion.$MinorVersion%') and (not (Name like '%64-bit%'))"
    } else {
      "Name like '%Python%%$MajorVersion.$MinorVersion%%$ArchFilter%'"
    }
}

function Uninstall-Python {
    $ArchFilter = Get-ArchitectureFilter
    Write-Host "Check for installed Python$MajorVersion.$MinorVersion $ArchFilter WMI..."
    $PythonFilter = Get-PythonFilter -ArchFilter $ArchFilter
    Get-WmiObject Win32_Product -Filter $PythonFilter | Foreach-Object { $_.Uninstall() | Out-Null }
}

function Delete-PythonVersion {
    param(
        [Parameter (Mandatory = $true)]
        [String]$InstalledVersion
    )

    Write-Host "Delete Python$MajorVersion.$MinorVersion $Architecture"
    Remove-Item -Path "$($InstalledVersion.FullName)/$Architecture" -Recurse -Force
    Remove-Item -Path "$($InstalledVersion.FullName)/$Architecture.complete" -Force  
}

function Get-ExecParams {
    if ($IsMSI) {
        "TARGETDIR=$PythonArchPath ALLUSERS=1"
    } else {
        "DefaultAllUsersTargetDir=$PythonArchPath InstallAllUsers=1"
    }
}

$PythonToolcachePath = Join-Path -Path $env:AGENT_TOOLSDIRECTORY -ChildPath "Python"
$PythonVersionPath = Join-Path -Path $PythonToolcachePath -ChildPath $Version.ToString()
$PythonArchPath = Join-Path -Path $PythonVersionPath -ChildPath $Architecture

$IsMSI = $PythonExecName -match "msi"

$MajorVersion = $Version.Major
$MinorVersion = $Version.Minor

if (-Not (Test-Path $PythonToolcachePath)) {
    Write-Host "Create Python toolcache folder"
    New-Item -ItemType Directory -Path $PythonToolcachePath | Out-Null
}

Write-Host "Check if current Python version is installed..."
$InstalledVersion = Get-ChildItem -Path $PythonToolcachePath -Filter "$MajorVersion.$MinorVersion.*"

if ($InstalledVersion -ne $null) {
    Uninstall-Python

    if (Test-Path -Path "$($InstalledVersion.FullName)/$Architecture") {
      Write-Host "Python$MajorVersion.$MinorVersion/$Architecture was found in $PythonToolcachePath"
      Delete-PythonVersion -InstalledVersion $InstalledVersion
    }
} else {
    Write-Host "No Python$MajorVersion.$MinorVersion found"
}

Write-Host "Create Python $Version folder in $PythonToolcachePath"
New-Item -ItemType Directory -Path $PythonArchPath -Force | Out-Null

Write-Host "Copy Python binaries to $PythonArchPath"
Copy-Item -Path ./$PythonExecName -Destination $PythonArchPath | Out-Null

Write-Host "Install Python $Version in $PythonToolcachePath..."
$ExecParams = Get-ExecParams

cmd.exe /c "cd $PythonArchPath && call $PythonExecName $ExecParams /quiet"
if ($LASTEXITCODE -ne 0) {
    Throw "Error happened during Python installation"
}

cmd.exe /c "cd $PythonArchPath && python.exe -m ensurepip && python.exe -m pip install --upgrade pip"

Write-Host "Create complete file"
New-Item -ItemType File -Path $PythonVersionPath -Name "$Architecture.complete" | Out-Null
