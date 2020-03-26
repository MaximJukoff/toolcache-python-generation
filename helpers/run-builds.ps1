param (
    [Parameter(Mandatory)] [string] $TeamFoundationCollectionUri,
    [Parameter(Mandatory)] [string] $AzDoProjectName,
    [Parameter(Mandatory)] [string] $AzDoAccessToken,
    [Parameter(Mandatory)] [string] $SourceBranch,
    [Parameter(Mandatory)] [string] $ToolVersions,
    [Parameter(Mandatory)] [UInt32] $DefinitionId
)

function Get-RequestParams {
    param (
        [Parameter(Mandatory)] [string] $ToolVersion
    )

    # The content of parameters field should be a json string
    $buildParameters = @{ VERSION = $ToolVersion } | ConvertTo-Json

    $body = @{
        definition = @{
            id = $DefinitionId
        }
        reason = "pullRequest"
        sourceBranch = $SourceBranch
        parameters = $buildParameters
    } | ConvertTo-Json

    return @{
        Method = "POST"
        ContentType = "application/json"
        Uri = "${TeamFoundationCollectionUri}/${AzDoProjectName}/_apis/build/builds?api-version=5.1"
        Headers = @{
            Authorization = "Bearer $AzDoAccessToken"
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