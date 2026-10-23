# Gaptex installer v0.3.0. Requires real Spicetify CLI, does not bundle its binary.
$ErrorActionPreference = 'Stop'
$Version = '0.3.0'
$logFolder = Join-Path $env:LOCALAPPDATA 'Gaptex\logs'
$logFile = Join-Path $logFolder 'install.log'
New-Item -ItemType Directory -Path $logFolder -Force | Out-Null

function Add-Log([string]$message) {
    Add-Content -LiteralPath $logFile -Encoding UTF8 -Value ('[{0}] {1}' -f (Get-Date -Format s), $message)
}
function Say([string]$line, [ConsoleColor]$color = [ConsoleColor]::Green) {
    Write-Host $line -ForegroundColor $color
}
function Banner {
    try { Clear-Host } catch {}
    Say '           /\_/\' Cyan
    Say '          ( o.o )    GAPTEX' Magenta
    Say '           > ^ <     WINDOWS' Yellow
    Write-Host ''
    $font = @{
        'E'=@('####','#...','###.','#...','####');
        'K'=@('#..#','#.#.','##..','#.#.','#..#');
        'I'=@('###','.#.','.#.','.#.','###');
        'N'=@('#..#','##.#','#.##','#..#','#..#');
        'S'=@('.###','#...','.##.','...#','###.');
        'T'=@('#####','..#..','..#..','..#..','..#..');
        'R'=@('###.','#..#','###.','#.#.','#..#');
        'U'=@('#..#','#..#','#..#','#..#','.##.');
        'M'=@('#...#','##.##','#.#.#','#...#','#...#');
        'A'=@('.##.','#..#','####','#..#','#..#');
        'O'=@('.##.','#..#','#..#','#..#','.##.');
    }
    $colors=@('Green','Cyan','Magenta','Yellow','Blue')
    $phrases=@('EK','INSTRUMENTATION')
    $width=80
    try { $width=$Host.UI.RawUI.WindowSize.Width } catch {}
    if ($width -lt 84) { $phrases=@('EK','INSTRU','MENTATION') }
    foreach ($phrase in $phrases) {
        for ($row=0; $row -lt 5; $row++) {
            $line=''
            foreach ($letter in $phrase.ToCharArray()) {
                $line += ($font[[string]$letter][$row] -replace '\.', ' ') + ' '
            }
            Say ('  ' + $line.TrimEnd()) $colors[$row]
        }
        Write-Host ''
    }
    Say '  ==========================================' DarkGreen
    Say "  Gaptex v$Version" White
    Write-Host ''
}
function Find-Spicetify {
    # Prefer official installer location over stale executables earlier on PATH.
    $officialPath = Join-Path $env:LOCALAPPDATA 'spicetify\spicetify.exe'
    if (Test-Path -LiteralPath $officialPath -PathType Leaf) { return $officialPath }
    $cmd = Get-Command spicetify.exe -ErrorAction SilentlyContinue
    if ($cmd -and (Test-Path -LiteralPath $cmd.Source -PathType Leaf)) { return $cmd.Source }
    $possible = @(
        (Join-Path $env:LOCALAPPDATA 'spicetify\spicetify.exe'),
        (Join-Path $env:USERPROFILE '.spicetify\spicetify.exe'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\spicetify.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Spicetify\spicetify.exe')
    )
    foreach ($path in $possible) {
        if (Test-Path -LiteralPath $path -PathType Leaf) { return $path }
    }
    return $null
}
function Invoke-Native {
    param([Parameter(Mandatory)][string]$Exe,[string[]]$Arguments = @(),[int]$TimeoutSeconds = 180)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Exe
    # All arguments passed here are known ASCII, no whitespace or quoting required.
    $psi.Arguments = $Arguments -join ' '
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = New-Object System.Text.UTF8Encoding($false)
    $psi.StandardErrorEncoding = New-Object System.Text.UTF8Encoding($false)
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    [void]$process.Start()
    # Read both streams asynchronously to prevent deadlocks.
    $outTask = $process.StandardOutput.ReadToEndAsync()
    $errTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        try { $process.Kill() } catch {}
        throw "Perintah terlalu lama: $($Arguments -join ' ')"
    }
    [void][Threading.Tasks.Task]::WaitAll([Threading.Tasks.Task[]]@($outTask, $errTask), 15000)
    $text = [regex]::Replace(($outTask.Result + "`n" + $errTask.Result), ([string][char]27 + '\[[0-9;?]*[ -/]*[@-~]'), '')
    $text = $text.Trim()
    $result = [pscustomobject]@{ Code = [int]$process.ExitCode; Text = [string]$text }
    Add-Log ("RUN: {0} {1}`n{2}`nEXIT: {3}" -f [IO.Path]::GetFileName($Exe), ($Arguments -join ' '), $text, $result.Code)
    return $result
}
function Stop-Spotify {
    $running = @(Get-Process -Name Spotify -ErrorAction SilentlyContinue)
    if ($running.Count -eq 0) { return }
    Say '[*] Menutup Spotify sebelum aktivasi...' Yellow
    foreach ($p in $running) {
        try { Stop-Process -Id $p.Id -Force -ErrorAction Stop }
        catch { throw "Tidak dapat menutup Spotify: $($_.Exception.Message)" }
    }
    for ($i = 0; $i -lt 40; $i++) {
        if (-not (Get-Process -Name Spotify -ErrorAction SilentlyContinue)) { return }
        Start-Sleep -Milliseconds 250
    }
    throw 'Spotify belum berhenti. Tutup melalui Task Manager.'
}
function Install-OfficialSpicetify {
    Say '[*] Memasang Spicetify CLI resmi (LGPL-2.1)...' Cyan
    Say '    Sumber: https://github.com/spicetify/cli' DarkGray
    $answer = Read-Host '    Lanjutkan pemasangan komponen ini? (Y/N)'
    if ($answer -notmatch '^(y|yes|ya)$') { throw 'Pemasangan dibatalkan.' }
    $official = Join-Path $env:TEMP ('spicetify-official-' + [guid]::NewGuid().ToString('N') + '.ps1')
    try {
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/spicetify/cli/main/install.ps1' -UseBasicParsing -OutFile $official
        # Official installer is run as its own script and can update PATH on disk.
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = 'powershell.exe'
        $psi.Arguments = ('-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $official)
        $psi.UseShellExecute = $false
        $proc = [System.Diagnostics.Process]::Start($psi)
        $proc.WaitForExit()
        if ($proc.ExitCode -ne 0) { throw "Installer resmi gagal (exit $($proc.ExitCode))." }
    } finally {
        Remove-Item -LiteralPath $official -Force -ErrorAction SilentlyContinue
    }
}
function Explain-Failure([string]$message) {
    Say ''
    Say '[!] AKTIVASI BELUM BERHASIL' Red
    if ($message -match '(?i)cannot be backed up at this state|failed to backup app files|please re-install spotify') {
        Say 'Instalasi Spotify sekarang tidak dapat dibackup.' Yellow
        Write-Host 'Perbaikan yang diperlukan:'
        Write-Host '  1. Uninstall Spotify Desktop melalui Settings > Apps.'
        Write-Host '  2. Install ulang dari https://www.spotify.com/download/windows/'
        Write-Host '  3. Buka Spotify, login, biarkan terbuka sekitar 60 detik.'
        Write-Host '  4. Tutup Spotify dan jalankan kembali installer Gaptex.'
        Write-Host 'Installer tidak akan menghapus Spotify secara otomatis.'
    } elseif ($message -match '(?i)restore first|backup is available|preprocessed') {
        Say 'Backup lama perlu dipulihkan terlebih dahulu.' Yellow
        Write-Host 'Periksa panduan pemulihan di docs/TROUBLESHOOTING.md.'
    } elseif ($message -match '(?i)not supported|version mismatch') {
        Say 'Versi Spotify mungkin belum kompatibel dengan Spicetify CLI.' Yellow
        Write-Host 'Periksa pembaruan CLI dan Spotify Desktop.'
    } else {
        Write-Host 'Detail utama:'
        Write-Host (($message -split "`n" | Select-Object -Last 10) -join "`n")
    }
    Say "Log: $logFile" DarkGray
}

try {
    Banner
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Hanya Windows 10/11 yang didukung.' }
    if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'gaptex.js'))) { throw 'File gaptex.js tidak ditemukan.' }
    Add-Log '=== GAPTEX v0.3.0 START ==='
    Say '[1/5] Memeriksa Spotify Desktop...' Cyan
    $spotifyPrefs = Join-Path $env:APPDATA 'Spotify\prefs'
    if (-not (Test-Path -LiteralPath $spotifyPrefs)) {
        Say 'Spotify belum membuat file prefs.' Yellow
        throw 'Pasang Spotify dari https://www.spotify.com/download/windows/, buka dan login sekitar 60 detik dahulu.'
    }
    Say '[2/5] Memeriksa Spicetify CLI resmi...' Cyan
    $cli = Find-Spicetify
    if (-not $cli) {
        Install-OfficialSpicetify
        $cli = Find-Spicetify
        if (-not $cli) { throw 'Spicetify sudah dipasang tetapi executable tidak ditemukan. Buka PowerShell baru, lalu ulangi.' }
    }
    $version = Invoke-Native -Exe $cli -Arguments @('-v')
    if ($version.Code -ne 0) { throw "Spicetify CLI gagal dijalankan: $($version.Text)" }
    Say ("     " + (($version.Text -split "`n")[0])) DarkGray
    # The v2.46.1/2 releases fix extension support on newer Spotify builds.
    try {
        $latestRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/spicetify/cli/releases/latest' -TimeoutSec 12
        $latestText = [string]$latestRelease.tag_name
        $installedMatch = [regex]::Match($version.Text, 'v?(\d+\.\d+\.\d+)')
        if ($installedMatch.Success -and $latestText -match '^v?(\d+\.\d+\.\d+)$') {
            $installedVersion = [version]$installedMatch.Groups[1].Value
            $latestVersion = [version]$Matches[1]
            if ($installedVersion -lt $latestVersion) {
                Say ("[*] Memperbarui Spicetify CLI: $installedVersion -> $latestVersion") Yellow
                $update = Invoke-Native -Exe $cli -Arguments @('update') -TimeoutSeconds 240
                if ($update.Code -ne 0) {
                    Say 'Pembaruan otomatis belum berhasil. Periksa petunjuk Spicetify resmi.' Yellow
                    Add-Log ('UPDATE FAILURE: ' + $update.Text)
                } else {
                    $cli = Find-Spicetify
                    $version = Invoke-Native -Exe $cli -Arguments @('-v')
                }
            }
        }
    } catch {
        Add-Log ('Could not check Spicetify updates: ' + $_.Exception.Message)
    }
    Say '[3/5] Menyiapkan modul Gaptex...' Cyan
    $extDir = Join-Path $env:APPDATA 'spicetify\Extensions'
    New-Item -ItemType Directory -Force -Path $extDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'gaptex.js') -Destination (Join-Path $extDir 'gaptex.js') -Force
    $configure = Invoke-Native -Exe $cli -Arguments @('config','extensions','gaptex.js')
    if ($configure.Code -ne 0) { throw "Gagal mendaftarkan ekstensi: $($configure.Text)" }
    Say '[4/5] Menerapkan ekstensi ke Spotify...' Cyan
    Stop-Spotify
    $apply = Invoke-Native -Exe $cli -Arguments @('apply','--no-restart')
    if ($apply.Code -ne 0) {
        if ($apply.Text -match '(?i)cannot be backed up at this state|failed to backup app files|please re-install spotify') {
            Explain-Failure $apply.Text
            throw 'Spotify memerlukan instalasi ulang sebelum Gaptex dapat diaktifkan.'
        }
        if ($apply.Text -match '(?i)restore first|backup is available|preprocessed') {
            Say 'Backup lama terdeteksi. Konfigurasi ekstensi tidak dihapus.' Yellow
            Explain-Failure $apply.Text
            throw 'Backup lama perlu diperbaiki secara manual.'
        }
        $backup = Invoke-Native -Exe $cli -Arguments @('backup','apply','--no-restart')
        if ($backup.Code -ne 0) {
            Explain-Failure $backup.Text
            throw 'Spicetify gagal mengaktifkan Gaptex.'
        }
    }
    Say '[5/5] Selesai.' Cyan
    Say ''
    Say '   GAPTEX BERHASIL DIAKTIFKAN' Green
    Say '   Buka Spotify > foto profil kanan atas > Gaptex.' White
    Say "   Log: $logFile" DarkGray
    Add-Log 'SUCCESS'
} catch {
    Add-Log ('FAILED: ' + $_.Exception.Message)
    Say ('[!] ' + $_.Exception.Message) Red
    Say "Log: $logFile" DarkGray
    throw
}
