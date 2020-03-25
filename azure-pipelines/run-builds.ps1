param (
    [Parameter(Mandatory)] [string] $AzDoOrganizationName,
    [Parameter(Mandatory)] [string] $AzDoProjectName,
    [Parameter(Mandatory)] [string] $AzDoAccessToken,
    [Parameter(Mandatory)] [string] $SourceBranch,
    [Parameter(Mandatory)] [string] $PythonVersions,
    [Parameter(Mandatory)] [UInt32] $BuildId,
    [Parameter(Mandatory)] [UInt32] $PullRequestId,
    [Parameter(Mandatory)] [UInt32] $PullRequestNumber,
    [string] $MergedAt,
    [Parameter(Mandatory)] [string] $TargetBranch,
    [Parameter(Mandatory)] [string] $SourceRepositoryUri,
    [Parameter(Mandatory)] [string] $SourceCommitId
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
        sourceBranch = $SourceBranch
        parameters = "{ ""VERSION"" : ""$PythonVersion""
                        ""system.pullRequest.pullRequestId"" : ""$PullRequestId""
                        ""system.pullRequest.pullRequestNumber"" : ""$PullRequestNumber""
                        ""system.pullRequest.mergedAt"" : ""$MergedAt""
                        ""system.pullRequest.sourceBranch"" : ""$SourceBranch""
                        ""system.pullRequest.targetBranch"" : ""$TargetBranch""
                        ""system.pullRequest.sourceRepositoryUri"" : ""$SourceRepositoryUri""
                        ""system.pullRequest.sourceCommitId"" : ""$SourceCommitId"" }"
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
    Write-Host "Queued build: $($NewRelease._links.web.href)"
}