# Gaptex offline installer for Windows.
# Notices for required third-party integration: docs/THIRD_PARTY_NOTICES.md.
$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot 'gaptex.js'
if (-not (Test-Path -LiteralPath $source)) {
    throw 'gaptex.js tidak ditemukan. Ekstrak seluruh ZIP sebelum instalasi.'
}
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'Gaptex Installer ini hanya mendukung Windows.'
}
$logDir = Join-Path $env:LOCALAPPDATA 'Gaptex\logs'
$log = Join-Path $logDir 'install.log'
New-Item -Path $logDir -ItemType Directory -Force | Out-Null

function Find-GaptexRuntime {
    $exe = Get-Command spicetify -ErrorAction SilentlyContinue
    if ($exe -and $exe.Source) { return $exe.Source }
    foreach ($candidate in @(
        (Join-Path $env:USERPROFILE '.spicetify\spicetify.exe'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\spicetify.exe')
    )) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    return $null
}
function Invoke-GaptexTool {
    param([string]$Executable, [string[]]$Arguments)
    & $Executable @Arguments *>> $log
    return ($LASTEXITCODE -eq 0)
}

Write-Host ''
Write-Host '================================='
Write-Host '         Gaptex Installer'
Write-Host '================================='
Write-Host '[1/3] Memeriksa komponen integrasi...'
$runtime = Find-GaptexRuntime
if (-not $runtime) {
    Write-Host 'Gaptex memerlukan komponen integrasi desktop pihak ketiga yang bersifat open-source.'
    Write-Host 'Komponen ini mempunyai lisensi sendiri dan akan dipasang melalui Windows Package Manager.'
    Write-Host 'Rincian komponen: https://github.com/efendiyhy/gaptex/blob/main/docs/THIRD_PARTY_NOTICES.md'
    $reply = Read-Host 'Izinkan pemasangan komponen pendukung? (Y/N)'
    if ($reply -notmatch '^(?i:y|yes|ya)$') { throw 'Instalasi dibatalkan oleh pengguna.' }
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) { throw 'Windows Package Manager tidak tersedia. Perbarui App Installer melalui Microsoft Store.' }
    if (-not (Invoke-GaptexTool -Executable $winget.Source -Arguments @(
        'install', '--id', 'Spicetify.Spicetify', '--exact', '--silent',
        '--accept-package-agreements', '--accept-source-agreements'
    ))) { throw "Pemasangan komponen pendukung gagal. Lihat log: $log" }
    $env:Path = @(
        [Environment]::GetEnvironmentVariable('Path', 'Machine'),
        [Environment]::GetEnvironmentVariable('Path', 'User'),
        $env:Path
    ) -join ';'
    $runtime = Find-GaptexRuntime
    if (-not $runtime) { throw 'Buka PowerShell baru, lalu ulangi instalasi Gaptex.' }
}

Write-Host '[2/3] Menyiapkan Gaptex...'
$destDir = Join-Path $env:APPDATA 'spicetify\Extensions'
$dest = Join-Path $destDir 'gaptex.js'
New-Item -Path $destDir -ItemType Directory -Force | Out-Null
Copy-Item -LiteralPath $source -Destination $dest -Force
if (-not (Invoke-GaptexTool -Executable $runtime -Arguments @('config', 'extensions', 'gaptex.js'))) {
    throw "Gagal mendaftarkan Gaptex. Lihat log: $log"
}
Write-Host '[3/3] Mengaktifkan Gaptex...'
if (-not (Invoke-GaptexTool -Executable $runtime -Arguments @('apply'))) {
    if (-not (Invoke-GaptexTool -Executable $runtime -Arguments @('backup', 'apply'))) {
        throw "Gagal mengaktifkan Gaptex. Tutup Spotify, lalu jalankan ulang installer. Lihat log: $log"
    }
}
Write-Host ''
Write-Host 'Gaptex berhasil dipasang!' -ForegroundColor Green
Write-Host 'Buka kembali Spotify Desktop > menu profil > Gaptex.'
