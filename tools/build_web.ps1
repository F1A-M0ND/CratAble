param([string]$Engine = "$env:USERPROFILE/Downloads/Godot_v4.6.1-stable_win64.exe/Godot_v4.6.1-stable_win64_console.exe")
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
if (!(Test-Path -LiteralPath $Engine)) { throw 'Pass -Engine with the path to Godot 4.6.1.' }
if (!(Test-Path -LiteralPath "$projectRoot/.web-tools/web_nothreads_release.zip")) {
    throw 'Run tools/fetch_web_templates.py first, or place the official Godot 4.6.1 Web templates in .web-tools/.'
}
New-Item -ItemType Directory -Force -Path "$projectRoot/build/web" | Out-Null
& $Engine --headless --editor --path $projectRoot --rendering-method gl_compatibility --import --quit --log-file "$projectRoot/.web-tools/import.log"
if ($LASTEXITCODE -ne 0) { throw "Asset import failed: $LASTEXITCODE" }
if (Select-String -LiteralPath "$projectRoot/.web-tools/import.log" -Pattern 'SCRIPT ERROR|^ERROR:' -Quiet) { throw 'Asset import log contains errors. Inspect .web-tools/import.log.' }
& $Engine --headless --path $projectRoot --rendering-method gl_compatibility --export-release Web "$projectRoot/build/web/index.html" --log-file "$projectRoot/.web-tools/export.log"
if ($LASTEXITCODE -ne 0) { throw "Web export failed: $LASTEXITCODE" }
if (Select-String -LiteralPath "$projectRoot/.web-tools/export.log" -Pattern 'SCRIPT ERROR|^ERROR:' -Quiet) { throw 'Web export log contains errors. Inspect .web-tools/export.log.' }
Write-Output 'Web build ready in build/web. Run tools/start_web.ps1 to preview.'
