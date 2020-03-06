Import-Module "../../helpers/common-helpers.psm1" -DisableNameChecking -Force
Import-Module "../../helpers/nix-helpers.psm1" -DisableNameChecking -Force
Import-Module "../../helpers/win-helpers.psm1" -DisableNameChecking -Force

$Version = "3.8.1"
$Platform = "macos-1013"
$Architecture = "x64"

$Builder = Get-PythonBuilder -Version $Version -Platform $Platform -Architecture $Architecture
$Builder.Build()
