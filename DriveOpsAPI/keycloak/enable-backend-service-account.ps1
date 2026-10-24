# Enables the driveops-backend service account on a RUNNING Keycloak instance and grants it
# the realm-management roles needed by the DriveOpsAPI KeycloakAdminService
# (view-users + manage-users). Idempotent — safe to re-run.
#
# Usage:
#   pwsh enable-backend-service-account.ps1
#   pwsh enable-backend-service-account.ps1 -BaseUrl http://localhost:8081 -Realm driveops-dev
#
# For FRESH installs (docker compose down -v), the realm JSON already contains
# these settings (serviceAccountsEnabled + serviceAccountsClientRoles).
#
# NOTE: the admin token is obtained from the MASTER realm (KC_BOOTSTRAP_ADMIN_USERNAME/PASSWORD
# in docker-compose.yml). The realm-imported 'admin' user of driveops-dev is a plain realm role
# without realm-management permissions and gets 403 on admin REST calls.

param(
    [string]$BaseUrl = "http://localhost:8081",
    [string]$Realm = "driveops-dev",
    [string]$AdminRealm = "master",
    [string]$AdminUsername = "admin",
    [string]$AdminPassword = "admin",
    [string]$BackendClientId = "driveops-backend",
    [string]$BackendClientSecret = "driveops-backend-secret-dev"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Get-AdminToken {
    param([string]$Username, [string]$Password)
    $body = "grant_type=password&client_id=admin-cli&username=$([uri]::EscapeDataString($Username))&password=$([uri]::EscapeDataString($Password))"
    $response = Invoke-RestMethod -Method Post -Uri "$BaseUrl/realms/$AdminRealm/protocol/openid-connect/token" `
        -ContentType "application/x-www-form-urlencoded" -Body $body
    return $response.access_token
}

function Invoke-AdminGet {
    param([string]$Token, [string]$Path)
    return Invoke-RestMethod -Method Get -Uri "$BaseUrl/admin/realms/$Realm/$Path" `
        -Headers @{ Authorization = "Bearer $Token" }
}

function Invoke-AdminPut {
    param([string]$Token, [string]$Path, [psobject]$Body)
    $json = $Body | ConvertTo-Json -Depth 20
    Invoke-RestMethod -Method Put -Uri "$BaseUrl/admin/realms/$Realm/$Path" `
        -Headers @{ Authorization = "Bearer $Token" } -ContentType "application/json" -Body $json | Out-Null
}

function Invoke-AdminPost {
    param([string]$Token, [string]$Path, [psobject]$Body)
    $json = $Body | ConvertTo-Json -Depth 20
    Invoke-RestMethod -Method Post -Uri "$BaseUrl/admin/realms/$Realm/$Path" `
        -Headers @{ Authorization = "Bearer $Token" } -ContentType "application/json" -Body $json | Out-Null
}

Write-Host "== DriveOps: enable backend service account on $BaseUrl (realm $Realm) =="

# 1. Obtain an admin token (password grant on admin-cli against the master realm).
try {
    $adminToken = Get-AdminToken -Username $AdminUsername -Password $AdminPassword
} catch {
    throw "Failed to obtain admin token for '$AdminUsername' on realm '$AdminRealm'. Is Keycloak running at $BaseUrl? ($($_.Exception.Message))"
}
Write-Host "[1/5] Admin token acquired."

# 2. Locate the driveops-backend client, enable service accounts (idempotent).
$clients = Invoke-AdminGet -Token $adminToken -Path "clients?clientId=$BackendClientId"
if (-not $clients -or $clients.Count -eq 0) {
    throw "Client '$BackendClientId' not found in realm '$Realm'."
}
$clientId = $clients[0].id
$client = Invoke-AdminGet -Token $adminToken -Path "clients/$clientId"
if ($client.serviceAccountsEnabled -ne $true) {
    $client.serviceAccountsEnabled = $true
    Invoke-AdminPut -Token $adminToken -Path "clients/$clientId" -Body $client
    Write-Host "[2/5] Service accounts enabled for client '$BackendClientId'."
} else {
    Write-Host "[2/5] Service accounts already enabled for client '$BackendClientId'."
}

# 3. Find the service account user (created/managed by Keycloak when service accounts are on).
$serviceAccountUsername = "service-account-$BackendClientId"
$users = Invoke-AdminGet -Token $adminToken -Path "users?username=$serviceAccountUsername&exact=true"
if (-not $users -or $users.Count -eq 0) {
    throw "Service account user '$serviceAccountUsername' not found. Try restarting Keycloak or re-running this script."
}
$serviceAccountUserId = $users[0].id
Write-Host "[3/5] Service account user found ($serviceAccountUserId)."

# 4. Grant realm-management view-users + manage-users (idempotent).
$realmMgmtClients = Invoke-AdminGet -Token $adminToken -Path "clients?clientId=realm-management"
if (-not $realmMgmtClients -or $realmMgmtClients.Count -eq 0) {
    throw "'realm-management' client not found in realm '$Realm'."
}
$realmMgmtClientId = $realmMgmtClients[0].id

$assignedRoles = @(Invoke-AdminGet -Token $adminToken -Path "users/$serviceAccountUserId/role-mappings/clients/$realmMgmtClientId")
$rolesToAssign = @()
foreach ($roleName in @("view-users", "manage-users")) {
    if ($assignedRoles | Where-Object { $_.name -eq $roleName }) {
        Write-Host "      Role '$roleName' already assigned."
        continue
    }
    $role = Invoke-AdminGet -Token $adminToken -Path "clients/$realmMgmtClientId/roles/$roleName"
    $rolesToAssign += $role
}
if ($rolesToAssign.Count -gt 0) {
    Invoke-AdminPost -Token $adminToken -Path "users/$serviceAccountUserId/role-mappings/clients/$realmMgmtClientId" -Body $rolesToAssign
    Write-Host "[4/5] Granted: $(($rolesToAssign | ForEach-Object { $_.name }) -join ', ')."
} else {
    Write-Host "[4/5] realm-management roles already in place."
}

# 5. Self-test: client-credentials token for the backend client + a view-users admin call.
$ccBody = "grant_type=client_credentials&client_id=$([uri]::EscapeDataString($BackendClientId))&client_secret=$([uri]::EscapeDataString($BackendClientSecret))"
$ccToken = (Invoke-RestMethod -Method Post -Uri "$BaseUrl/realms/$Realm/protocol/openid-connect/token" `
        -ContentType "application/x-www-form-urlencoded" -Body $ccBody).access_token
$probe = Invoke-RestMethod -Method Get -Uri "$BaseUrl/admin/realms/$Realm/users?username=$serviceAccountUsername&exact=true" `
    -Headers @{ Authorization = "Bearer $ccToken" }
Write-Host "[5/5] Self-test passed: service-account token can search users ($(@($probe).Count) result(s))."
Write-Host "== Done. DriveOpsAPI can now manage driver roles via its KeycloakAdminService. =="
