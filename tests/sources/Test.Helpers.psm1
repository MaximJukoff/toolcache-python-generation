function Get-CommandExitCode {
    Param (
      [String] [Parameter (Mandatory = $true)] [ValidateNotNullOrEmpty()]
      $Command
    )
  
    $null = Invoke-Expression -Command $Command
    return $LASTEXITCODE
}