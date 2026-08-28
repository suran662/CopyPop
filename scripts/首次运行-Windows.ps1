$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

& (Join-Path $PSScriptRoot "构建-Windows.ps1")
Start-Process ".\build\windows\CopyPop.exe"
