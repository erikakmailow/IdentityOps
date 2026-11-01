$ProjectRoot = $PSScriptRoot

function Show-IdentityOpsMenu {
    Clear-Host
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "         IDENTITYOPS" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Generate password"
    Write-Host "  [2] Compare employee access profiles"
    Write-Host "  [3] Validate HR import batch"
    Write-Host "  [4] Check Active Directory prerequisites"
    Write-Host "  [5] Check Entra ID prerequisites"
    Write-Host "  [6] View recent logs"
    Write-Host "  [Q] Quit"
    Write-Host ""
    Write-Host "  MODE: DEVELOPMENT / PREVIEW ONLY" -ForegroundColor Yellow
    Write-Host "  No directory changes are performed by this menu." -ForegroundColor Yellow
    Write-Host ""
}

function Invoke-IdentityOpsMenu {
    while ($true) {
        Show-IdentityOpsMenu
        $choice = Read-Host "Select an option"

        switch ($choice.ToUpperInvariant()) {
            "1" {
                Import-Module (Join-Path $ProjectRoot "src\Passwords\PasswordGenerator.psm1") -Force
                $mode = Read-Host "Password mode (Strong, Account, Temporary)"

                try {
                    $password = New-IdentityOpsPassword -Mode $mode -ErrorAction Stop
                    Write-Host "`nGenerated password (display only):" -ForegroundColor Cyan
                    Write-Host $password
                    Write-Host "Do not share this output or save it in logs." -ForegroundColor Yellow
                }
                catch {
                    Write-Host "Password generation failed: $($_.Exception.Message)" -ForegroundColor Red
                }

                Read-Host "`nPress Enter to continue" | Out-Null
            }

            "2" {
                try {
                    Import-Module (Join-Path $ProjectRoot "src\Access\AccessProfile.psm1") -Force -ErrorAction Stop

                    Write-Host "`nEnter fictional test profiles." -ForegroundColor Cyan
                    $sourceId = Read-Host "Reference employee ID"
                    $targetId = Read-Host "Target employee ID"

                    $sourceGroupsText = Read-Host "Reference groups (comma-separated)"
                    $targetGroupsText = Read-Host "Target groups (comma-separated)"
                    $sourceLicensesText = Read-Host "Reference licenses (comma-separated)"
                    $targetLicensesText = Read-Host "Target licenses (comma-separated)"

                    $sourceProfile = [PSCustomObject]@{
                        EmployeeId = $sourceId
                        Groups = @($sourceGroupsText -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                        Licenses = @($sourceLicensesText -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                    }

                    $targetProfile = [PSCustomObject]@{
                        EmployeeId = $targetId
                        Groups = @($targetGroupsText -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                        Licenses = @($targetLicensesText -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                    }

                    $comparison = Compare-IdentityOpsAccessProfile -SourceEmployee $sourceProfile -TargetEmployee $targetProfile -ErrorAction Stop

                    Write-Host "`nACCESS COMPARISON SUMMARY" -ForegroundColor Cyan
                    [PSCustomObject]@{
                        SourceEmployeeId = $comparison.SourceEmployeeId
                        TargetEmployeeId = $comparison.TargetEmployeeId
                        DryRun = $comparison.DryRun
                        ChangesApplied = $comparison.ChangesApplied
                    } | Format-List

                    Write-Host "GROUP CHANGES" -ForegroundColor Cyan
                    if (@($comparison.GroupChanges).Count -gt 0) {
                        $comparison.GroupChanges | Format-Table Group, Action, Reason -AutoSize
                    }
                    if (@($comparison.GroupChanges).Count -eq 0) {
                        Write-Host "No missing groups found."
                    }

                    Write-Host "LICENSE CHANGES" -ForegroundColor Cyan
                    if (@($comparison.LicenseChanges).Count -gt 0) {
                        $comparison.LicenseChanges | Format-Table License, Action, Reason -AutoSize
                    }
                    if (@($comparison.LicenseChanges).Count -eq 0) {
                        Write-Host "No missing licenses found."
                    }

                    Write-Host "`nThis is a preview only. No access changes were made." -ForegroundColor Yellow
                }
                catch {
                    Write-Host "Access comparison failed: $($_.Exception.Message)" -ForegroundColor Red
                }

                Read-Host "`nPress Enter to continue" | Out-Null
            }

            "3" {
                try {
                    Import-Module (Join-Path $ProjectRoot "src\Core\HRSafetyGate.psm1") -Force -ErrorAction Stop
                    $path = Read-Host "CSV path (default: .\tests\sample-hr-import.csv)"

                    if ([string]::IsNullOrWhiteSpace($path)) {
                        $path = Join-Path $ProjectRoot "tests\sample-hr-import.csv"
                    }

                    $employees = @(Import-Csv -LiteralPath $path -ErrorAction Stop)
                    $result = Test-IdentityOpsHRBatch -Employees $employees

                    $result |
                        Select-Object TotalRecords, ApprovedCount, BlockedCount, ChangesApplied |
                        Format-List

                    $result.Results |
                        Format-Table EmployeeId, Username, Decision -AutoSize
                }
                catch {
                    Write-Host "HR validation failed: $($_.Exception.Message)" -ForegroundColor Red
                }

                Read-Host "`nPress Enter to continue" | Out-Null
            }

            "4" {
                Import-Module (Join-Path $ProjectRoot "src\Providers\ActiveDirectory\ActiveDirectoryProvider.psm1") -Force
                Test-IdentityOpsADPrerequisites | Format-List
                Read-Host "`nPress Enter to continue" | Out-Null
            }

            "5" {
                Import-Module (Join-Path $ProjectRoot "src\Providers\EntraID\EntraProvider.psm1") -Force
                Test-IdentityOpsEntraPrerequisites | Format-List
                Read-Host "`nPress Enter to continue" | Out-Null
            }

            "6" {
                $logDirectory = Join-Path $ProjectRoot "logs"
                $latest = Get-ChildItem -LiteralPath $logDirectory -Filter "*.jsonl" -File -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -First 1

                if ($null -ne $latest) {
                    Get-Content -LiteralPath $latest.FullName -Tail 10
                }
                else {
                    Write-Host "No logs found yet." -ForegroundColor Yellow
                }

                Read-Host "`nPress Enter to continue" | Out-Null
            }

            "Q" {
                Write-Host "Exiting IdentityOps." -ForegroundColor Cyan
                return
            }

            default {
                Write-Host "Invalid selection." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

Invoke-IdentityOpsMenu


