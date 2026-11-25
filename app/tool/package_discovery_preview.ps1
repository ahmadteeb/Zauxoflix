# Run from a Windows Flutter checkout with the C++ desktop workload, ATL and NuGet.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$appDirectory = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location -LiteralPath $appDirectory
try {
    flutter build windows --release --target tool/discovery_preview.dart
    if ($LASTEXITCODE -ne 0) { throw "Flutter build failed ($LASTEXITCODE)" }
    $bundle = (Resolve-Path 'build/windows/x64/runner/Release').Path
    foreach ($required in 'zauxoflix.exe','flutter_inappwebview_windows_plugin.dll','data/app.so') {
        if (!(Test-Path -LiteralPath (Join-Path $bundle $required))) { throw "Preview is missing $required" }
    }
    Copy-Item -LiteralPath 'tool/preview/sample.mp4' -Destination $bundle
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    $vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    $crt = Get-ChildItem -Directory -Path (Join-Path $vs 'VC/Redist/MSVC/*/x64/Microsoft.VC*.CRT') |
        Sort-Object FullName -Descending | Select-Object -First 1
    if (!$crt) { throw 'Visual C++ x64 redistributable libraries are missing' }
    Get-ChildItem -LiteralPath $crt.FullName -Filter '*.dll' | Copy-Item -Destination $bundle
    $zip = Join-Path $appDirectory 'build/Zauxoflix-Discovery-Preview-Windows.zip'
    Compress-Archive -Path (Join-Path $bundle '*') -DestinationPath $zip -Force
    Get-Item -LiteralPath $zip
} finally {
    Pop-Location
}
