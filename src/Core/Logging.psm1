function Write-IdentityOpsLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("INFO", "WARN", "ERROR", "AUDIT")]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Operation = "General",

        [string]$CorrelationId = ""
    )

    $timestamp = [DateTime]::UtcNow.ToString("o")

    $safeMessage = $Message -replace `
        '(?i)\b(password|passwd|pwd|client_secret|clientsecret|access_token|refresh_token|secret)\s*[:=]\s*("[^"]*"|''[^'']*''|\S+)', `
        '$1=[REDACTED]'

    if ([string]::IsNullOrWhiteSpace($CorrelationId)) {
        $CorrelationId = [guid]::NewGuid().ToString()
    }

    $entry = [ordered]@{
        Timestamp     = $timestamp
        Level         = $Level
        Operation     = $Operation
        CorrelationId = $CorrelationId
        Message       = $safeMessage
    }

    $json = $entry | ConvertTo-Json -Compress -Depth 5

    $projectRoot = Split-Path $PSScriptRoot -Parent
    $projectRoot = Split-Path $projectRoot -Parent
    $logDirectory = Join-Path $projectRoot "logs"

    New-Item -ItemType Directory -Path $logDirectory -Force |
        Out-Null

    $logPath = Join-Path $logDirectory (
        "IdentityOps-{0}.jsonl" -f (Get-Date -Format "yyyy-MM-dd")
    )

    Add-Content -LiteralPath $logPath -Value $json -Encoding utf8

    switch ($Level) {
        "INFO"  { $color = "Cyan" }
        "WARN"  { $color = "Yellow" }
        "ERROR" { $color = "Red" }
        "AUDIT" { $color = "Magenta" }
    }

    Write-Host "[$Level] $safeMessage" -ForegroundColor $color
}

Export-ModuleMember -Function Write-IdentityOpsLog
