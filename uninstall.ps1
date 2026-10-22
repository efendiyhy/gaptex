# Gaptex uninstaller for Windows / Spicetify
$ErrorActionPreference = 'Stop'
if (-not (Get-Command spicetify -ErrorAction SilentlyContinue)) {
    throw 'Spicetify CLI tidak ditemukan dalam PATH.'
}
& spicetify config extensions 'gaptex.js-'
if ($LASTEXITCODE -ne 0) { throw 'Gagal menghapus konfigurasi extension.' }
$dest = Join-Path $env:APPDATA 'spicetify\Extensions\gaptex.js'
if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Force }
& spicetify apply
if ($LASTEXITCODE -ne 0) { throw 'Spicetify apply gagal.' }
Write-Host 'Gaptex berhasil dihapus dari Spicetify.'
