# Rugdraiger Play — entorno de desarrollo (Windows)
# Ejecutar en PowerShell: .\scripts\setup-dev-env.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$DevRoot = "J:\dev"

Write-Host "==> Configurando variables de entorno en $DevRoot" -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path `
    "$DevRoot\flutter", `
    "$DevRoot\.pub-cache", `
    "$DevRoot\temp", `
    "$DevRoot\Android\Sdk" | Out-Null

$jdk = Get-ChildItem "C:\Program Files\Microsoft\jdk-*" -Directory -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending |
    Select-Object -First 1

if (-not $jdk) {
    Write-Warning "JDK 17 no encontrado. Instala: winget install Microsoft.OpenJDK.17"
} else {
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $jdk.FullName, "User")
    Write-Host "JAVA_HOME = $($jdk.FullName)"
}

[Environment]::SetEnvironmentVariable("FLUTTER_ROOT", "$DevRoot\flutter", "User")
[Environment]::SetEnvironmentVariable("PUB_CACHE", "$DevRoot\.pub-cache", "User")
[Environment]::SetEnvironmentVariable("TEMP", "$DevRoot\temp", "User")
[Environment]::SetEnvironmentVariable("TMP", "$DevRoot\temp", "User")
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "$DevRoot\Android\Sdk", "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", "$DevRoot\Android\Sdk", "User")

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$segments = $userPath -split ";" | Where-Object { $_ -and $_ -notmatch "C:\\src\\flutter" }
if ($segments -notcontains "$DevRoot\flutter\bin") {
    $segments = @("$DevRoot\flutter\bin") + $segments
}
[Environment]::SetEnvironmentVariable("Path", ($segments -join ";"), "User")

Write-Host "==> Instalando dependencias npm..." -ForegroundColor Cyan
npm ci --prefix "$Root\web"
npm ci --prefix "$Root\Win_install"
npm ci --prefix "$Root\exe\desktop-shell"
npm ci --ignore-scripts --prefix "$Root\android-twa"

if (Get-Command flutter -ErrorAction SilentlyContinue) {
    Write-Host "==> flutter pub get" -ForegroundColor Cyan
    Push-Location "$Root\rugdraiger_player"
    flutter config --android-sdk "$DevRoot\Android\Sdk"
    flutter pub get
    Pop-Location
} else {
    Write-Warning "Flutter no está en PATH. Clónalo en $DevRoot\flutter"
}

Write-Host ""
Write-Host "Listo. Reinicia Cursor/terminal y ejecuta:" -ForegroundColor Green
Write-Host "  cd web && npm run dev          # desarrollo web"
Write-Host "  cd web && npm run build        # build PWA"
Write-Host "  cd exe && .\build-windows.ps1  # .exe Flutter Windows"
Write-Host "  cd Win_install && .\build-installer.ps1  # instalador NSIS"
Write-Host ""
Write-Host "Si flutter doctor pide Developer Mode: start ms-settings:developers"
