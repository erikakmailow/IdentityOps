$ErrorActionPreference = "Stop"

$modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) "src\Access\AccessProfile.psm1"
Import-Module $modulePath -Force

$source = [PSCustomObject]@{
    EmployeeId = "10025"
    Groups = @("GG-Employees", "GG-IT", "Domain Admins")
    Licenses = @("Microsoft 365 E3", "Power BI Pro")
}

$target = [PSCustomObject]@{
    EmployeeId = "10081"
    Groups = @("GG-Employees")
    Licenses = @("Microsoft 365 E3")
}

$result = Compare-IdentityOpsAccessProfile -SourceEmployee $source -TargetEmployee $target

if ($result.DryRun -ne $true) {
    throw "FAIL: DryRun should be true."
}

if ($result.ChangesApplied -ne $false) {
    throw "FAIL: The comparison must not apply changes."
}

$proposedGroups = @($result.GroupChanges | Where-Object { $_.Action -eq "Proposed" } | ForEach-Object { $_.Group })
if ($proposedGroups -notcontains "GG-IT") {
    throw "FAIL: GG-IT should be proposed."
}

$excludedGroups = @($result.GroupChanges | Where-Object { $_.Action -eq "Excluded" } | ForEach-Object { $_.Group })
if ($excludedGroups -notcontains "Domain Admins") {
    throw "FAIL: Domain Admins should be excluded."
}

$proposedLicenses = @($result.LicenseChanges | Where-Object { $_.Action -eq "Proposed" } | ForEach-Object { $_.License })
if ($proposedLicenses -notcontains "Power BI Pro") {
    throw "FAIL: Power BI Pro should be proposed."
}

$sameEmployeeRejected = $false
try {
    Compare-IdentityOpsAccessProfile -SourceEmployee $source -TargetEmployee $source -ErrorAction Stop | Out-Null
}
catch {
    $sameEmployeeRejected = $true
}

if ($sameEmployeeRejected -ne $true) {
    throw "FAIL: The module should reject the same source and target employee."
}

Write-Host ""
Write-Host "PASS: Dry-run protection" -ForegroundColor Green
Write-Host "PASS: No changes applied" -ForegroundColor Green
Write-Host "PASS: Missing group detected" -ForegroundColor Green
Write-Host "PASS: Privileged group excluded" -ForegroundColor Green
Write-Host "PASS: Missing license detected" -ForegroundColor Green
Write-Host "PASS: Same employee rejected" -ForegroundColor Green
Write-Host ""
Write-Host "All access-profile tests passed." -ForegroundColor Cyan
