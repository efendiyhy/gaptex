# Gaptex Online Installer for Windows / Spotify Desktop.
# Standalone: designed for `irm https://raw.githubusercontent.com/efendiyhy/gaptex/main/install-online.ps1 | iex`.
# Reads gaptex.js from the same public GitHub repository; never downloads arbitrary executable payloads.
# Installing the third-party Spicetify CLI (if needed) always requires the user's confirmation.

$ErrorActionPreference = 'Stop'

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'Installer online Gaptex ini khusus Windows. Untuk Linux/macOS, gunakan petunjuk instalasi manual.'
}

$repo = 'https://raw.githubusercontent.com/efendiyhy/gaptex/main'
$extensionUrl = "$repo/gaptex.js"
$extensionsDir = Join-Path $env:APPDATA 'spicetify\Extensions'
$destination = Join-Path $extensionsDir 'gaptex.js'
$tempFile = Join-Path ([IO.Path]::GetTempPath()) ('gaptex-' + [guid]::NewGuid().ToString('N') + '.js')

function Find-GaptexIntegration {
    $command = Get-Command spicetify -ErrorAction SilentlyContinue
    if ($command -and $command.Source) { return $command.Source }

    $paths = @(
        (Join-Path $env:USERPROFILE '.spicetify\spicetify.exe'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\spicetify.exe')
    )
    foreach ($path in $paths) {
        if (Test-Path -LiteralPath $path -PathType Leaf) { return $path }
    }
    return $null
}

Write-Host ''
Write-Host '====================================='
Write-Host '        Gaptex Online Installer'
Write-Host '====================================='
Write-Host 'Sumber: https://github.com/efendiyhy/gaptex'
Write-Host 'Mengunduh modul Gaptex...'

try {
    # Windows PowerShell 5.1 on older installations may not default to TLS 1.2.
    if ($PSVersionTable.PSVersion.Major -le 5) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    }
    Invoke-WebRequest -Uri $extensionUrl -OutFile $tempFile -UseBasicParsing -ErrorAction Stop
    $file = Get-Item -LiteralPath $tempFile
    if ($file.Length -lt 1000 -or (Get-Content -LiteralPath $tempFile -TotalCount 1) -ne '// NAME: Gaptex') {
        throw 'File ekstensi dari GitHub tidak valid. Instalasi dibatalkan.'
    }

    $integration = Find-GaptexIntegration
    if (-not $integration) {
        Write-Host ''
        Write-Host 'Gaptex memerlukan komponen integrasi desktop pihak ketiga (Spicetify CLI).'
        Write-Host 'Jika Anda setuju, Windows Package Manager akan memasangnya dari sumber yang terdaftar.'
        $reply = Read-Host 'Pasang komponen pendukung sekarang? (Y/N)'
        if ($reply -notmatch '^(?i:y|yes|ya)$') {
            throw 'Instalasi dibatalkan. Komponen integrasi diperlukan untuk menjalankan Gaptex.'
        }
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            throw 'winget tidak ditemukan. Pasang Windows App Installer, atau pasang Spicetify CLI lebih dulu.'
        }
        & winget install --id Spicetify.Spicetify --exact --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            throw 'Pemasangan komponen integrasi gagal. Periksa pesan winget, lalu coba kembali.'
        }

        # Update environment inside the current PowerShell process after winget changes PATH.
        $env:Path = @(
            [Environment]::GetEnvironmentVariable('Path', 'Machine'),
            [Environment]::GetEnvironmentVariable('Path', 'User'),
            $env:Path
        ) -join ';'
        $integration = Find-GaptexIntegration
        if (-not $integration) {
            throw 'Komponen pendukung belum ditemukan pada sesi ini. Buka PowerShell baru lalu jalankan perintah Gaptex lagi.'
        }
    }

    New-Item -ItemType Directory -Path $extensionsDir -Force | Out-Null
    Copy-Item -LiteralPath $tempFile -Destination $destination -Force
    Write-Host 'Mendaftarkan Gaptex di Spotify Desktop...'

    & $integration config extensions gaptex.js
    if ($LASTEXITCODE -ne 0) {
        throw 'Pendaftaran Gaptex gagal. Buka Spotify dan login setidaknya sekali, lalu ulangi instalasi.'
    }

    & $integration backup apply
    if ($LASTEXITCODE -ne 0) {
        throw 'Penerapan Gaptex gagal. Tutup Spotify, lalu jalankan perintah instalasi lagi.'
    }

    Write-Host ''
    Write-Host 'Gaptex berhasil dipasang!' -ForegroundColor Green
    Write-Host 'Buka Spotify Desktop > menu profil > Gaptex.'
    Write-Host 'Catatan: fitur masih prototipe. Efektivitas pemblokiran iklan tidak dijamin.'
}
finally {
    if (Test-Path -LiteralPath $tempFile) {
        Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
    }
}
