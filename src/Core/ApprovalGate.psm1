function Test-IdentityOpsApproval {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Onboarding", "Offboarding", "AccessChange")]
        [string]$Operation,

        [Parameter(Mandatory)]
        [string]$EmployeeId,

        [Parameter(Mandatory)]
        [bool]$DryRun,

        [bool]$ApprovalRequired = $true,

        [bool]$ApprovalGranted = $false,

        [bool]$ProductionChangesAllowed = $false,

        [bool]$InputValidated = $false,

        [bool]$DuplicateCheckPassed = $false
    )

    $reasons = @()
    $approvedForExecution = $false

    if ([string]::IsNullOrWhiteSpace($EmployeeId)) {
        $reasons += "Employee ID is missing."
    }

    if (-not $InputValidated) {
        $reasons += "Input validation has not passed."
    }

    if (-not $DuplicateCheckPassed) {
        $reasons += "Duplicate check has not passed."
    }

    if ($ApprovalRequired -and -not $ApprovalGranted) {
        $reasons += "Required approval has not been granted."
    }

    if (-not $DryRun -and -not $ProductionChangesAllowed) {
        $reasons += "Production changes are disabled."
    }

    if ($DryRun) {
        $status = "PreviewOnly"
        $reasons += "Dry-run mode: no changes may be executed."
    }
    elseif ($reasons.Count -gt 0) {
        $status = "Blocked"
    }
    else {
        $status = "EligibleForExecutionReview"
        $approvedForExecution = $true
        $reasons += "Safety checks passed; separate execution controls are still required."
    }

    [PSCustomObject]@{
        Operation               = $Operation
        EmployeeId              = $EmployeeId
        Status                  = $status
        ApprovedForExecution    = $approvedForExecution
        DryRun                  = $DryRun
        ChangesApplied          = $false
        Reasons                 = @($reasons)
        EvaluatedAtUtc          = [DateTime]::UtcNow.ToString("o")
    }
}

Export-ModuleMember -Function "Test-IdentityOpsApproval"
