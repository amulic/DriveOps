# Adds the 'customer' realm role to the 'default-roles-driveops-dev' composite on a RUNNING
# Keycloak instance. Run ONCE — from then on, Keycloak automatically grants 'customer' to
# every new self-registered user at registration time (no per-user action needed).
# Idempotent — safe to re-run.
#
# Usage:
#   pwsh add-customer-default-role.ps1
#   pwsh add-customer-default-role.ps1 -BaseUrl http://localhost:8081 -Realm driveops-dev
#
# For FRESH installs (docker compose down -v), the realm JSON already contains the
# default-roles-driveops-dev composite with 'customer' included.
#
# NOTE: the admin token is obtained from the MASTER realm (same pattern as
# enable-backend-service-account.ps1) — the realm-imported 'admin' user of driveops-dev
# lacks realm-management permissions.
#
# Secrets are NOT stored in this file. The admin password is read from the
# KC_BOOTSTRAP_ADMIN_PASSWORD environment variable (or pass -AdminPassword).

param(
    [string]$BaseUrl = "http://localhost:8081",
    [string]$Realm = "driveops-dev",
    [string]$AdminRealm = "master",
    [string]$AdminUsername = "admin",
    [string]$AdminPassword = $env:KC_BOOTSTRAP_ADMIN_PASSWORD,
    [string]$CustomerRoleName = "customer"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

if (-not $AdminPassword) {
    throw "AdminPassword not provided. Set the KC_BOOTSTRAP_ADMIN_PASSWORD environment variable (or pass -AdminPassword)."
}

Write-Host "== DriveOps: add '$CustomerRoleName' to default roles on $BaseUrl (realm $Realm) =="

# 1. Obtain an admin token (password grant on admin-cli against the master realm).
try {
    $body = "grant_type=password&client_id=admin-cli&username=$([uri]::EscapeDataString($AdminUsername))&password=$([uri]::EscapeDataString($AdminPassword))"
    $adminToken = (Invoke-RestMethod -Method Post -Uri "$BaseUrl/realms/$AdminRealm/protocol/openid-connect/token" `
            -ContentType "application/x-www-form-urlencoded" -Body $body).access_token
} catch {
    throw "Failed to obtain admin token for '$AdminUsername' on realm '$AdminRealm'. Is Keycloak running at $BaseUrl? ($($_.Exception.Message))"
}
Write-Host "[1/4] Admin token acquired."

$headers = @{ Authorization = "Bearer $adminToken" }
$defaultRoleName = "default-roles-$Realm"

# 2. Resolve the 'customer' realm role.
$customerRole = Invoke-RestMethod -Method Get -Uri "$BaseUrl/admin/realms/$Realm/roles/$CustomerRoleName" -Headers $headers
Write-Host "[2/4] Role '$CustomerRoleName' found ($($customerRole.id))."

# 3. Check whether it is already part of the default-roles composite.
# NOTE: do NOT wrap Invoke-RestMethod in @() here — it returns the collection as a single
# object, so @() would nest it and break per-item enumeration. Pipe the result instead.
$composites = Invoke-RestMethod -Method Get -Uri "$BaseUrl/admin/realms/$Realm/roles/$defaultRoleName/composites" -Headers $headers
$alreadyDefault = @($composites | Where-Object { $_.name -eq $CustomerRoleName -and -not $_.clientRole }).Count -gt 0
if ($alreadyDefault) {
    Write-Host "[3/4] '$CustomerRoleName' is already a default role — nothing to do."
} else {
    # -InputObject (not piping) preserves the single-element array as JSON `[{...}]`;
    # piping one object into ConvertTo-Json would emit a scalar and Keycloak rejects it.
    $json = ConvertTo-Json -InputObject @($customerRole) -Depth 10
    Invoke-RestMethod -Method Post -Uri "$BaseUrl/admin/realms/$Realm/roles/$defaultRoleName/composites" `
        -Headers $headers -ContentType "application/json" -Body $json | Out-Null
    Write-Host "[3/4] Added '$CustomerRoleName' to '$defaultRoleName'."
}

# 4. Self-test: re-read the composites and confirm.
$verify = Invoke-RestMethod -Method Get -Uri "$BaseUrl/admin/realms/$Realm/roles/$defaultRoleName/composites" -Headers $headers
$hasCustomer = @($verify | Where-Object { $_.name -eq $CustomerRoleName -and -not $_.clientRole }).Count -gt 0
if (-not $hasCustomer) {
    throw "Self-test failed: '$CustomerRoleName' is not in '$defaultRoleName' after the update."
}
$names = @($verify | ForEach-Object { $_.name }) -join ', '
Write-Host "[4/4] Self-test passed. Default roles now: $names."
Write-Host "== Done. Every new self-registered user will automatically receive the '$CustomerRoleName' role. =="
