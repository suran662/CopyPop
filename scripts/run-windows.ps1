param(
  [ValidateSet("zh-CN", "en")]
  [string]$Language = "zh-CN"
)

$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

& (Join-Path $PSScriptRoot "build-windows.ps1") -Language $Language
Start-Process ".\build\windows\$Language\CopyPop.exe"
