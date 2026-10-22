# Gaptex installer for Windows / Spicetify
# Run from the extracted ZIP directory. Does not download anything.
$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot 'gaptex.js'
$destDir = Join-Path $env:APPDATA 'spicetify\Extensions'
$dest = Join-Path $destDir 'gaptex.js'
if (-not (Test-Path -LiteralPath $source)) { throw 'gaptex.js tidak ditemukan di direktori installer.' }
if (-not (Get-Command spicetify -ErrorAction SilentlyContinue)) {
    throw 'Spicetify CLI belum terpasang atau belum ada dalam PATH. Lihat README.md.'
}
New-Item -ItemType Directory -Path $destDir -Force | Out-Null
Copy-Item -LiteralPath $source -Destination $dest -Force
Write-Host "Gaptex copied to: $dest"
& spicetify config extensions gaptex.js
if ($LASTEXITCODE -ne 0) { throw 'Gagal mengaktifkan Gaptex via Spicetify config.' }
& spicetify apply
if ($LASTEXITCODE -ne 0) { throw 'Spicetify apply gagal. Jalankan: spicetify backup apply' }
Write-Host 'Gaptex terpasang. Buka Spotify dan lihat menu profil > Gaptex.'
