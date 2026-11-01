function Test-IdentityOpsEmployee {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSObject]$Employee
    )

    $errors = [System.Collections.Generic.List[string]]::new()

    $requiredFields = @(
        "EmployeeId",
        "FirstName",
        "LastName",
        "Username",
        "Department",
        "JobTitle"
    )

    foreach ($field in $requiredFields) {
        $property = $Employee.PSObject.Properties[$field]

        if (
            $null -eq $property -or
            [string]::IsNullOrWhiteSpace([string]$property.Value)
        ) {
            $errors.Add("Missing required field: $field")
        }
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$Employee.Username)) {
        if ([string]$Employee.Username -notmatch '^[a-zA-Z0-9._-]{1,20}$') {
            $errors.Add("Username must be 1-20 characters: letters, digits, periods, underscores, or hyphens.")
        }
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$Employee.Email)) {
        if ([string]$Employee.Email -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
            $errors.Add("Email address format is invalid.")
        }
    }

    [PSCustomObject]@{
        IsValid = ($errors.Count -eq 0)
        Errors  = @($errors.ToArray())
    }
}

function Test-IdentityOpsDuplicateEmployee {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSObject[]]$Employees
    )

    $duplicates = @(
        $Employees |
            Group-Object { ([string]$_.EmployeeId).Trim().ToLowerInvariant() } |
            Where-Object {
                $_.Count -gt 1 -and
                -not [string]::IsNullOrWhiteSpace($_.Name)
            } |
            ForEach-Object {
                [PSCustomObject]@{
                    EmployeeId = $_.Name
                    Count      = $_.Count
                }
            }
    )

    [PSCustomObject]@{
        HasDuplicates = ($duplicates.Count -gt 0)
        Duplicates    = @($duplicates)
    }
}

Export-ModuleMember -Function @(
    "Test-IdentityOpsEmployee",
    "Test-IdentityOpsDuplicateEmployee"
)
