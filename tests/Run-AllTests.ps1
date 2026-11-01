$ErrorActionPreference = "Stop"

$testFiles = @(
    "Test-AccessProfile.ps1",
    "Test-Lifecycle.ps1",
    "Test-ApprovalGate.ps1",
    "Test-HRSafetyGate.ps1",
    "Test-PasswordGenerator.ps1"
)

$results = @()
$powershellExe = Join-Path $PSHOME "powershell.exe"

foreach ($testFile in $testFiles) {
    $path = Join-Path $PSScriptRoot $testFile

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Running: $testFile" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    if (-not (Test-Path -LiteralPath $path)) {
        $results += [PSCustomObject]@{
            Test = $testFile
            Status = "FAIL"
            Detail = "File not found"
        }
        Write-Host "FAIL: File not found." -ForegroundColor Red
        continue
    }

    & $powershellExe -NoProfile -ExecutionPolicy Bypass -File $path
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        $results += [PSCustomObject]@{
            Test = $testFile
            Status = "PASS"
            Detail = "Process exit code 0"
        }
        Write-Host "RESULT: PASS" -ForegroundColor Green
    }

    if ($exitCode -ne 0) {
        $results += [PSCustomObject]@{
            Test = $testFile
            Status = "FAIL"
            Detail = "Process exit code $exitCode"
        }
        Write-Host "RESULT: FAIL - Exit code $exitCode" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$results | Format-Table Test, Status, Detail -AutoSize

$passed = @($results | Where-Object { $_.Status -eq "PASS" }).Count
$failed = @($results | Where-Object { $_.Status -eq "FAIL" }).Count

Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red

if ($failed -gt 0) {
    throw "One or more test scripts failed."
}

Write-Host "`nAll five test suites completed successfully." -ForegroundColor Green
