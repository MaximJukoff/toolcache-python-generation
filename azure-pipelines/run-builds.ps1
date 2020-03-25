param (
    [Parameter(Mandatory)] [string] $AzDoOrganizationName,
    [Parameter(Mandatory)] [string] $AzDoProjectName,
    [Parameter(Mandatory)] [string] $AzDoAccessToken,
    [Parameter(Mandatory)] [string] $SourceBranch,
    [Parameter(Mandatory)] [string] $PythonVersions,
    [Parameter(Mandatory)] [UInt32] $BuildId
)

function Get-RequestParams {
    param (
        [Parameter(Mandatory)] [string] $PythonVersion
    )

    $encodedToken = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("'':$AzDoAccessToken"))

    $body = @{
        definition = @{
            id = $BuildId
        }
        reason = "pullRequest"
        sourceBranch = $SourceBranch
        # The content of parameters field should be a json string
        parameters = @{ VERSION = $PythonVersion } | ConvertTo-Json -Depth 2
    } | ConvertTo-Json -Depth 3

    return @{
        Method = "POST"
        ContentType = "application/json"
        Uri = "https://dev.azure.com/$AzDoOrganizationName/$AzDoProjectName/_apis/build/builds?api-version=5.1"
        Headers = @{
            Authorization = "Basic $encodedToken"
        }
        Body = $body
    }
}

$PythonVersions.Split(',') | foreach { 
    $version = $_.Trim()
    $requestParams = Get-RequestParams -PythonVersion $version
    Write-Host "Queue build for Python $version..."
    $response = Invoke-RestMethod @requestParams
    Write-Host "Queued build: $($response._links.web.href)"
}