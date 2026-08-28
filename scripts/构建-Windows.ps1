$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

$outDir = ".\build\windows"
$outExe = Join-Path $outDir "CopyPop.exe"
New-Item -ItemType Directory -Force $outDir | Out-Null

$cl = Get-Command cl.exe -ErrorAction SilentlyContinue
$gxx = Get-Command g++.exe -ErrorAction SilentlyContinue

if ($cl) {
  & cl.exe /nologo /O1 /EHsc /std:c++17 /utf-8 /DUNICODE /D_UNICODE /MT "/Fe:$outExe" ".\windows\CopyPop.cpp" user32.lib gdi32.lib shell32.lib
} elseif ($gxx) {
  & g++.exe -Os -std=c++17 -finput-charset=UTF-8 -municode -mwindows ".\windows\CopyPop.cpp" -o $outExe -luser32 -lgdi32 -lshell32
} else {
  Write-Host "需要安装 Visual Studio Build Tools（使用 C++ 的桌面开发）或 MinGW-w64。"
  exit 1
}

Write-Host "已构建：$outExe"
