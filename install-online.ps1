# Gaptex one-command installer for Windows.
# Version: 0.1.4 (activation diagnostic / backup repair hotfix)
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
    param(
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )
    # External applications may write normal status messages to stderr.
    # On Windows PowerShell 5.1, *>> with ErrorActionPreference=Stop can
    # terminate the installer with NativeCommandError before checking exit code.
    # Capture native process streams separately and check the actual exit code.
    $script:GaptexLastOutput = ''
    $unique = [guid]::NewGuid().ToString('N')
    $stdout = Join-Path $logDir ("gaptex-out-$unique.tmp")
    $stderr = Join-Path $logDir ("gaptex-err-$unique.tmp")
    $cmd = [IO.Path]::GetFileName($Executable)
    Add-Content -LiteralPath $log -Value ("`r`n[{0}] {1} {2}" -f (Get-Date -Format s), $cmd, ($Arguments -join ' '))
    try {
        # All current CLI arguments are simple tokens without embedded spaces.
        $process = Start-Process -FilePath $Executable -ArgumentList $Arguments `
            -NoNewWindow -Wait -PassThru `
            -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        foreach ($path in @($stdout, $stderr)) {
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                $output = [IO.File]::ReadAllText($path)
                if ($output.Length -gt 0) {
                    $script:GaptexLastOutput += $output + [Environment]::NewLine
                    [IO.File]::AppendAllText($log, $output + [Environment]::NewLine)
                }
            }
        }
        Add-Content -LiteralPath $log -Value ("Exit code: {0}" -f $process.ExitCode)
        # A known version-mismatch error can appear with exit code 0 in some builds.
        $versionMismatch = $script:GaptexLastOutput -match '(?i)Spotify version mismatch|Spotify version is not supported'
        if ($versionMismatch) {
            Add-Content -LiteralPath $log -Value 'Gaptex: detected Spotify compatibility error in process output.'
        }
        return (($process.ExitCode -eq 0) -and -not $versionMismatch)
    }
    catch {
        $script:GaptexLastOutput = $_.Exception.Message
        Add-Content -LiteralPath $log -Value ("Process launch failed: {0}" -f $_.Exception.Message)
        Write-Warning "Proses integrasi desktop gagal. Periksa log: $log"
        return $false
    }
    finally {
        Remove-Item -LiteralPath $stdout, $stderr -Force -ErrorAction SilentlyContinue
    }
}

function Stop-GaptexSpotify {
    # Close Spotify before the CLI applies changes to its local installation.
    $running = @(Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue)
    if ($running.Count -eq 0) {
        Add-Content -LiteralPath $log -Value 'Spotify was already closed.'
        return
    }

    Write-Host 'Menutup Spotify Desktop secara otomatis...'
    Add-Content -LiteralPath $log -Value ("Closing Spotify processes: {0}" -f (($running | ForEach-Object { $_.Id }) -join ', '))

    foreach ($process in $running) {
        try {
            Stop-Process -Id $process.Id -Force -ErrorAction Stop
        }
        catch {
            # The process may have exited on its own between Get- and Stop-Process.
            if (Get-Process -Id $process.Id -ErrorAction SilentlyContinue) {
                throw "Gaptex tidak bisa menutup Spotify (PID $($process.Id)). Tutup Spotify lewat Task Manager, kemudian coba lagi. Detail: $($_.Exception.Message)"
            }
        }
    }

    # Wait until all Spotify processes have actually exited before applying.
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        if (-not (Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue)) {
            Add-Content -LiteralPath $log -Value 'Spotify closed successfully.'
            Write-Host 'Spotify sudah ditutup.'
            return
        }
        Start-Sleep -Milliseconds 250
    }

    throw 'Spotify masih berjalan setelah 10 detik. Hentikan dari Task Manager kemudian ulangi instalasi Gaptex.'
}

Write-Host ''
Write-Host '================================='
Write-Host '         Gaptex Installer'
Write-Host '            v0.1.4'
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
    Stop-GaptexSpotify
    $activated = Invoke-GaptexTool -Executable $runtime -Arguments @('apply')
    if (-not $activated) {
        if ($script:GaptexLastOutput -match '(?i)Spotify version mismatch|Spotify version is not supported') {
            Write-Warning 'Versi Spotify belum kompatibel dengan komponen integrasi terpasang.'
        }
        else {
            # First-time installation may need an initial backup.
            Write-Host 'Aktivasi awal gagal; memeriksa kondisi backup...' -ForegroundColor Yellow
            $activated = Invoke-GaptexTool -Executable $runtime -Arguments @('backup', 'apply')
            $backupOutput = $script:GaptexLastOutput

            # Only offer repair for the documented stale-backup case.
            # Do not automatically overwrite existing Spotify modifications.
            if (-not $activated -and
                $backupOutput -match '(?i)Please restore first then backup|After clearing backup|Before clearing backup') {
                Write-Warning 'Backup Spotify lama ditemukan dan tidak dapat dibuat ulang langsung.'
                Write-Host 'Perbaikan akan memulihkan berkas Spotify ke kondisi asal lalu menerapkan konfigurasi ekstensi yang terdaftar.'
                Write-Host 'Perubahan pada file Spotify dari alat lain mungkin akan terganti.'
                $answer = Read-Host 'Izinkan pemulihan backup otomatis? (Y/N)'
                if ($answer -match '^(?i:y|yes|ya)$') {
                    Stop-GaptexSpotify
                    $activated = Invoke-GaptexTool -Executable $runtime -Arguments @('restore', 'backup', 'apply')
                }
            }
        }
    }

    if (-not $activated) {
        Write-Host ''
        Write-Host 'Ringkasan log aktivasi terakhir:' -ForegroundColor Yellow
        if (Test-Path -LiteralPath $log -PathType Leaf) {
            Get-Content -LiteralPath $log -Tail 35 | ForEach-Object { Write-Host $_ }
        }
        throw "Gaptex belum berhasil diaktifkan. Lihat penyebab sebenarnya pada log: $log"
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
