function Test-IdentityOpsADPrerequisites {
    [CmdletBinding()]
    param()

    $module = Get-Module -ListAvailable -Name ActiveDirectory

    $powershellEdition = $PSVersionTable.PSEdition
    $isWindows = $env:OS -eq "Windows_NT"

    $result = [PSCustomObject]@{
        Provider          = "ActiveDirectory"
        IsWindows         = $isWindows
        PowerShellEdition = $powershellEdition
        ModuleInstalled   = ($null -ne $module)
        ModuleVersion     = if ($module) {
            [string]$module[0].Version
        } else {
            $null
        }
        Ready             = ($isWindows -and $null -ne $module)
        ChangesApplied    = $false
    }

    return $result
}

function Connect-IdentityOpsAD {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Server,

        [Parameter(Mandatory)]
        [string]$SearchBase
    )

    if ([string]::IsNullOrWhiteSpace($Server)) {
        throw "A domain controller must be specified."
    }

    if ([string]::IsNullOrWhiteSpace($SearchBase)) {
        throw "An Active Directory search base must be specified."
    }

    $prerequisites = Test-IdentityOpsADPrerequisites

    if (-not $prerequisites.Ready) {
        throw "Active Directory prerequisites are missing. Run Test-IdentityOpsADPrerequisites."
    }

    Import-Module ActiveDirectory -ErrorAction Stop

    # Read-only connectivity check. No account changes are performed.
    $domain = Get-ADDomain -Server $Server -ErrorAction Stop

    [PSCustomObject]@{
        Connected      = $true
        Server         = $Server
        Domain         = $domain.DNSRoot
        SearchBase     = $SearchBase
        ReadOnly       = $true
        ChangesApplied = $false
    }
}

Export-ModuleMember -Function @(
    "Test-IdentityOpsADPrerequisites",
    "Connect-IdentityOpsAD"
)
