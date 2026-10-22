# Gaptex Online Installer v0.1.6
# Official source: https://github.com/efendiyhy/gaptex
# Installer engine and extension are fetched from the same branch.
# Third-party notices: docs/THIRD_PARTY_NOTICES.md
$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'Gaptex Installer hanya mendukung Windows.'
}
if ($PSVersionTable.PSVersion.Major -le 5) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}
$base = 'https://raw.githubusercontent.com/efendiyhy/gaptex/main'
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('Gaptex-' + [guid]::NewGuid().ToString('N'))
New-Item -Path $temporary -ItemType Directory -Force | Out-Null
try {
    New-Item -Path (Join-Path $temporary 'docs') -ItemType Directory -Force | Out-Null
    foreach ($item in @('install.ps1','gaptex.js','docs/THIRD_PARTY_NOTICES.md')) {
        $target = Join-Path $temporary ($item -replace '/', '\')
        $url = "$base/$item"
        Invoke-WebRequest -Uri $url -OutFile $target -UseBasicParsing -ErrorAction Stop
        if (-not (Test-Path -LiteralPath $target -PathType Leaf) -or (Get-Item -LiteralPath $target).Length -eq 0) {
            throw "Unduhan tidak lengkap: $item"
        }
    }
    $scriptPath = Join-Path $temporary 'install.ps1'
    & $scriptPath
}
finally {
    Remove-Item -LiteralPath $temporary -Recurse -Force -ErrorAction SilentlyContinue
}
