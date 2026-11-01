$ErrorActionPreference = "Stop"

$modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) "src\Onboarding\Lifecycle.psm1"
Import-Module $modulePath -Force

$employee = [PSCustomObject]@{
    EmployeeId = "TEST-30025"
    FirstName  = "Taylor"
    LastName   = "Example"
    Username   = "texample"
    Email      = "texample@example.com"
    Department = "IT"
    JobTitle   = "Systems Analyst"
}

Write-Host "`nTEST 1: Valid employee stays in preview mode" -ForegroundColor Cyan
$validResult = Invoke-IdentityOpsLifecyclePreview -Action Onboarding -Employee $employee

if (($validResult.Status -eq "Preview") -and
    ($validResult.ApprovalGateStatus -eq "PreviewOnly") -and
    ($validResult.ChangesApplied -eq $false)) {
    Write-Host "PASS: Valid employee remains preview-only." -ForegroundColor Green
}
if (($validResult.Status -ne "Preview") -or
    ($validResult.ApprovalGateStatus -ne "PreviewOnly") -or
    ($validResult.ChangesApplied -ne $false)) {
    throw "FAIL: Valid employee preview safeguards failed."
}

Write-Host "`nTEST 2: Invalid employee is rejected" -ForegroundColor Cyan
$invalidEmployee = [PSCustomObject]@{
    EmployeeId = ""
    FirstName  = ""
    LastName   = "Example"
    Username   = "this_username_is_far_too_long"
    Email      = "not-an-email"
    Department = "IT"
    JobTitle   = "Systems Analyst"
}

$invalidResult = Invoke-IdentityOpsLifecyclePreview -Action Onboarding -Employee $invalidEmployee

if (($invalidResult.Status -eq "Rejected") -and
    ($invalidResult.ChangesApplied -eq $false)) {
    Write-Host "PASS: Invalid employee rejected without changes." -ForegroundColor Green
}
if (($invalidResult.Status -ne "Rejected") -or
    ($invalidResult.ChangesApplied -ne $false)) {
    throw "FAIL: Invalid employee was not safely rejected."
}

Write-Host "`nTEST 3: Offboarding also remains preview-only" -ForegroundColor Cyan
$offboardingResult = Invoke-IdentityOpsLifecyclePreview -Action Offboarding -Employee $employee

if (($offboardingResult.Status -eq "Preview") -and
    ($offboardingResult.ApprovalGateStatus -eq "PreviewOnly") -and
    ($offboardingResult.ChangesApplied -eq $false)) {
    Write-Host "PASS: Offboarding remains preview-only." -ForegroundColor Green
}
if (($offboardingResult.Status -ne "Preview") -or
    ($offboardingResult.ApprovalGateStatus -ne "PreviewOnly") -or
    ($offboardingResult.ChangesApplied -ne $false)) {
    throw "FAIL: Offboarding preview safeguards failed."
}

Write-Host "`nAll lifecycle tests passed." -ForegroundColor Cyan
