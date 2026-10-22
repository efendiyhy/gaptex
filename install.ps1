# Gaptex Windows Installer
# Installs Gaptex and, with explicit consent, its required desktop integration tool.
# For transparency, this implementation currently uses the Spicetify CLI.
$ErrorActionPreference = 'Stop'

$source = Join-Path $PSScriptRoot 'gaptex.js'
if (-not (Test-Path -LiteralPath $source)) {
    throw 'File gaptex.js tidak ditemukan. Ekstrak ZIP seluruhnya sebelum menginstal.'
}

Write-Host '================================'
Write-Host '        Gaptex Installer'
Write-Host '================================'

if (-not (Get-Command spicetify -ErrorAction SilentlyContinue)) {
    Write-Host ''
    Write-Host 'Gaptex membutuhkan komponen integrasi Spotify Desktop.'
    Write-Host 'Komponen pihak ketiga tersebut dapat dipasang dari Windows Package Manager.'
    $reply = Read-Host 'Izinkan installer mengunduh dan memasang komponen pendukung? (Y/N)'
    if ($reply -notmatch '^(?i:y|yes|ya)$') {
        throw 'Instalasi dibatalkan. Komponen pendukung diperlukan agar Gaptex dapat berjalan.'
    }

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'Windows Package Manager (winget) tidak ditemukan. Perbarui App Installer melalui Microsoft Store lalu coba lagi.'
    }

    & winget install --id Spicetify.Spicetify --exact --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw 'Pemasangan komponen pendukung gagal. Periksa keluaran winget, lalu ulangi instalasi.'
    }

    # WinGet may update the user PATH but not this PowerShell process.
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machinePath;$userPath;$env:Path"
}

if (-not (Get-Command spicetify -ErrorAction SilentlyContinue)) {
    throw 'Komponen pendukung belum terdeteksi. Tutup terminal, buka PowerShell baru, lalu jalankan kembali install.ps1.'
}

$destDir = Join-Path $env:APPDATA 'spicetify\Extensions'
$dest = Join-Path $destDir 'gaptex.js'
New-Item -ItemType Directory -Path $destDir -Force | Out-Null
Copy-Item -LiteralPath $source -Destination $dest -Force
Write-Host "File Gaptex disalin ke: $dest"

& spicetify config extensions gaptex.js
if ($LASTEXITCODE -ne 0) {
    throw 'Gagal mendaftarkan Gaptex. Pastikan Spotify Desktop pernah dibuka dan login.'
}

# backup apply handles first-time installs and re-applying after Spotify updates.
& spicetify backup apply
if ($LASTEXITCODE -ne 0) {
    throw 'Gagal menerapkan Gaptex. Pastikan Spotify Desktop kompatibel dan telah ditutup, lalu coba kembali.'
}

Write-Host ''
Write-Host 'Gaptex berhasil dipasang. Buka Spotify Desktop > Menu Profil > Gaptex.'
