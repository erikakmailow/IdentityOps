$ErrorActionPreference = "Stop"

$modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) "src\Core\HRSafetyGate.psm1"
Import-Module $modulePath -Force

function Assert-Test {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw "FAIL: $Message"
    }

    Write-Host "PASS: $Message" -ForegroundColor Green
}

function New-TestEmployee {
    param(
        [string]$EmployeeId,
        [string]$Username,
        [string]$Email = "test@example.com"
    )

    [PSCustomObject]@{
        EmployeeId = $EmployeeId
        FirstName  = "Taylor"
        LastName   = "Example"
        Username   = $Username
        Email      = $Email
        Department = "IT"
        JobTitle   = "Systems Analyst"
    }
}

Write-Host "`nTEST 1: Unique valid employee" -ForegroundColor Cyan

$uniqueBatch = @(
    New-TestEmployee -EmployeeId "TEST-50025" -Username "taylor.test"
)

$uniqueResult = Test-IdentityOpsHRBatch -Employees $uniqueBatch

Assert-Test ($uniqueResult.TotalRecords -eq 1) "One input record counted"
Assert-Test ($uniqueResult.ApprovedCount -eq 1) "Unique valid employee approved for review"
Assert-Test ($uniqueResult.BlockedCount -eq 0) "No records blocked"
Assert-Test ($uniqueResult.ChangesApplied -eq $false) "HR safety gate applies no changes"

Write-Host "`nTEST 2: Duplicate employee IDs" -ForegroundColor Cyan

$duplicateBatch = @(
    (New-TestEmployee -EmployeeId "TEST-50026" -Username "jordan.test"),
    (New-TestEmployee -EmployeeId "test-50026" -Username "casey.test")
)

$duplicateResult = Test-IdentityOpsHRBatch -Employees $duplicateBatch

Assert-Test ($duplicateResult.BlockedCount -eq 2) "Both records with duplicate IDs are blocked"
Assert-Test ($duplicateResult.ApprovedCount -eq 0) "Duplicate batch has no approved records"

Write-Host "`nTEST 3: Invalid employee record" -ForegroundColor Cyan

$invalidBatch = @(
    (New-TestEmployee -EmployeeId "" -Username "bad username!" -Email "not-an-email")
)

$invalidResult = Test-IdentityOpsHRBatch -Employees $invalidBatch

Assert-Test ($invalidResult.BlockedCount -eq 1) "Invalid record is blocked"
Assert-Test ($invalidResult.ApprovedCount -eq 0) "Invalid record is not approved for review"

Write-Host "`nTEST 4: Empty batch" -ForegroundColor Cyan

$emptyBatchRejected = $false

try {
    Test-IdentityOpsHRBatch -Employees @() -ErrorAction Stop | Out-Null
}
catch {
    $emptyBatchRejected = $true
}

Assert-Test $emptyBatchRejected "Empty batch is rejected"

Write-Host "`nAll HR safety-gate tests passed." -ForegroundColor Cyan
