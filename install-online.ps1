# Gaptex online bootstrap - EK Instrumentation. Windows PowerShell 5.1+.
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Repo = 'https://raw.githubusercontent.com/efendiyhy/gaptex/main'
$work = Join-Path $env:TEMP ('Gaptex-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work -Force | Out-Null
try {
    foreach ($filename in @('install.ps1', 'gaptex.js')) {
        $url = "$Repo/$filename"
        $destination = Join-Path $work $filename
        Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $destination -ErrorAction Stop
        if (-not (Test-Path -LiteralPath $destination) -or (Get-Item -LiteralPath $destination).Length -lt 100) {
            throw "File Gaptex gagal diunduh: $filename"
        }
    }
    # Invoke in the current PowerShell process so exit errors remain visible.
    & (Join-Path $work 'install.ps1')
} finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
