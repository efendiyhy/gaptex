# Gaptex Uninstaller v0.1.5
# Removes only Gaptex's extension, not shared third-party components.
$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Windows diperlukan.' }
$runtimeCommand = Get-Command spicetify -ErrorAction SilentlyContinue
$runtime = if ($runtimeCommand) { $runtimeCommand.Source } else { $null }
if (-not $runtime) {
    $candidate = Join-Path $env:USERPROFILE '.spicetify\spicetify.exe'
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { $runtime = $candidate }
}
$dir = Join-Path $env:APPDATA 'spicetify\Extensions'
$extension = Join-Path $dir 'gaptex.js'
$logFolder = Join-Path $env:LOCALAPPDATA 'Gaptex\logs'
New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
$log = Join-Path $logFolder 'uninstall.log'
Write-Host '[GAPTEX] Menghapus ekstensi...' -ForegroundColor Cyan
if ($runtime) {
    Get-Process -Name Spotify -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    foreach ($commandLine in @('config extensions gaptex.js-','apply --no-restart')) {
        $argsForCli = $commandLine -split ' '
        # Redirect streams separately to avoid PowerShell 5.1 NativeCommandError.
        $out = Join-Path $logFolder ([guid]::NewGuid().ToString('N') + '.out')
        $err = Join-Path $logFolder ([guid]::NewGuid().ToString('N') + '.err')
        try {
            $proc = Start-Process -FilePath $runtime -ArgumentList $argsForCli -NoNewWindow -Wait -PassThru `
                -RedirectStandardOutput $out -RedirectStandardError $err
            foreach ($file in @($out,$err)) {
                if (Test-Path -LiteralPath $file -PathType Leaf) {
                    Get-Content -LiteralPath $file | Add-Content -LiteralPath $log
                }
            }
            if ($proc.ExitCode -ne 0) {
                Write-Warning "Terdapat kendala saat memperbarui Spotify. Log: $log"
            }
        }
        finally { Remove-Item -LiteralPath $out,$err -Force -ErrorAction SilentlyContinue }
    }
}
if (Test-Path -LiteralPath $extension -PathType Leaf) {
    Remove-Item -LiteralPath $extension -Force
}
Write-Host 'Gaptex telah dihapus dari folder ekstensi.' -ForegroundColor Green
Write-Host 'Komponen bersama tetap terpasang. Buka ulang Spotify Desktop.'
