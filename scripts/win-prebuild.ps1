Param (
    [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    [String] $Version,
    [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    [String] $DestinationPath,
    [Parameter (Mandatory = $true)] [ValidateSet("x64", "x86")]
    [String] $Architecture
)

Import-Module "${env:BUILD_SOURCESDIRECTORY}\common\helpers\common-helpers.psm1" -DisableNameChecking
Import-Module "${env:BUILD_SOURCESDIRECTORY}\common\helpers\win-helpers.psm1" -DisableNameChecking
Import-Module "${env:BUILD_SOURCESDIRECTORY}\common\helpers\npm-helpers.psm1" -DisableNameChecking
Import-Module "${env:BUILD_SOURCESDIRECTORY}\python\scripts\Python.psm1" -DisableNameChecking

# Artifact Python directory
$FullPathArtifact = $DestinationPath
New-Item -ItemType Directory $FullPathArtifact -Force | Out-Null

Write-Host "Download binaries"
$Uri = Get-PythonUri -Platform "windows" -Version $Version -Architecture $Architecture
Write-Host "Download uri: $Uri"
$BinPathFile = Download-File -Uri $Uri -BinPathFolder $FullPathArtifact

# Add Python Installation to setup file
$ExecName = $Uri.Split("/")[-1]

Write-Host "Create package.json file"
$PackageName = Get-PackageName -ToolName "python" -Platform "windows" -Architecture $Architecture
$InstallScript = "powershell ./install_to_tools_cache.ps1 ${Architecture} ${Version} ${ExecName}"
New-PackageJson `
    -PackageName $PackageName `
    -PackageVersion $Version `
    -PackagePath $FullPathArtifact `
    -InstallScript $InstallScript `
    -TemplateName "python"

Write-Host "Create README.md file"
New-Readme -OutputDirectory $FullPathArtifact

Write-Host "Create install_to_tools_cache.ps1 file"
$InstallScriptPath = Join-Path -Path $FullPathArtifact -ChildPath "install_to_tools_cache.ps1"
Copy-Item `
    -Path "$($env:BUILD_SOURCESDIRECTORY)\python\tools\win_setup_template.ps1" `
    -Destination $InstallScriptPath

Write-Host "Create tool structure dump"
New-ToolStructureDump -ToolPath $BinPathFile -OutputFolder $FullPathArtifact

