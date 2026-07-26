# Variables locales de desarrollo (Windows). Ejecutar: . .\scripts\local-env.ps1
$DevRoot = "J:\dev"
$jdk = Get-ChildItem "C:\Program Files\Microsoft\jdk-*" -Directory -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending |
    Select-Object -First 1

if ($jdk) { $env:JAVA_HOME = $jdk.FullName }
$env:FLUTTER_ROOT = "$DevRoot\flutter"
$env:PUB_CACHE = "$DevRoot\.pub-cache"
$env:TEMP = "$DevRoot\temp"
$env:TMP = "$DevRoot\temp"
$env:ANDROID_HOME = "$DevRoot\Android\Sdk"
$env:ANDROID_SDK_ROOT = "$DevRoot\Android\Sdk"
$env:Path = "$DevRoot\flutter\bin;$DevRoot\Android\Sdk\platform-tools;$env:JAVA_HOME\bin;" + $env:Path

Write-Host "Entorno local cargado desde $DevRoot"
