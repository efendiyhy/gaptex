# Remove only Gaptex. Leave Spotify and Spicetify available for other extensions.
$ErrorActionPreference = 'Stop'
$ext = Join-Path $env:APPDATA 'spicetify\Extensions\gaptex.js'
$cli = (Get-Command spicetify.exe -ErrorAction SilentlyContinue).Source
if (-not $cli) {
    $candidate = Join-Path $env:LOCALAPPDATA 'spicetify\spicetify.exe'
    if (Test-Path -LiteralPath $candidate) { $cli = $candidate }
}
if ($cli) {
    & $cli config extensions gaptex.js- | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'Gagal melepas konfigurasi Gaptex.' }
}
if (Test-Path -LiteralPath $ext) { Remove-Item -LiteralPath $ext -Force }
if ($cli) {
    Get-Process -Name Spotify -ErrorAction SilentlyContinue | Stop-Process -Force
    & $cli apply | Out-Host
    if ($LASTEXITCODE -ne 0) { Write-Warning 'Gaptex telah dilepas, tetapi penerapan ulang Spotify belum berhasil.' }
}
Write-Host 'Gaptex dihapus. Komponen integrasi dan Spotify tetap terpasang.' -ForegroundColor Green
