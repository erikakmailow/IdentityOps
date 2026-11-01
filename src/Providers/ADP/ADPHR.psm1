function ConvertFrom-IdentityOpsADPEmployee {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSObject]$Record
    )

    $mapping = [ordered]@{
        EmployeeId = @("associateOID", "EmployeeId", "EmployeeNumber")
        FirstName  = @("givenName", "FirstName")
        LastName   = @("familyName", "LastName")
        Username   = @("Username", "UserName", "SamAccountName")
        Email      = @("workEmail", "Email", "EmailAddress")
        Department = @("departmentName", "Department", "DepartmentName")
        JobTitle   = @("jobTitle", "JobTitle", "PositionTitle")
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

Export-ModuleMember -Function "ConvertFrom-IdentityOpsADPEmployee"
