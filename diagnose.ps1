$log = Join-Path $env:LOCALAPPDATA 'Gaptex\logs\install.log'
Write-Host '=== GAPTEX DIAGNOSTICS ===' -ForegroundColor Cyan
$exe = (Get-Command spicetify.exe -ErrorAction SilentlyContinue).Source
if (-not $exe) { $exe = Join-Path $env:LOCALAPPDATA 'spicetify\spicetify.exe' }
Write-Host ('Runtime: ' + $(if (Test-Path -LiteralPath $exe) { $exe } else { 'Not found' }))
Write-Host ('Spotify prefs: ' + (Test-Path (Join-Path $env:APPDATA 'Spotify\prefs')))
Write-Host ('Gaptex extension: ' + (Test-Path (Join-Path $env:APPDATA 'spicetify\Extensions\gaptex.js')))
if (Test-Path $log) {
    Write-Host '=== Latest log ==='
    Get-Content -LiteralPath $log -Tail 35
} else { Write-Host 'No install log yet.' }
