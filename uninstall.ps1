# Gaptex uninstaller. Leaves any shared third-party integration tool installed.
$ErrorActionPreference = 'Stop'
$runtime = Get-Command spicetify -ErrorAction SilentlyContinue
if (-not $runtime) {
    $candidate = Join-Path $env:USERPROFILE '.spicetify\spicetify.exe'
    if (Test-Path -LiteralPath $candidate) { $runtime = @{ Source = $candidate } }
}
if (-not $runtime) {
    throw 'Komponen integrasi desktop tidak ditemukan. Gaptex mungkin sudah tidak aktif.'
}
$logDir = Join-Path $env:LOCALAPPDATA 'Gaptex\logs'
New-Item -Path $logDir -ItemType Directory -Force | Out-Null
$log = Join-Path $logDir 'uninstall.log'
& $runtime.Source config extensions 'gaptex.js-' *>> $log
if ($LASTEXITCODE -ne 0) { throw "Gagal melepas Gaptex dari konfigurasi. Log: $log" }
$dest = Join-Path $env:APPDATA 'spicetify\Extensions\gaptex.js'
if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Force }
& $runtime.Source apply *>> $log
if ($LASTEXITCODE -ne 0) { throw "Gaptex sudah dilepas, tetapi perubahan belum dapat diterapkan. Log: $log" }
Write-Host 'Gaptex berhasil dihapus. Komponen integrasi bersama tidak dihapus.' -ForegroundColor Green
