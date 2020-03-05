function Get-PythonUri {
    param(
        [String]$Platform,
        [Version]$Version,
        [String]$Architecture
    )

    if ($Platform -eq "windows") {
        # After Python version 3.5.0 msi packages are replaced by exe file
        if ($Version -ge [Version]"3.5") {
            # Construct hash-table with appropriate URLs built for each possible architecture and
            # return one that are meets specified `$Architecture`
            return @{
                "x64" = "https://www.python.org/ftp/python/$Version/python-$Version-amd64.exe";
                "x86" = "https://www.python.org/ftp/python/$Version/python-$Version.exe"
            }[$Architecture]
        }
        elseif ($Version -lt [Version]"3.5" -and $Version -ge [version]"2.5") {
            return @{
                "x64" = "https://www.python.org/ftp/python/$Version/python-$Version.amd64.msi";
                "x86" = "https://www.python.org/ftp/python/$Version/python-$Version.msi"
            }[$Architecture]
        }
    } else {
        return "https://www.python.org/ftp/python/$Version/Python-$Version.tgz"
    }
}