<#
.SYNOPSIS
    One-command SANDBOX launcher for the full DriveOps stack (test-mode Stripe only).

.DESCRIPTION
    End-to-end, idempotent startup for local testing on any dev machine:

      1. Prereq check (docker, dotnet, flutter, stripe CLI, adb)
      2. Sandbox guard (only pk_test_/sk_test_ keys are accepted)
      3. Stripe secret key -> .NET user-secrets (one-time per machine, then reused)
      4. docker compose up -d (MySQL, Keycloak, RabbitMQ, Adminer)
      5. stripe listen spawned in its own window; the printed whsec_... is
         captured from its log and pushed into user-secrets BEFORE the API starts
         (PaymentServiceOptions.WebhookSecret is read once at API startup)
      6. DriveOpsAPI (:5032) + DriveOpsRealtime (:5033) started in separate windows
      7. adb reverse tunnels (8081/5032/5033) for a physical Android device
      8. flutter run for the mobile app (--dart-define-from-file=stripe_keys.json)
         and optionally the management desktop app

    Everything Stripe is TEST mode. Use the sandbox cards:
      4242 4242 4242 4242  success
      4000 0027 6000 3184  3DS
      4000 0000 0000 9995  decline -> exercises the in-app retry flow

    First run on a fresh machine:
      pwsh scripts/start-sandbox.ps1 -StripeSecretKey sk_test_...
    (also run `stripe login` once beforehand if the CLI isn't authenticated yet)

    Later runs:  pwsh scripts/start-sandbox.ps1

.PARAMETER StripeSecretKey
    sk_test_... for the sandbox account. Persisted to .NET user-secrets on first
    run; optional afterwards.

.PARAMETER PhoneSerial
    adb serial of the Android device. Required only when multiple devices are
    connected (USB and/or wireless adb).

.PARAMETER SkipMobile / SkipDesktop
    Don't launch the mobile / desktop Flutter app.

.EXAMPLE
    pwsh scripts/start-sandbox.ps1 -StripeSecretKey sk_test_abc123
.EXAMPLE
    pwsh scripts/start-sandbox.ps1
.EXAMPLE
    pwsh scripts/start-sandbox.ps1 -PhoneSerial 5tmvxsp7kzpborqs -SkipDesktop
#>
param(
    [string]$StripeSecretKey,
    [string]$PhoneSerial,
    [switch]$SkipMobile,
    [switch]$SkipDesktop
)

$ErrorActionPreference = 'Stop'
$root        = Split-Path $PSScriptRoot -Parent
$apiProject  = Join-Path $root 'DriveOpsAPI\DriveOps'
$rtProject   = Join-Path $root 'DriveOpsRealtime\DriveOpsRealtime'
$composeFile = Join-Path $root 'DriveOpsAPI\docker-compose.yml'
$mobileDir   = Join-Path $root 'driveops_mobile'
$mgmtDir     = Join-Path $root 'driveops_management'
$keysFile    = Join-Path $mobileDir 'stripe_keys.json'
$adbReverse  = Join-Path $mobileDir 'tool\adb_reverse.ps1'
$sandboxDir  = Join-Path $root '.sandbox'
$stripeLog   = Join-Path $sandboxDir 'stripe-listen.log'

function Write-Step([string]$msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Wait-Port([int]$Port, [string]$Name, [int]$TimeoutSec = 90) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
        try {
            $c = New-Object System.Net.Sockets.TcpClient
            $c.Connect('localhost', $Port); $c.Close()
            Write-Host "  $Name up on :$Port" -ForegroundColor DarkGray
            return
        } catch { Start-Sleep -Milliseconds 500 }
    }
    throw "Timed out waiting for $Name on port $Port"
}
function Wait-HttpOk([string]$Url, [int]$TimeoutSec = 180) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
        try {
            $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
            if ($r.StatusCode -eq 200) { return }
        } catch { Start-Sleep -Seconds 2 }
    }
    throw "Timed out waiting for $Url"
}

# ---------- 1. Prereqs ----------
Write-Step 'Checking prerequisites'
foreach ($cmd in 'docker', 'dotnet', 'flutter', 'stripe') {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        throw "'$cmd' not found on PATH. Install it first (stripe CLI: winget install Stripe.StripeCLI)."
    }
}
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (-not (Test-Path $adb)) { $adb = 'adb' }
Write-Host '  docker / dotnet / flutter / stripe / adb OK' -ForegroundColor DarkGray

# ---------- 2. Sandbox guard ----------
if (-not (Test-Path $keysFile)) {
    throw "$keysFile missing. Create it with: { `"STRIPE_PUBLISHABLE_KEY`": `"pk_test_...`" }"
}
$pubKey = (Get-Content $keysFile -Raw | ConvertFrom-Json).STRIPE_PUBLISHABLE_KEY
if ($pubKey -notmatch '^pk_test_') { throw "stripe_keys.json must hold a TEST publishable key (pk_test_...). Live keys are refused." }
if ($StripeSecretKey -and $StripeSecretKey -notmatch '^sk_test_') { throw 'Only TEST secret keys (sk_test_...) are accepted in the sandbox launcher.' }

# ---------- 3. Stripe secret key -> user-secrets (one-time per machine) ----------
Write-Step 'Stripe secret key'
if ($StripeSecretKey) {
    dotnet user-secrets set 'Stripe:SecretKey' $StripeSecretKey --project $apiProject | Out-Null
    Write-Host '  saved to .NET user-secrets' -ForegroundColor DarkGray
} else {
    $existing = dotnet user-secrets list --project $apiProject 2>$null |
        Where-Object { $_ -match '^Stripe:SecretKey\s*=\s*\S+' }
    if (-not $existing) {
        throw "No Stripe:SecretKey in user-secrets. Re-run once with: -StripeSecretKey sk_test_..."
    }
    Write-Host '  already in .NET user-secrets' -ForegroundColor DarkGray
}

# ---------- 4. No stale backends (an old API would hold an outdated whsec) ----------
foreach ($p in 5032, 5033) {
    if (Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue) {
        throw "Port $p is already in use. Stop the running backend first (its Stripe webhook secret would be stale)."
    }
}

# ---------- 5. Infra ----------
Write-Step 'Starting infrastructure (docker compose)'
docker compose -f $composeFile up -d | Out-Null
Wait-Port 3306 'MySQL'
Wait-Port 5672 'RabbitMQ'
Wait-Port 8081 'Keycloak' -TimeoutSec 180
try {
    # The port opens before the realm import finishes; apps must not launch until login actually works.
    Wait-HttpOk 'http://localhost:8081/realms/driveops-dev' -TimeoutSec 180
    Write-Host '  driveops-dev realm imported and ready' -ForegroundColor DarkGray
} catch {
    throw "Keycloak did not finish importing the driveops-dev realm. Check 'docker logs keycloak'. $_"
}

# ---------- 6. Stripe listen + auto whsec ----------
Write-Step 'Starting stripe listen (capturing webhook secret)'
Get-Process stripe -ErrorAction SilentlyContinue | Stop-Process -Force
New-Item -ItemType Directory -Force -Path $sandboxDir | Out-Null
if (Test-Path $stripeLog) { Remove-Item $stripeLog -Force }

Start-Process pwsh -ArgumentList @(
    '-NoExit', '-Command',
    "stripe listen --events `"payment_intent.succeeded,payment_intent.payment_failed`" --forward-to localhost:5032/api/payment/webhook 2>&1 | Tee-Object -FilePath `"$stripeLog`""
) | Out-Null

$whsec = $null
$sw = [Diagnostics.Stopwatch]::StartNew()
while ($sw.Elapsed.TotalSeconds -lt 30 -and -not $whsec) {
    Start-Sleep -Milliseconds 500
    if (Test-Path $stripeLog) {
        $log = Get-Content $stripeLog -Raw
        if ($log -match '(whsec_[A-Za-z0-9]+)') { $whsec = $Matches[1] }
        elseif ($log -match 'stripe login|not authenticated|Invalid API key') {
            throw 'stripe CLI is not authenticated. Run "stripe login" once, then re-run this script.'
        }
    }
}
if (-not $whsec) { throw "No whsec_... appeared in $stripeLog within 30s. Check the stripe listen window." }
dotnet user-secrets set 'Stripe:WebhookSecret' $whsec --project $apiProject | Out-Null
Write-Host "  webhook secret captured and saved ($($whsec.Substring(0,12))...)" -ForegroundColor DarkGray

# ---------- 7. Backends (AFTER the whsec is in user-secrets) ----------
# Sequential on purpose: both projects transitively build DriveOps.RealTime.Contracts
# into the same obj/ folder; launching them concurrently races on that DLL (CS2012 file lock).
Write-Step 'Starting DriveOpsAPI (:5032)'
Start-Process pwsh -ArgumentList @('-NoExit', '-Command', "dotnet run --project `"$apiProject`"") | Out-Null
Wait-HttpOk 'http://localhost:5032/api/test/public'
Write-Host '  API responding on :5032' -ForegroundColor DarkGray

Write-Step 'Starting DriveOpsRealtime (:5033)'
Start-Process pwsh -ArgumentList @('-NoExit', '-Command', "dotnet run --project `"$rtProject`"") | Out-Null
Wait-HttpOk 'http://localhost:5033/api/chat/debug'
Write-Host '  Realtime responding on :5033' -ForegroundColor DarkGray

# ---------- 8. adb reverse tunnels ----------
Write-Step 'Configuring adb reverse tunnels'
$deviceLines = @(& $adb devices | Where-Object { $_ -match "`tdevice$" })
if ($deviceLines.Count -eq 0) {
    Write-Warning 'No adb device connected - skipping tunnels and mobile launch. Connect the phone (USB or wireless adb) and re-run tool/adb_reverse.ps1.'
} else {
    if ($deviceLines.Count -gt 1 -and -not $PhoneSerial) {
        throw "Multiple adb devices found. Re-run with -PhoneSerial <id>:`n$($deviceLines -join "`n")"
    }
    if (-not $PhoneSerial) { $PhoneSerial = ($deviceLines[0] -split "`t")[0].Trim() }
    & $adbReverse -Serial $PhoneSerial
}

# ---------- 9. Flutter apps ----------
if (-not $SkipMobile -and $deviceLines.Count -gt 0) {
    Write-Step "Launching mobile app on $PhoneSerial"
    Start-Process pwsh -ArgumentList @(
        '-NoExit', '-Command',
        "Set-Location `"$mobileDir`"; flutter run --dart-define-from-file=stripe_keys.json --dart-define=API_HOST=localhost -d $PhoneSerial"
    ) | Out-Null
}
if (-not $SkipDesktop) {
    Write-Step 'Launching management desktop app'
    Start-Process pwsh -ArgumentList @(
        '-NoExit', '-Command',
        "Set-Location `"$mgmtDir`"; flutter run -d windows"
    ) | Out-Null
}

# ---------- Summary ----------
Write-Host @"

===================  SANDBOX READY  ===================
API :5032 | Realtime :5033 | Keycloak :8081 | RabbitMQ :5672 (UI :15672) | Adminer :8089

Seed logins (password = username):
  admin/admin, dispatcher/dispatcher (management)
  marcusjohnson, sarahwilliams, davidchen, emilyrodriguez, jamesbrown (drivers)
  johndoe, janesmith, bobwilson (customers)

Stripe TEST cards:
  4242 4242 4242 4242   success
  4000 0027 6000 3184   3DS
  4000 0000 0000 9995   decline -> retry flow (needs the webhook, which is live)

Webhook log: $stripeLog
Stop: close the spawned windows, then 'docker compose -f "$composeFile" down'.
========================================================
"@ -ForegroundColor Green
