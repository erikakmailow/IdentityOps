Import-Module (Join-Path $PSScriptRoot "..\Core\Validation.psm1") -Force

function Test-IdentityOpsHRBatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSObject[]]$Employees
    )

    if ($Employees.Count -eq 0) {
        throw "HR batch is empty."
    }

    $duplicateCheck = Test-IdentityOpsDuplicateEmployee -Employees $Employees

    $duplicateIds = @(
        $duplicateCheck.Duplicates |
            ForEach-Object { [string]$_.EmployeeId }
    )

    $results = foreach ($employee in $Employees) {
        $validation = Test-IdentityOpsEmployee -Employee $employee

        $employeeId = ([string]$employee.EmployeeId).Trim()
        $isDuplicate = $duplicateIds -contains $employeeId

        $errors = @($validation.Errors)

        if ($isDuplicate) {
            $errors += "Duplicate EmployeeId detected in HR batch."
        }

        [PSCustomObject]@{
            EmployeeId = $employeeId
            Username   = [string]$employee.Username
            IsValid    = ($validation.IsValid -and -not $isDuplicate)
            Decision   = if ($validation.IsValid -and -not $isDuplicate) {
                "ApprovedForReview"
            } else {
                "Blocked"
            }
            Errors     = @($errors)
        }
    }

    [PSCustomObject]@{
        TotalRecords   = $Employees.Count
        ApprovedCount  = @($results | Where-Object { $_.Decision -eq "ApprovedForReview" }).Count
        BlockedCount   = @($results | Where-Object { $_.Decision -eq "Blocked" }).Count
        Results        = @($results)
        ChangesApplied = $false
    }
}

Export-ModuleMember -Function "Test-IdentityOpsHRBatch"
