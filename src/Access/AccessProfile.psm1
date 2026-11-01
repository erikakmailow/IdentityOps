function Compare-IdentityOpsAccessProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSObject]$SourceEmployee,

        [Parameter(Mandatory)]
        [PSObject]$TargetEmployee,

        [string[]]$ExcludedGroups = @(
            "Domain Admins",
            "Enterprise Admins",
            "Schema Admins",
            "Administrators",
            "Global Administrator",
            "Privileged Role Administrator"
        )
    )

    foreach ($employee in @($SourceEmployee, $TargetEmployee)) {
        foreach ($field in @("EmployeeId", "Groups", "Licenses")) {
            if ($null -eq $employee.PSObject.Properties[$field]) {
                throw "Employee profile is missing required property: $field"
            }
        }
    }

    if ([string]$SourceEmployee.EmployeeId -eq
        [string]$TargetEmployee.EmployeeId) {
        throw "Source and target must be different employees."
    }

    $sourceGroups = @($SourceEmployee.Groups | Where-Object { $_ })
    $targetGroups = @($TargetEmployee.Groups | Where-Object { $_ })

    $sourceLicenses = @($SourceEmployee.Licenses | Where-Object { $_ })
    $targetLicenses = @($TargetEmployee.Licenses | Where-Object { $_ })

    $groupChanges = @(
        foreach ($group in $sourceGroups) {
            $excluded = $ExcludedGroups -contains [string]$group

            $alreadyAssigned = $false
            foreach ($existing in $targetGroups) {
                if ([string]$existing -ieq [string]$group) {
                    $alreadyAssigned = $true
                    break
                }
            }

            if (-not $alreadyAssigned) {
                [PSCustomObject]@{
                    Group    = [string]$group
                    Action   = if ($excluded) { "Excluded" } else { "Proposed" }
                    Reason   = if ($excluded) {
                        "Privileged group requires separate authorization."
                    } else {
                        "Present on source; missing on target."
                    }
                }
            }
        }
    )

    $licenseChanges = @(
        foreach ($license in $sourceLicenses) {
            $alreadyAssigned = $false

            foreach ($existing in $targetLicenses) {
                if ([string]$existing -ieq [string]$license) {
                    $alreadyAssigned = $true
                    break
                }
            }

            if (-not $alreadyAssigned) {
                [PSCustomObject]@{
                    License = [string]$license
                    Action  = "Proposed"
                    Reason  = "Present on source; missing on target. Eligibility and availability must be checked."
                }
            }
        }
    )

    [PSCustomObject]@{
        SourceEmployeeId = [string]$SourceEmployee.EmployeeId
        TargetEmployeeId = [string]$TargetEmployee.EmployeeId
        GroupChanges     = @($groupChanges)
        LicenseChanges   = @($licenseChanges)
        DryRun           = $true
        ChangesApplied   = $false
    }
}

Export-ModuleMember -Function "Compare-IdentityOpsAccessProfile"
