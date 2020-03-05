Param (
    [Version] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Version,
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Platform,
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Architecture,
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $SourcesDirectory
)

function InvokePythonCode {
  Param (
    [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
    $Command
  )

  Invoke-Expression -Command $Command

  if ($LASTEXITCODE -eq 0) {
    Write-Output "$Command ran successfully"
  } else {
    Write-Output "$Command failed"
    exit $LASTEXITCODE
  }
}

$Major = $Version.Major
$Minor = $Version.Minor

if ($Architecture -eq 'x86') {
  $Bit = "-32"
} else {
  $Bit = ""
}

Set-Location "$SourcesDirectory/python/tests/sources"
InvokePythonCode -Command "python ./main.py"

if ($Platform -eq 'windows') {
  py "-$Major.$Minor$Bit" -c "from sys import version_info;import struct;print('py {}.{}.{}-{}bit'.format(version_info.major, version_info.minor, version_info.micro, 8*struct.calcsize('P')))"
}

if (($Platform -eq 'ubuntu-1604') -or ($Platform -eq 'ubuntu-1804'))
{
  # remove apt install -y tk in next image rollout
  sudo apt install -y tk

  InvokePythonCode -Command "python ./python_modules.py"

  # Pyinstaller 3.5 does not support Python 3.8.0. Check issue https://github.com/pyinstaller/pyinstaller/issues/4311
  if ($Version -lt "3.8.0") {
    pip install pyinstaller
    InvokePythonCode -Command "pyinstaller --onefile ./main.py"
    ./dist/main
  }
}

if ($Platform -notmatch "windows") {
  InvokePythonCode -Command "python ./check_tkinter.py"
}