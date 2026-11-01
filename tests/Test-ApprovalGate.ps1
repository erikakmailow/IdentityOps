$ErrorActionPreference = "Stop"

$modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) "src\Core\ApprovalGate.psm1"
Import-Module $modulePath -Force

Write-Host "`nTEST 1: Preview must not be executable" -ForegroundColor Cyan

$preview = Test-IdentityOpsApproval `
    -Operation Onboarding `
    -EmployeeId "TEST-40025" `
    -DryRun $true `
    -InputValidated $true `
    -DuplicateCheckPassed $true

if (($preview.Status -eq "PreviewOnly") -and
    ($preview.ApprovedForExecution -eq $false) -and
    ($preview.ChangesApplied -eq $false)) {
    Write-Host "PASS: Preview cannot execute." -ForegroundColor Green
}
if (($preview.Status -ne "PreviewOnly") -or
    ($preview.ApprovedForExecution -ne $false) -or
    ($preview.ChangesApplied -ne $false)) {
    throw "FAIL: Preview safety check failed."
}

Write-Host "`nTEST 2: Missing approval must block" -ForegroundColor Cyan

$missingApproval = Test-IdentityOpsApproval `
    -Operation Offboarding `
    -EmployeeId "TEST-40026" `
    -DryRun $false `
    -ApprovalRequired $true `
    -ApprovalGranted $false `
    -ProductionChangesAllowed $true `
    -InputValidated $true `
    -DuplicateCheckPassed $true

if (($missingApproval.Status -eq "Blocked") -and
    ($missingApproval.ApprovedForExecution -eq $false) -and
    ($missingApproval.ChangesApplied -eq $false)) {
    Write-Host "PASS: Missing approval blocks the request." -ForegroundColor Green
}
if (($missingApproval.Status -ne "Blocked") -or
    ($missingApproval.ApprovedForExecution -ne $false) -or
    ($missingApproval.ChangesApplied -ne $false)) {
    throw "FAIL: Missing approval was not blocked."
}

Write-Host "`nTEST 3: Production changes disabled must block" -ForegroundColor Cyan

$productionDisabled = Test-IdentityOpsApproval `
    -Operation AccessChange `
    -EmployeeId "TEST-40027" `
    -DryRun $false `
    -ApprovalRequired $true `
    -ApprovalGranted $true `
    -ProductionChangesAllowed $false `
    -InputValidated $true `
    -DuplicateCheckPassed $true

if (($productionDisabled.Status -eq "Blocked") -and
    ($productionDisabled.ApprovedForExecution -eq $false) -and
    ($productionDisabled.ChangesApplied -eq $false)) {
    Write-Host "PASS: Disabled production changes block the request." -ForegroundColor Green
}
if (($productionDisabled.Status -ne "Blocked") -or
    ($productionDisabled.ApprovedForExecution -ne $false) -or
    ($productionDisabled.ChangesApplied -ne $false)) {
    throw "FAIL: Production-change safeguard failed."
}

Write-Host "`nAll approval-gate tests passed." -ForegroundColor Cyan
