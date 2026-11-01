function Test-IdentityOpsEntraPrerequisites {
    [CmdletBinding()]
    param()

    $graphModules = @(
        "Microsoft.Graph.Authentication",
        "Microsoft.Graph.Users",
        "Microsoft.Graph.Groups",
        "Microsoft.Graph.Identity.DirectoryManagement"
    )

    $moduleStatus = foreach ($name in $graphModules) {
        $found = Get-Module -ListAvailable -Name $name |
            Select-Object -First 1

        [PSCustomObject]@{
            Module    = $name
            Installed = ($null -ne $found)
            Version   = if ($found) { [string]$found.Version } else { $null }
        }
    }

    [PSCustomObject]@{
        Provider       = "MicrosoftEntraID"
        Modules        = @($moduleStatus)
        AllInstalled   = (@($moduleStatus | Where-Object { -not $_.Installed }).Count -eq 0)
        ChangesApplied = $false
    }
}

function Connect-IdentityOpsEntra {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    if ($TenantId -notmatch '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') {
        throw "TenantId must be a valid tenant GUID."
    }

    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph.Authentication is not installed. Run the prerequisite check first."
    }

    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

    # Request read-only scopes only. No write scopes are requested.
    Connect-MgGraph -TenantId $TenantId -Scopes @(
        "User.Read.All",
        "GroupMember.Read.All",
        "Organization.Read.All",
        "LicenseAssignment.Read.All"
    ) -NoWelcome -ErrorAction Stop

    $context = Get-MgContext

    [PSCustomObject]@{
        Connected      = ($null -ne $context)
        TenantId       = $context.TenantId
        Account        = $context.Account
        AuthType       = $context.AuthType
        ReadOnly       = $true
        ChangesApplied = $false
    }
}

Export-ModuleMember -Function @(
    "Test-IdentityOpsEntraPrerequisites",
    "Connect-IdentityOpsEntra"
)
