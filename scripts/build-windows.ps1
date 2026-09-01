param(
  [ValidateSet("zh-CN", "en")]
  [string]$Language = "zh-CN"
)

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

$outDir = ".\build\windows\$Language"
$outExe = Join-Path $outDir "CopyPop.exe"
New-Item -ItemType Directory -Force $outDir | Out-Null
$msvcLanguageFlag = @()
$gnuLanguageFlag = @()
if ($Language -eq "en") {
  $msvcLanguageFlag = @("/DCOPYPOP_ENGLISH")
  $gnuLanguageFlag = @("-DCOPYPOP_ENGLISH")
}

$cl = Get-Command cl.exe -ErrorAction SilentlyContinue
$gxx = Get-Command g++.exe -ErrorAction SilentlyContinue
$clangxx = Get-Command clang++.exe -ErrorAction SilentlyContinue
$localClang = Get-ChildItem -Path ".\.tools" -Filter "clang-*.exe" -Recurse -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -match '^clang-\d+\.exe$' } |
  Select-Object -First 1

if ($cl) {
  & cl.exe /nologo /O1 /EHsc /std:c++17 $msvcLanguageFlag /utf-8 /DUNICODE /D_UNICODE /MT "/Fe:$outExe" ".\windows\CopyPop.cpp" user32.lib gdi32.lib shell32.lib
} elseif ($gxx) {
  & g++.exe -Os -std=c++17 $gnuLanguageFlag -finput-charset=UTF-8 -municode -mwindows -static ".\windows\CopyPop.cpp" -o $outExe -luser32 -lgdi32 -lshell32
} elseif ($clangxx) {
  & clang++.exe -Os -std=c++17 $gnuLanguageFlag -finput-charset=UTF-8 -municode -mwindows -static ".\windows\CopyPop.cpp" -o $outExe -luser32 -lgdi32 -lshell32
} elseif ($localClang) {
  & $localClang.FullName --driver-mode=g++ --target=x86_64-w64-windows-gnu -Os -std=c++17 $gnuLanguageFlag -finput-charset=UTF-8 -municode -mwindows -static ".\windows\CopyPop.cpp" -o $outExe -luser32 -lgdi32 -lshell32
} else {
  Write-Host "Install Visual Studio Build Tools, MinGW-w64, or LLVM-MinGW first."
  exit 1
}

if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Host "Built: $outExe"
