param (
    [Parameter(Mandatory)] [string] $AzDoOrganizationName,
    [Parameter(Mandatory)] [string] $AzDoProjectName,
    [Parameter(Mandatory)] [string] $AzDoAccessToken,
    [Parameter(Mandatory)] [string] $SourceBranch
)

$encodedToken = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$GitHubAccessToken"))

$body = @{
    definition = @{
        id = 6
    }
    sourceBranch = $SourceBranch
    parameters = "{ ""VERSION"":  ""3.7.6"" }"
} | ConvertTo-Json -Depth 5

$requestParams = @{
    Method = "POST"
    ContentType = "application/json"
    Uri = "https://dev.azure.com/$AzDoOrganizationName/$AzDoProjectName/_apis/build/builds?api-version=5.1"
    Headers = @{
        Authorization = "Basic $encodedToken"
    }
    Body = $body
}

Invoke-RestMethod @requestParams