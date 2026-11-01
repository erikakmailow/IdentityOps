$ErrorActionPreference = "Stop"

$modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) "src\Passwords\PasswordGenerator.psm1"
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

Write-Host "`nTEST 1: Strong password policy" -ForegroundColor Cyan

$strong = New-IdentityOpsPassword -Mode Strong

Assert-Test ($strong.Length -eq 20) "Strong password is exactly 20 characters"
Assert-Test ($strong -cmatch '[A-Z]') "Strong password has uppercase"
Assert-Test ($strong -cmatch '[a-z]') "Strong password has lowercase"
Assert-Test ($strong -match '\d') "Strong password has a digit"
Assert-Test ($strong -match '[^a-zA-Z0-9]') "Strong password has a special character"

Write-Host "`nTEST 2: Account password policy" -ForegroundColor Cyan

$account = New-IdentityOpsPassword -Mode Account
$words = @($account -split '  ')

Assert-Test ($words.Count -eq 3) "Account password has three words"
Assert-Test ($account.Contains("  ")) "Account password has two spaces between words"
Assert-Test ($words[0] -cmatch '^[A-Z]') "First word begins with uppercase"
Assert-Test ($account -match '\d') "Account password has a digit"
Assert-Test ($account -match '[^a-zA-Z0-9 ]') "Account password has a special character"

Write-Host "`nTEST 3: Temporary password policy" -ForegroundColor Cyan

$temporary = New-IdentityOpsPassword -Mode Temporary

Assert-Test ($temporary.Length -ge 8) "Temporary password is at least 8 characters"
Assert-Test ($temporary -cmatch '[A-Z]') "Temporary password has uppercase"
Assert-Test ($temporary -cmatch '[a-z]') "Temporary password has lowercase"
Assert-Test ($temporary -match '\d') "Temporary password has a digit"

Write-Host "`nTEST 4: Repeated generation" -ForegroundColor Cyan

$repeatSuccess = $true
1..10 | ForEach-Object {
    $generated = New-IdentityOpsPassword -Mode Temporary
    if ([string]::IsNullOrWhiteSpace($generated) -or $generated.Length -lt 8) {
        $repeatSuccess = $false
    }
}

Assert-Test $repeatSuccess "Ten additional temporary passwords met minimum length"

Write-Host "`nAll password-generator tests passed." -ForegroundColor Cyan

