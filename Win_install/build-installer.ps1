$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$PublicDir = Join-Path $Root "web/public/Win_install"
$SetupName = "RugdraigerPlay-Setup.exe"

Write-Host "==> Preparando icono..."
$iconSrc = Join-Path $Root "web/public/icons/app-icon.png"
$assetsDir = Join-Path $Root "exe/desktop-shell/assets"
New-Item -ItemType Directory -Force -Path $assetsDir | Out-Null
Copy-Item $iconSrc (Join-Path $assetsDir "app-icon.png") -Force

Write-Host "==> Compilando web..."
Push-Location (Join-Path $Root "web")
npm ci
$env:VITE_CAPACITOR = "true"
npm run build
Pop-Location

Write-Host "==> Generando icono .ico..."
Push-Location (Join-Path $Root "exe/desktop-shell")
npm ci
npm run make:ico
Pop-Location

Write-Host "==> Generando instalador NSIS..."
Push-Location $PSScriptRoot
npm ci
npm run installer
Pop-Location

$installer = Get-ChildItem (Join-Path $PSScriptRoot "dist") -Filter "*.exe" |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $installer) {
  throw "No se encontró el instalador en Win_install/dist"
}

New-Item -ItemType Directory -Force -Path $PublicDir | Out-Null
Copy-Item $installer.FullName (Join-Path $PublicDir $SetupName) -Force

$sizeMb = [math]::Round($installer.Length / 1MB, 1)
Write-Host ""
Write-Host "Listo."
Write-Host "  Instalador: $($installer.FullName) ($sizeMb MB)"
Write-Host "  Web:        $(Join-Path $PublicDir $SetupName)"
