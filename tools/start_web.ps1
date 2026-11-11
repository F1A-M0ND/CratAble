param([string]$Python = '', [int]$Port = 8060)
$ErrorActionPreference = 'Stop'
if (!$Python) {
    $runtime = Get-AppxPackage -Name 'OpenAI.CodexPrimaryRuntime*' -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1
    if ($runtime) { $Python = Join-Path $runtime.InstallLocation 'dependencies/python/python.exe' }
    if (!$Python) {
        $candidate = Get-ChildItem "$env:ProgramFiles/WindowsApps/OpenAI.CodexPrimaryRuntime*/dependencies/python/python.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($candidate) { $Python = $candidate.FullName }
    }
}
if (!$Python -or !(Test-Path -LiteralPath $Python)) {
    throw 'Run again with -Python <path to python.exe> (Python 3).'
}
& $Python "$PSScriptRoot/serve_web.py" --port $Port
