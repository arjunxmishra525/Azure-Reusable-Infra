
param(
    [string]$CsvPath = ".\terraform_input_sheet.csv",
    [string]$OutputPath = ".\terraform.tfvars"
)

Write-Host "============================================="
Write-Host "       Terraform TFVARS Generator"
Write-Host "============================================="
Write-Host ""

# =========================================================
# 1. Check CSV file
# =========================================================

if (-not (Test-Path -LiteralPath $CsvPath)) {
    Write-Error "CSV file not found: $CsvPath"
    exit 1
}

Write-Host "CSV File    : $CsvPath"
Write-Host "Output File : $OutputPath"
Write-Host ""

# =========================================================
# 2. Read CSV
# =========================================================

try {
    $rows = @(Import-Csv -LiteralPath $CsvPath)
}
catch {
    Write-Error "Unable to read CSV file."
    Write-Error $_.Exception.Message
    exit 1
}

if ($rows.Count -eq 0) {
    Write-Error "CSV file is empty."
    exit 1
}

# =========================================================
# 3. Validate CSV columns
# =========================================================

$requiredColumns = @(
    "resource_type",
    "resource_id",
    "variable",
    "value"
)

$csvColumns = $rows[0].PSObject.Properties.Name

foreach ($column in $requiredColumns) {

    if ($column -notin $csvColumns) {
        Write-Error "Required CSV column '$column' is missing."
        Write-Host ""
        Write-Host "Expected CSV columns:"
        Write-Host "resource_type,resource_id,variable,value"
        exit 1
    }
}

Write-Host "CSV validation successful."
Write-Host "Total rows  : $($rows.Count)"
Write-Host ""

# =========================================================
# 4. Create nested data structure
#
# resource_type
#     |
#     +-- resource_id
#             |
#             +-- variable = value
#
# Example:
#
# vnet
#   vnet1
#      name = dev-vnet
#      location = Central India
#
# =========================================================

$data = [ordered]@{}

foreach ($row in $rows) {

    $resourceType = if ($null -ne $row.resource_type) {
        $row.resource_type.Trim()
    }
    else {
        ""
    }

    $resourceId = if ($null -ne $row.resource_id) {
        $row.resource_id.Trim()
    }
    else {
        ""
    }

    $variable = if ($null -ne $row.variable) {
        $row.variable.Trim()
    }
    else {
        ""
    }

    $value = if ($null -ne $row.value) {
        $row.value.Trim()
    }
    else {
        ""
    }

    # -----------------------------------------------------
    # Skip invalid rows
    # -----------------------------------------------------

    if (
        [string]::IsNullOrWhiteSpace($resourceType) -or
        [string]::IsNullOrWhiteSpace($resourceId) -or
        [string]::IsNullOrWhiteSpace($variable)
    ) {
        Write-Warning "Skipping invalid CSV row."
        continue
    }

    # -----------------------------------------------------
    # Create resource type
    # -----------------------------------------------------

    if (-not $data.Contains($resourceType)) {
        $data[$resourceType] = [ordered]@{}
    }

    # -----------------------------------------------------
    # Create resource ID
    # -----------------------------------------------------

    if (-not $data[$resourceType].Contains($resourceId)) {
        $data[$resourceType][$resourceId] = [ordered]@{}
    }

    # -----------------------------------------------------
    # Store variable/value
    # -----------------------------------------------------

    $data[$resourceType][$resourceId][$variable] = $value
}

# =========================================================
# 5. Terraform value conversion function
# =========================================================

function Convert-ToTerraformValue {

    param(
        [AllowNull()]
        [string]$Value,

        [string]$VariableName
    )

    # -----------------------------------------------------
    # Null
    # -----------------------------------------------------

    if ($null -eq $Value) {
        return "null"
    }

    $Value = $Value.Trim()

    # -----------------------------------------------------
    # Empty value
    # -----------------------------------------------------

    if ($Value -eq "") {
        return '""'
    }

    # -----------------------------------------------------
    # IMPORTANT:
    #
    # address_prefixes must ALWAYS be a list
    #
    # Example:
    #
    # 10.10.12.0/26
    #
    # becomes:
    #
    # ["10.10.12.0/26"]
    #
    # -----------------------------------------------------

    if ($VariableName -eq "address_prefixes") {

        $items = $Value -split "," |
        ForEach-Object {

            $item = $_.Trim()

            if ($item -ne "") {
                '"' + $item.Replace('\', '\\').Replace('"', '\"') + '"'
            }
        }

        return "[" + ($items -join ", ") + "]"
    }

    # -----------------------------------------------------
    # address_space must ALWAYS be a list
    # -----------------------------------------------------

    if ($VariableName -eq "address_space") {

        $items = $Value -split "," |
        ForEach-Object {

            $item = $_.Trim()

            if ($item -ne "") {
                '"' + $item.Replace('\', '\\').Replace('"', '\"') + '"'
            }
        }

        return "[" + ($items -join ", ") + "]"
    }

    # -----------------------------------------------------
    # Terraform boolean
    #
    # true
    # false
    # -----------------------------------------------------

    if ($Value -match '^(true|false)$') {
        return $Value.ToLower()
    }

    # -----------------------------------------------------
    # Terraform integer
    #
    # Example:
    # 100
    # 22
    # -----------------------------------------------------

    if ($Value -match '^-?\d+$') {
        return $Value
    }

    # -----------------------------------------------------
    # Terraform decimal
    #
    # Example:
    # 10.5
    # -----------------------------------------------------

    if ($Value -match '^-?\d+\.\d+$') {
        return $Value
    }

    # -----------------------------------------------------
    # Generic comma-separated list
    #
    # Example:
    #
    # value1,value2,value3
    #
    # becomes:
    #
    # ["value1", "value2", "value3"]
    # -----------------------------------------------------

    if ($Value.Contains(",")) {

        $items = $Value -split "," |
        ForEach-Object {

            $item = $_.Trim()

            if ($item -ne "") {
                '"' + $item.Replace('\', '\\').Replace('"', '\"') + '"'
            }
        }

        return "[" + ($items -join ", ") + "]"
    }

    # -----------------------------------------------------
    # Normal Terraform string
    # -----------------------------------------------------

    $escapedValue = $Value.
    Replace('\', '\\').
    Replace('"', '\"')

    return '"' + $escapedValue + '"'
}

# =========================================================
# 6. Generate Terraform HCL
# =========================================================

$output = New-Object System.Collections.Generic.List[string]

foreach ($resourceType in $data.Keys) {

    # -----------------------------------------------------
    # Resource type
    #
    # Example:
    #
    # subnet = {
    #
    # -----------------------------------------------------

    $output.Add("$resourceType = {")

    foreach ($resourceId in $data[$resourceType].Keys) {

        # -------------------------------------------------
        # Resource ID
        #
        # Example:
        #
        # subnet1 = {
        #
        # -------------------------------------------------

        $output.Add("  $resourceId = {")

        $properties = $data[$resourceType][$resourceId]

        foreach ($variable in $properties.Keys) {

            $terraformValue = Convert-ToTerraformValue `
                -Value $properties[$variable] `
                -VariableName $variable

            # -------------------------------------------------
            # Align Terraform variables
            # -------------------------------------------------

            $line = "    {0,-36} = {1}" -f `
                $variable,
            $terraformValue

            $output.Add($line)
        }

        $output.Add("  }")
    }

    $output.Add("}")
    $output.Add("")
}

# =========================================================
# 7. Write terraform.tfvars
# =========================================================

try {

    $output | Set-Content `
        -LiteralPath $OutputPath `
        -Encoding UTF8

}
catch {

    Write-Error "Failed to create terraform.tfvars"
    Write-Error $_.Exception.Message
    exit 1
}

# =========================================================
# 8. Success message
# =========================================================

Write-Host ""
Write-Host "============================================="
Write-Host "              SUCCESS"
Write-Host "============================================="
Write-Host ""

Write-Host "Terraform tfvars generated successfully."
Write-Host ""

try {
    $resolvedOutput = Resolve-Path -LiteralPath $OutputPath
    Write-Host "Output file:"
    Write-Host $resolvedOutput
}
catch {
    Write-Host "Output file: $OutputPath"
}

Write-Host ""
Write-Host "Next step:"
Write-Host "terraform fmt"
Write-Host "terraform validate"
Write-Host ""
