param (
    [Parameter(Mandatory)] [string] $GitHubRepository,
    [Parameter(Mandatory)] [string] $GitHubAccessToken,
    [Parameter(Mandatory)] [string] $OutputFile
)

function Get-GitHubReleases {
    $encodedToken = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("'':${GitHubAccessToken}"))

    $requestParams = @{
        Method = "GET"
        ContentType = "application/json"
        Uri = "https://api.github.com/repos/${GitHubRepository}/releases"
        Headers = @{
            Authorization = "Basic ${encodedToken}"
        }
    }

    return Invoke-RestMethod @requestParams
}

function Build-AssetsList {
    param (
        [AllowEmptyCollection()]
        [Parameter(Mandatory)][array]$ReleaseAssets
    )

    return $ReleaseAssets | ForEach-Object {
        $parts = [IO.path]::GetFileNameWithoutExtension($_.name).Split("-")

        return [PSCustomObject]@{
            filename = $_.name
            arch = $parts[-1]
            platform = [string]::Join("-", $parts[2..($parts.Length-2)])
            download_url = $_.browser_download_url
        }
    }
}

function Get-VersionFromRelease {
    param (
        [Parameter(Mandatory)][object]$Release
    )
    # Release name can contain additional information after ':' so filter it
    [string]$releaseName = $Release.name.Split(':')[0]
    [Version]$version = $null
    if (![Version]::TryParse($releaseName, [ref]$version)) {
        throw "Release '$($Release.id)' has invalid title '$($Release.name)'. It can't be parsed as version. ( $($Release.html_url) )"
    }

    return $version
}

function Build-VersionsManifest {
    param (
        [Parameter(Mandatory)][array]$Releases
    )

    $Releases = $Releases | Sort-Object -Property "published_at" -Descending

    $versionsHash = @{}
    foreach ($release in $Releases) {
        if (($release.draft -eq $true) -or ($release.prerelease -eq $true)) {
            continue
        }

        [Version]$version = Get-VersionFromRelease $release
        $versionKey = $version.ToString()

        if ($versionsHash.ContainsKey($versionKey)) {
            continue
        }

        $versionsHash.Add($versionKey, [PSCustomObject]@{
            version = $versionKey
            stable = $true
            release_url = $release.html_url
            files = Build-AssetsList $release.assets
        })
    }

    # Sort versions by descending
    return $versionsHash.Values | Sort-Object -Property "version" -Descending
}

$releases = Get-GitHubReleases
$versionIndex = Build-VersionsManifest $releases
$versionIndex | ConvertTo-Json -Depth 5 | Out-File $OutputFile -Encoding utf8 -Force