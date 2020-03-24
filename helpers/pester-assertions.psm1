function ShouldReturnZeroExitCode {
    Param(
        [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
        [String]$Command,
        [switch]$Negate
    )

    $actualCommandOutput = Invoke-Expression -Command $Command
    $actualExitCode = $LASTEXITCODE
    Write-Host $actualCommandOutput

    [bool]$succeeded = $actualExitCode -eq 0
    if ($Negate) { $succeeded = -not $succeeded }

    if (-not $succeeded)
    {
        $failureMessage = "Command '{$ActualValue}' has finished with exit code ${actualExitCode}"
    }

    return New-Object PSObject -Property @{
        Succeeded      = $succeeded
        FailureMessage = $failureMessage
    }
}

Add-AssertionOperator -Name ReturnZeroExitCode `
                    -Test  $function:ShouldReturnZeroExitCode
