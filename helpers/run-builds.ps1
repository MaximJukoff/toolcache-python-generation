param (
    [Parameter(Mandatory)] [string] $AzDoOrganizationName,
    [Parameter(Mandatory)] [string] $AzDoProjectName,
    [Parameter(Mandatory)] [string] $AzDoAccessToken,
    [Parameter(Mandatory)] [string] $SourceBranch,
    [Parameter(Mandatory)] [string] $ToolVersions,
    [Parameter(Mandatory)] [UInt32] $BuildId
)

function Get-RequestParams {
    param (
        [Parameter(Mandatory)] [string] $ToolVersion
    )

    $encodedToken = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("'':${AzDoAccessToken}"))
    # The content of parameters field should be a json string
    $buildParameters = @{ VERSION = $ToolVersion } | ConvertTo-Json -Depth 2

    $body = @{
        definition = @{
            id = $BuildId
        }
        sourceBranch = $SourceBranch
        parameters = $buildParameters
    } | ConvertTo-Json -Depth 3

    return @{
        Method = "POST"
        ContentType = "application/json"
        Uri = "https://dev.azure.com/${AzDoOrganizationName}/${AzDoProjectName}/_apis/build/builds?api-version=5.1"
        Headers = @{
            Authorization = "Basic $encodedToken"
        }
        Body = $body
    }
}

$ToolVersions.Split(',') | ForEach-Object { 
    $version = $_.Trim()
    $requestParams = Get-RequestParams -ToolVersion $version
    Write-Host "Queue build for $version..."
    $response = Invoke-RestMethod @requestParams
    Write-Host "Queued build: $($response._links.web.href)"
}