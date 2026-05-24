#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$FlutterDir = Join-Path $Root "rugdraiger_player"
$OutDir = Join-Path $PSScriptRoot "RugdraigerPlay"
$BuildDir = Join-Path $FlutterDir "build\windows\x64\runner\Release"

Write-Host "==> Rugdraiger Play — build Windows" -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Error "Flutter no está instalado o no está en el PATH."
}

Push-Location $FlutterDir
try {
    Write-Host "==> flutter pub get"
    flutter pub get

    Write-Host "==> flutter build windows --release"
    flutter build windows --release
}
finally {
    Pop-Location
}

if (-not (Test-Path $BuildDir)) {
    Write-Error "No se encontró la salida de compilación en: $BuildDir"
}

if (Test-Path $OutDir) {
    Remove-Item $OutDir -Recurse -Force
}

Write-Host "==> Copiando a $OutDir"
Copy-Item $BuildDir $OutDir -Recurse

$Exe = Join-Path $OutDir "RugdraigerPlay.exe"
if (-not (Test-Path $Exe)) {
    Write-Error "No se generó RugdraigerPlay.exe"
}

Write-Host ""
Write-Host "Listo: $Exe" -ForegroundColor Green
Write-Host "Ejecuta la carpeta completa RugdraigerPlay (no muevas solo el .exe)."
