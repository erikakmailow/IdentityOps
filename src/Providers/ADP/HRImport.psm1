Import-Module (Join-Path $PSScriptRoot "..\..\Core\Validation.psm1") -Force

function Import-IdentityOpsHRData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$Path
    )

    $rows = @(Import-Csv -LiteralPath $Path -ErrorAction Stop)

    if ($rows.Count -eq 0) {
        throw "HR import contains no employee records."
    }

    $requiredColumns = @(
        "EmployeeId",
        "FirstName",
        "LastName",
        "Username",
        "Email",
        "Department",
        "JobTitle"
    )

    $actualColumns = @($rows[0].PSObject.Properties.Name)

    foreach ($column in $requiredColumns) {
        if ($actualColumns -notcontains $column) {
            throw "HR import is missing required column: $column"
        }
    }

    $duplicateCheck = Test-IdentityOpsDuplicateEmployee -Employees $rows

    $results = foreach ($row in $rows) {
        $validation = Test-IdentityOpsEmployee -Employee $row

        [PSCustomObject]@{
            EmployeeId = [string]$row.EmployeeId
            Username   = [string]$row.Username
            IsValid    = $validation.IsValid
            Errors     = @($validation.Errors)
        }
    }

    [PSCustomObject]@{
        Source          = [System.IO.Path]::GetFileName($Path)
        TotalRecords    = $rows.Count
        ValidRecords    = @($results | Where-Object IsValid).Count
        InvalidRecords  = @($results | Where-Object { -not $_.IsValid }).Count
        HasDuplicates   = $duplicateCheck.HasDuplicates
        Duplicates      = @($duplicateCheck.Duplicates)
        Records         = @($results)
        ChangesApplied  = $false
    }
}

Export-ModuleMember -Function "Import-IdentityOpsHRData"
