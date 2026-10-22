# Gaptex Installer v0.1.6 - Windows PowerShell 5.1+ (local or online)
# Runtime attribution: docs/THIRD_PARTY_NOTICES.md
$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'Gaptex saat ini hanya mendukung Windows.'
}
$Version = '0.1.6'
$Repo = 'https://github.com/efendiyhy/gaptex'
$source = Join-Path $PSScriptRoot 'gaptex.js'
$logDir = Join-Path $env:LOCALAPPDATA 'Gaptex\logs'
$log = Join-Path $logDir 'install.log'
New-Item -Path $logDir -ItemType Directory -Force | Out-Null
$script:LastOutput = ''
$script:LastExitCode = -1
$script:LastFailureCategory = ''

function Write-GaptexText {
    param([string]$Value, [ConsoleColor]$Color = [ConsoleColor]::Green)
    Write-Host $Value -ForegroundColor $Color
}

function Show-GaptexSplash {
    # Clear the PowerShell host to display the banner cleanly.
    try { Clear-Host } catch { }
    $colors = @('Cyan','Green','Magenta','Yellow','Blue','DarkCyan','White')
    Write-GaptexText '    .--------------------------------------------------------------.' ([ConsoleColor]::DarkGreen)
    Write-GaptexText '    |   [::] GAPTEX SYSTEM INITIALIZATION  //  WINDOWS TERMINAL    |' ([ConsoleColor]::Green)
    Write-GaptexText '    ''--------------------------------------------------------------''' ([ConsoleColor]::DarkGreen)
    Write-GaptexText '             /\_/\\' ([ConsoleColor]::Cyan)
    Write-GaptexText '            ( o.o )   [ CAT PROTOCOL : ONLINE ]' ([ConsoleColor]::Magenta)
    Write-GaptexText '             > ^ <' ([ConsoleColor]::Yellow)
    Write-Host ''
    # Compact 5x7 pixel glyphs: big, legible, monospaced ASCII lettering.
    $glyph = @{
        'E' = @('#####','#....','#....','####.','#....','#....','#####')
        'K' = @('#...#','#..#.','#.#..','##...','#.#..','#..#.','#...#')
        'I' = @('#####','..#..','..#..','..#..','..#..','..#..','#####')
        'N' = @('#...#','##..#','#.#.#','#..##','#...#','#...#','#...#')
        'S' = @('.####','#....','#....','.###.','....#','....#','####.')
        'T' = @('#####','..#..','..#..','..#..','..#..','..#..','..#..')
        'R' = @('####.','#...#','#...#','####.','#.#..','#..#.','#...#')
        'U' = @('#...#','#...#','#...#','#...#','#...#','#...#','.###.')
        'M' = @('#...#','##.##','#.#.#','#...#','#...#','#...#','#...#')
        'A' = @('.###.','#...#','#...#','#####','#...#','#...#','#...#')
        'O' = @('.###.','#...#','#...#','#...#','#...#','#...#','.###.')
    }
    $terminalWidth = 120
    try { $terminalWidth = $Host.UI.RawUI.WindowSize.Width } catch { }
    $phrases = if ($terminalWidth -lt 115) { @('EK','INSTRU','MENTATION') } else { @('EK','INSTRUMENTATION') }
    foreach ($phrase in $phrases) {
        for ($row = 0; $row -lt 7; $row++) {
            $line = ''
            foreach ($char in $phrase.ToCharArray()) {
                if ($glyph.ContainsKey([string]$char)) {
                    $line += (($glyph[[string]$char][$row] -replace '\.',' ') + '  ')
                }
            }
            Write-Host ('  ' + $line.TrimEnd()) -ForegroundColor $colors[$row % $colors.Count]
        }
        Write-Host ''
    }
    Write-GaptexText ('  [GAPTEX {0}]  >> READY TO DEPLOY <<' -f $Version) ([ConsoleColor]::Green)
    Write-GaptexText ('  Repository: ' + $Repo) ([ConsoleColor]::DarkCyan)
    Write-GaptexText ('  ===========================================================') ([ConsoleColor]::DarkGreen)
    Write-Host ''
}

function Add-GaptexLog {
    param([string]$Line)
    Add-Content -LiteralPath $log -Value ('[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Line) -Encoding UTF8
}

function Find-GaptexRuntime {
    $cmd = Get-Command spicetify -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source -PathType Leaf)) { return $cmd.Source }
    foreach ($candidate in @(
        (Join-Path $env:USERPROFILE '.spicetify\spicetify.exe'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\spicetify.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Spicetify\spicetify.exe')
    )) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    return $null
}

function ConvertTo-GaptexPlainOutput {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '' }
    # Some native CLI versions emit byte streams that get decoded as UTF-16.
    # Example: `嬛洱灳捩瑥晩` represents ANSI escape bytes + `spicetify`.
    if ($Text -match '[\u3400-\u9FFF]') {
        try {
            $fixed = [Text.Encoding]::UTF8.GetString([Text.Encoding]::Unicode.GetBytes($Text))
            if ($fixed -match '(?i)spicetify|spotify|error|warning|info|backup') {
                $Text = $fixed
            }
        } catch { }
    }
    # Strip terminal ANSI colors from saved diagnostics.
    $Text = [regex]::Replace($Text, [string][char]27 + '\[[0-9;?]*[ -/]*[@-~]', '')
    return $Text.TrimEnd([char]0)
}

function Invoke-GaptexCommand {
    param([Parameter(Mandatory)][string]$Executable,
          [string[]]$Arguments = @())
    $script:LastOutput = ''
    $script:LastExitCode = -1
    $nonce = [guid]::NewGuid().ToString('N')
    $outFile = Join-Path $logDir ("out-$nonce.tmp")
    $errFile = Join-Path $logDir ("err-$nonce.tmp")
    Add-GaptexLog ("RUN: {0} {1}" -f [IO.Path]::GetFileName($Executable), ($Arguments -join ' '))
    try {
        # Separate native stdout/stderr to avoid Windows PowerShell 5.1 NativeCommandError.
        $options = @{
            FilePath = $Executable
            Wait = $true
            PassThru = $true
            NoNewWindow = $true
            RedirectStandardOutput = $outFile
            RedirectStandardError = $errFile
            ErrorAction = 'Stop'
        }
        if ($Arguments.Count -gt 0) { $options.ArgumentList = $Arguments }
        $process = Start-Process @options
        $script:LastExitCode = $process.ExitCode
        foreach ($file in @($outFile,$errFile)) {
            if (Test-Path -LiteralPath $file -PathType Leaf) {
                $value = ConvertTo-GaptexPlainOutput ([IO.File]::ReadAllText($file))
                if ($value) {
                    $script:LastOutput += $value + [Environment]::NewLine
                    [IO.File]::AppendAllText($log, $value + [Environment]::NewLine)
                }
            }
        }
        Add-GaptexLog ("ExitCode: $script:LastExitCode")
        # Some versions output compatibility errors despite returning exit code 0.
        if ($script:LastOutput -match '(?i)Spotify version mismatch|Spotify version is not supported') {
            Add-GaptexLog 'ERROR: Spotify version mismatch detected in tool output.'
            return $false
        }
        return ($script:LastExitCode -eq 0)
    }
    catch {
        $script:LastOutput = $_.Exception.Message
        Add-GaptexLog ("EXECUTION FAILURE: $script:LastOutput")
        return $false
    }
    finally {
        Remove-Item -LiteralPath $outFile,$errFile -Force -ErrorAction SilentlyContinue
    }
}

function Stop-GaptexSpotify {
    $running = @(Get-Process -Name Spotify -ErrorAction SilentlyContinue)
    if ($running.Count -eq 0) { Add-GaptexLog 'Spotify already closed.'; return }
    Write-GaptexText '  [*] Menutup Spotify sebelum aktivasi...' ([ConsoleColor]::Yellow)
    foreach ($proc in $running) {
        try { Stop-Process -Id $proc.Id -Force -ErrorAction Stop }
        catch {
            if (Get-Process -Id $proc.Id -ErrorAction SilentlyContinue) {
                throw "Gagal menghentikan Spotify (PID $($proc.Id)): $($_.Exception.Message)"
            }
        }
    }
    for ($i = 0; $i -lt 40; $i++) {
        if (-not (Get-Process -Name Spotify -ErrorAction SilentlyContinue)) {
            Add-GaptexLog 'Spotify stopped successfully.'
            return
        }
        Start-Sleep -Milliseconds 250
    }
    throw 'Spotify tetap berjalan setelah 10 detik. Cek Task Manager.'
}

function Show-GaptexDiagnostic {
    Write-Host ''
    Write-GaptexText '  [!] AKTIVASI BELUM BERHASIL' ([ConsoleColor]::Red)
    $out = $script:LastOutput
    if ($script:LastFailureCategory -eq 'spotify-dirty' -or $out -match '(?i)cannot be backed up at this state|Failed to backup app files|Please re-install Spotify') {
        Write-GaptexText '  Penyebab: file instalasi Spotify tidak dalam kondisi yang dapat dibackup.' ([ConsoleColor]::Yellow)
        Write-Host '  Solusi: reinstall Spotify Desktop resmi (tanpa menghapus akun/playlist).'
        Write-Host '    1. Windows Settings > Apps > Installed apps > Spotify > Uninstall.'
        Write-Host '    2. Pasang ulang dari https://www.spotify.com/download/windows/'
        Write-Host '    3. Jalankan Spotify, login, biarkan terbuka sekurangnya 60 detik.'
        Write-Host '    4. Tutup Spotify sepenuhnya dan jalankan ulang installer Gaptex.'
        Write-Host '  Catatan: unduhan lagu offline mungkin perlu diunduh ulang.'
    } elseif ($out -match '(?i)Spotify version mismatch|Spotify version is not supported') {
        Write-GaptexText '  Penyebab: versi Spotify dan komponen integrasi tidak kompatibel.' ([ConsoleColor]::Yellow)
        Write-GaptexText '  Periksa versi Spotify dan pembaruan komponen pendukung.' ([ConsoleColor]::Yellow)
    } elseif ($out -match '(?i)cannot find pref|prefs.path|prefs file|Spotify installation path not found') {
        Write-GaptexText '  Penyebab: konfigurasi Spotify tidak ditemukan. Buka Spotify dan login dahulu.' ([ConsoleColor]::Yellow)
    } elseif ($out -match '(?i)access is denied|permission denied|administrator privileges') {
        Write-GaptexText '  Penyebab: akses tulis ditolak. Periksa izin folder instalasi Spotify.' ([ConsoleColor]::Yellow)
    } elseif ($out -match '(?i)Please restore first then backup|After clearing backup|Preprocessed Spotify data is outdated') {
        Write-GaptexText '  Penyebab: cadangan Spotify perlu diperbarui/dipulihkan.' ([ConsoleColor]::Yellow)
    } else {
        Write-GaptexText '  Penyebab spesifik belum diketahui dari pesan singkat; periksa log.' ([ConsoleColor]::Yellow)
    }
    Write-Host ''
    Write-GaptexText '  --- RINGKASAN LOG TERAKHIR ---' ([ConsoleColor]::Cyan)
    if (Test-Path -LiteralPath $log -PathType Leaf) {
        Get-Content -LiteralPath $log -Tail 35 | ForEach-Object { Write-Host ('  ' + $_) }
    }
    Write-Host ''
    Write-GaptexText ("  Log lengkap: $log") ([ConsoleColor]::Cyan)
}

function Request-GaptexRestore {
    Write-GaptexText '  [!] Cadangan Spotify perlu dipulihkan agar aktivasi dilanjutkan.' ([ConsoleColor]::Yellow)
    Write-Host '      Tindakan ini dapat menimpa modifikasi Spotify dari alat lain.'
    Write-Host '      Pengaturan ekstensi Gaptex tidak akan dihapus.'
    $permission = Read-Host '      Izinkan pemulihan dan penerapan ulang? (Y/N)'
    return ($permission -match '^(?i:y|yes|ya)$')
}

function Enable-Gaptex {
    param([string]$Runtime)
    # 1. Applying is the least disruptive action for existing installations.
    if (Invoke-GaptexCommand -Executable $Runtime -Arguments @('apply','--no-restart')) { return $true }
    $firstFailure = $script:LastOutput
    Add-GaptexLog ('First apply unsuccessful. Output: ' + ($firstFailure -replace '[\r\n]+',' | '))
    # This state requires clean Spotify installation. Retrying backup/apply
    # cannot make it healthy and only creates confusing repeated errors.
    if ($firstFailure -match '(?i)cannot be backed up at this state|Failed to backup app files|Please re-install Spotify') {
        $script:LastFailureCategory = 'spotify-dirty'
        Add-GaptexLog 'DIRTY_SPOTIFY: clean reinstall required; stopping automatic backup retries.'
        return $false
    }
    if ($firstFailure -match '(?i)Spotify version mismatch|Spotify version is not supported') {
        return $false
    }
    # 2. Stock / first-time Spotify: make a backup and apply once.
    $backupMissing = $firstFailure -match '(?i)haven.t backed up|no backup|backup is not available|run .spicetify backup apply.|backup not found'
    if ($backupMissing) {
        Write-GaptexText '  [*] Aktivasi awal membutuhkan persiapan tambahan...' ([ConsoleColor]::Yellow)
        if (Invoke-GaptexCommand -Executable $Runtime -Arguments @('backup','apply','--no-restart')) { return $true }
        $secondFailure = $script:LastOutput
        if ($secondFailure -match '(?i)cannot be backed up at this state|Failed to backup app files|Please re-install Spotify') {
            $script:LastFailureCategory = 'spotify-dirty'
            Add-GaptexLog 'DIRTY_SPOTIFY: reinstall required; cannot create a valid backup.'
            return $false
        }
        if ($secondFailure -match '(?i)Spotify version mismatch|Spotify version is not supported') { return $false }
        if ($secondFailure -match '(?i)Please restore first then backup|After clearing backup|Preprocessed Spotify data is outdated') {
            if (Request-GaptexRestore) {
                Stop-GaptexSpotify
                return (Invoke-GaptexCommand -Executable $Runtime -Arguments @('restore','backup','apply','--no-restart'))
            }
        }
        return $false
    }
    # 3. Stale backup and version mismatches need informed consent.
    if ($firstFailure -match '(?i)Preprocessed Spotify data is outdated|Spotify version and backup version are mismatched|Please restore first then backup|After clearing backup') {
        if (Request-GaptexRestore) {
            Stop-GaptexSpotify
            return (Invoke-GaptexCommand -Executable $Runtime -Arguments @('restore','backup','apply','--no-restart'))
        }
        return $false
    }
    # Unknown failure: keep files and print actual tool output; no destructive retry.
    return $false
}

Show-GaptexSplash
$script:LastFailureCategory = ''
Add-GaptexLog "===== START GAPTEX INSTALL v$Version ====="
try {
    Write-GaptexText '  [1/5] Validasi paket Gaptex...' ([ConsoleColor]::Cyan)
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw 'gaptex.js tidak ditemukan. Ekstrak seluruh ZIP sebelum memasang Gaptex.'
    }
    $firstLine = Get-Content -LiteralPath $source -TotalCount 1
    if ($firstLine -ne '// NAME: Gaptex' -or (Get-Item -LiteralPath $source).Length -lt 1000) {
        throw 'File gaptex.js tidak valid, instalasi dibatalkan.'
    }

    Write-GaptexText '  [2/5] Memeriksa integrasi desktop...' ([ConsoleColor]::Cyan)
    $runtime = Find-GaptexRuntime
    if (-not $runtime) {
        Write-Host '      Gaptex menggunakan komponen integrasi desktop pihak ketiga.'
        Write-Host '      Lisensi dan identitas komponen: docs/THIRD_PARTY_NOTICES.md'
        Write-Host '      https://github.com/efendiyhy/gaptex/blob/main/docs/THIRD_PARTY_NOTICES.md'
        $reply = Read-Host '      Izinkan pemasangan komponen pendukung? (Y/N)'
        if ($reply -notmatch '^(?i:y|yes|ya)$') { throw 'Instalasi dibatalkan oleh pengguna.' }
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $winget) { throw 'Windows Package Manager tidak ditemukan. Instal App Installer melalui Microsoft Store.' }
        Write-GaptexText '      Memasang komponen pendukung...' ([ConsoleColor]::Yellow)
        if (-not (Invoke-GaptexCommand -Executable $winget.Source -Arguments @(
            'install','--id','Spicetify.Spicetify','--exact','--silent',
            '--accept-package-agreements','--accept-source-agreements'
        ))) { throw "Pemasangan komponen pendukung gagal. Periksa $log" }
        $env:Path = @(
            [Environment]::GetEnvironmentVariable('Path','Machine'),
            [Environment]::GetEnvironmentVariable('Path','User'),
            $env:Path
        ) -join ';'
        $runtime = Find-GaptexRuntime
        if (-not $runtime) { throw 'Komponen sudah terpasang tetapi belum terdeteksi. Buka PowerShell baru dan jalankan kembali installer.' }
    }

    Write-GaptexText '  [3/5] Menyiapkan konfigurasi...' ([ConsoleColor]::Cyan)
    Stop-GaptexSpotify
    # The first CLI run initializes config on a fresh machine.
    if (-not (Invoke-GaptexCommand -Executable $runtime -Arguments @())) {
        throw "Konfigurasi integrasi belum berhasil. Periksa $log"
    }
    $extensionDir = Join-Path $env:APPDATA 'spicetify\Extensions'
    $destination = Join-Path $extensionDir 'gaptex.js'
    New-Item -Path $extensionDir -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Force
    if (-not (Invoke-GaptexCommand -Executable $runtime -Arguments @('config','extensions','gaptex.js'))) {
        throw "Pendaftaran Gaptex gagal. Periksa $log"
    }

    Write-GaptexText '  [4/5] Mengaktifkan Gaptex...' ([ConsoleColor]::Cyan)
    if (-not (Enable-Gaptex -Runtime $runtime)) {
        Show-GaptexDiagnostic
        throw "Aktivasi gagal. Log teknis: $log"
    }

    Write-GaptexText '  [5/5] Finalisasi...' ([ConsoleColor]::Cyan)
    Add-GaptexLog 'Gaptex activation completed.'
    Write-Host ''
    Write-GaptexText '  [+] GAPTEX BERHASIL DIPASANG!' ([ConsoleColor]::Green)
    Write-GaptexText '  Buka Spotify Desktop > menu profil > Gaptex.' ([ConsoleColor]::White)
    Write-GaptexText '  AdBlock: best effort | Anti-Reshuffle: kunci status shuffle.' ([ConsoleColor]::DarkCyan)
    Write-Host ''
}
catch {
    Add-GaptexLog ('INSTALL FAILED: ' + $_.Exception.Message)
    Write-GaptexText ('  [!] ' + $_.Exception.Message) ([ConsoleColor]::Red)
    Write-GaptexText ("  Log: $log") ([ConsoleColor]::Yellow)
    throw
}
