Import-Module (Join-Path $PSScriptRoot "..\Core\Validation.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "..\Core\Logging.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "..\Core\ApprovalGate.psm1") -Force

function Invoke-IdentityOpsLifecyclePreview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Onboarding", "Offboarding")]
        [string]$Action,

        [Parameter(Mandatory)]
        [PSObject]$Employee,

        [string]$CorrelationId = [guid]::NewGuid().ToString(),

        [bool]$ApprovalGranted = $false,

        [bool]$DuplicateCheckPassed = $false
    )

    $validation = Test-IdentityOpsEmployee -Employee $Employee

    if (-not $validation.IsValid) {
        Write-IdentityOpsLog -Level WARN `
            -Operation $Action `
            -CorrelationId $CorrelationId `
            -Message "Lifecycle preview rejected because employee validation failed."

        return [PSCustomObject]@{
            Action              = $Action
            Status              = "Rejected"
            EmployeeId          = [string]$Employee.EmployeeId
            CorrelationId       = $CorrelationId
            Errors              = @($validation.Errors)
            ApprovalGateStatus  = "NotEvaluated"
            ApprovalGateReasons = @("Employee validation failed.")
            DryRun              = $true
            ChangesApplied      = $false
        }
    }

    $gate = Test-IdentityOpsApproval `
        -Operation $Action `
        -EmployeeId ([string]$Employee.EmployeeId) `
        -DryRun $true `
        -ApprovalRequired $true `
        -ApprovalGranted $ApprovalGranted `
        -InputValidated $true `
        -DuplicateCheckPassed $DuplicateCheckPassed

    $message = "Employee passed validation. Lifecycle action is preview-only."

    Write-IdentityOpsLog -Level AUDIT `
        -Operation $Action `
        -CorrelationId $CorrelationId `
        -Message "$message EmployeeId=$($Employee.EmployeeId); ApprovalGate=$($gate.Status)"

    [PSCustomObject]@{
        Action              = $Action
        Status              = "Preview"
        EmployeeId          = [string]$Employee.EmployeeId
        Username            = [string]$Employee.Username
        CorrelationId       = $CorrelationId
        Errors              = @()
        ApprovalGateStatus  = $gate.Status
        ApprovalGateReasons = @($gate.Reasons)
        DryRun              = $true
        ChangesApplied      = $false
        Message             = $message
    }
}

Export-ModuleMember -Function "Invoke-IdentityOpsLifecyclePreview"
