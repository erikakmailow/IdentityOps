function ConvertFrom-IdentityOpsOracleEmployee {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSObject]$Record
    )

    $mapping = [ordered]@{
        EmployeeId = @("PersonNumber", "EmployeeNumber", "EmployeeId")
        FirstName  = @("FirstName", "GivenName")
        LastName   = @("LastName", "FamilyName")
        Username   = @("Username", "UserName", "SamAccountName")
        Email      = @("WorkEmail", "EmailAddress", "Email")
        Department = @("DepartmentName", "Department")
        JobTitle   = @("JobName", "JobTitle", "PositionName")
    }

    $employee = [ordered]@{}

    foreach ($targetField in $mapping.Keys) {
        $value = $null

        foreach ($candidate in $mapping[$targetField]) {
            $property = $Record.PSObject.Properties[$candidate]

            if (
                $null -ne $property -and
                -not [string]::IsNullOrWhiteSpace([string]$property.Value)
            ) {
                $value = [string]$property.Value
                break
            }
        }

        $employee[$targetField] = $value
    }

    [PSCustomObject]$employee
}

Export-ModuleMember -Function "ConvertFrom-IdentityOpsOracleEmployee"
