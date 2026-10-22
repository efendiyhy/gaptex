# Gaptex uninstaller. Leaves any shared third-party integration tool installed.
$ErrorActionPreference = 'Stop'
$runtime = Get-Command spicetify -ErrorAction SilentlyContinue
if (-not $runtime) {
    $candidate = Join-Path $env:USERPROFILE '.spicetify\spicetify.exe'
    if (Test-Path -LiteralPath $candidate) { $runtime = @{ Source = $candidate } }
}
if (-not $runtime) {
    throw 'Komponen integrasi desktop tidak ditemukan. Gaptex mungkin sudah tidak aktif.'
}
$logDir = Join-Path $env:LOCALAPPDATA 'Gaptex\logs'
New-Item -Path $logDir -ItemType Directory -Force | Out-Null
$log = Join-Path $logDir 'uninstall.log'
function Invoke-GaptexTool {
    param(
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )
    # External applications may write normal status messages to stderr.
    # On Windows PowerShell 5.1, *>> with ErrorActionPreference=Stop can
    # terminate the installer with NativeCommandError before checking exit code.
    # Capture native process streams separately and check the actual exit code.
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
                    [IO.File]::AppendAllText($log, $output + [Environment]::NewLine)
                }
            }
        }
        Add-Content -LiteralPath $log -Value ("Exit code: {0}" -f $process.ExitCode)
        return ($process.ExitCode -eq 0)
    }
    catch {
        Add-Content -LiteralPath $log -Value ("Process launch failed: {0}" -f $_.Exception.Message)
        Write-Warning "Proses integrasi desktop gagal. Periksa log: $log"
        return $false
    }
    finally {
        Remove-Item -LiteralPath $stdout, $stderr -Force -ErrorAction SilentlyContinue
    }
}

if (-not (Invoke-GaptexTool -Executable $runtime.Source -Arguments @('config', 'extensions', 'gaptex.js-'))) { throw "Gagal melepas Gaptex dari konfigurasi. Log: $log" }
$dest = Join-Path $env:APPDATA 'spicetify\Extensions\gaptex.js'
if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Force }
if (-not (Invoke-GaptexTool -Executable $runtime.Source -Arguments @('apply'))) { throw "Gaptex sudah dilepas, tetapi perubahan belum dapat diterapkan. Log: $log" }
Write-Host 'Gaptex berhasil dihapus. Komponen integrasi bersama tidak dihapus.' -ForegroundColor Green
