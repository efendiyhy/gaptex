# Gaptex one-command installer for Windows.
# Source: https://github.com/efendiyhy/gaptex
# Dependency attribution: docs/THIRD_PARTY_NOTICES.md in this repository.
# Run: irm https://raw.githubusercontent.com/efendiyhy/gaptex/main/install-online.ps1 | iex

$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'Gaptex Installer ini hanya mendukung Windows.'
}

$repo = 'https://raw.githubusercontent.com/efendiyhy/gaptex/main'
$extensionUrl = "$repo/gaptex.js"
$extensionDir = Join-Path $env:APPDATA 'spicetify\Extensions'
$destination = Join-Path $extensionDir 'gaptex.js'
$tempFile = Join-Path ([IO.Path]::GetTempPath()) ('gaptex-' + [guid]::NewGuid().ToString('N') + '.js')
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
Write-Host '[1/4] Mengunduh modul Gaptex...'

try {
    if ($PSVersionTable.PSVersion.Major -le 5) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }
    Invoke-WebRequest -Uri $extensionUrl -OutFile $tempFile -UseBasicParsing
    if ((Get-Item -LiteralPath $tempFile).Length -lt 1000 -or
        (Get-Content -LiteralPath $tempFile -TotalCount 1) -ne '// NAME: Gaptex') {
        throw 'Berkas ekstensi tidak valid. Instalasi dibatalkan.'
    }

    Write-Host '[2/4] Memeriksa komponen integrasi...'
    $runtime = Find-GaptexRuntime
    if (-not $runtime) {
        Write-Host 'Gaptex memerlukan komponen integrasi desktop pihak ketiga yang bersifat open-source.'
        Write-Host 'Komponen ini dipasang melalui Windows Package Manager dan memiliki lisensi tersendiri.'
        Write-Host 'Rincian komponen dan lisensi: https://github.com/efendiyhy/gaptex/blob/main/docs/THIRD_PARTY_NOTICES.md'
        $reply = Read-Host 'Izinkan pemasangan komponen pendukung? (Y/N)'
        if ($reply -notmatch '^(?i:y|yes|ya)$') {
            throw 'Instalasi dibatalkan oleh pengguna.'
        }
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $winget) { throw 'Windows Package Manager belum tersedia. Perbarui App Installer melalui Microsoft Store.' }
        Write-Host 'Memasang komponen pendukung...'
        if (-not (Invoke-GaptexTool -Executable $winget.Source -Arguments @(
            'install', '--id', 'Spicetify.Spicetify', '--exact', '--silent',
            '--accept-package-agreements', '--accept-source-agreements'
        ))) {
            throw "Komponen pendukung gagal dipasang. Lihat log: $log"
        }
        $env:Path = @(
            [Environment]::GetEnvironmentVariable('Path', 'Machine'),
            [Environment]::GetEnvironmentVariable('Path', 'User'),
            $env:Path
        ) -join ';'
        $runtime = Find-GaptexRuntime
        if (-not $runtime) {
            throw 'Komponen pendukung telah dipasang tetapi belum terdeteksi. Buka PowerShell baru dan jalankan installer lagi.'
        }
    }

    Write-Host '[3/4] Menyiapkan Gaptex...'
    New-Item -Path $extensionDir -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $tempFile -Destination $destination -Force

    if (-not (Invoke-GaptexTool -Executable $runtime -Arguments @('config', 'extensions', 'gaptex.js'))) {
        throw "Gaptex gagal didaftarkan. Pastikan Spotify sudah pernah dibuka dan login. Lihat log: $log"
    }

    Write-Host '[4/4] Mengaktifkan Gaptex...'
    if (-not (Invoke-GaptexTool -Executable $runtime -Arguments @('apply'))) {
        # First-time setup may need an initial backup; never clear an existing one.
        if (-not (Invoke-GaptexTool -Executable $runtime -Arguments @('backup', 'apply'))) {
            throw "Aktivasi belum berhasil. Tutup Spotify sepenuhnya lalu jalankan installer lagi. Log: $log"
        }
    }

    Write-Host ''
    Write-Host 'Gaptex berhasil dipasang!' -ForegroundColor Green
    Write-Host 'Buka kembali Spotify Desktop, lalu klik menu profil untuk menemukan Gaptex.'
    Write-Host 'Catatan: keberhasilan pemasangan bukan jaminan setiap fitur cocok dengan versi Spotify Anda.'
}
finally {
    if (Test-Path -LiteralPath $tempFile) {
        Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
    }
}
