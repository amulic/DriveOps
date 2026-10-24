<#
.SYNOPSIS
    Re-establishes adb reverse tunnels so a physical Android device can reach
    the laptop's backend services via localhost over USB.

.DESCRIPTION
    Maps device localhost -> host localhost for:
      8081  Keycloak
      5032  DriveOps REST API
      5033  DriveOps Realtime (SignalR)

    These mappings live in adbd on the phone and are wiped whenever the device
    sleeps, USB re-enumerates, or adbd restarts. Re-run this script whenever the
    app can no longer reach the backend (e.g. "Failed to connect to
    localhost/127.0.0.1:8081").

    Pair with:  flutter run --dart-define=API_HOST=localhost

.PARAMETER Serial
    Optional device serial. If omitted, the single connected device is used.

.EXAMPLE
    pwsh tool/adb_reverse.ps1
    pwsh tool/adb_reverse.ps1 -Serial 5tmvxsp7kzpborqs
#>
param([string]$Serial)

$ErrorActionPreference = 'Stop'

$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (-not (Test-Path $adb)) { $adb = 'adb' }

if (-not $Serial) {
    $devices = @(& $adb devices | Where-Object { $_ -match "`tdevice$" })
    if ($devices.Count -eq 0) {
        Write-Error 'No authorized device found. Plug in the phone and accept the USB debugging prompt.'
        exit 1
    }
    if ($devices.Count -gt 1) {
        Write-Error "Multiple devices found. Re-run with -Serial <id>:`n$($devices -join "`n")"
        exit 1
    }
    $Serial = ($devices[0] -split "`t")[0].Trim()
}

$ports = 8081, 5032, 5033

& $adb -s $Serial reverse --remove-all
foreach ($p in $ports) {
    & $adb -s $Serial reverse "tcp:$p" "tcp:$p" | Out-Null
}

Write-Host "adb reverse tunnels active for $Serial :" -ForegroundColor Green
& $adb -s $Serial reverse --list
