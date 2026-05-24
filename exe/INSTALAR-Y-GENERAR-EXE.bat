@echo off
title Rugdraiger Play - Generar EXE
echo.
echo ============================================
echo   RUGDRAIGER PLAY - Instalador Windows
echo ============================================
echo.

where flutter >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter no esta instalado.
    echo.
    echo 1. Descarga Flutter: https://docs.flutter.dev/get-started/install/windows
    echo 2. Instala Visual Studio 2022 con "Desarrollo de escritorio con C++"
    echo 3. Vuelve a ejecutar este archivo.
    pause
    exit /b 1
)

echo [1/3] Descargando dependencias...
cd /d "%~dp0..\rugdraiger_player"
call flutter pub get
if errorlevel 1 goto error

echo [2/3] Compilando Rugdraiger Play (puede tardar varios minutos)...
call flutter build windows --release
if errorlevel 1 goto error

echo [3/3] Copiando a exe\RugdraigerPlay...
set SRC=build\windows\x64\runner\Release
set DST=%~dp0RugdraigerPlay
if exist "%DST%" rmdir /s /q "%DST%"
mkdir "%DST%"
xcopy /E /I /Y "%SRC%\*" "%DST%\"

echo.
echo ============================================
echo   LISTO!
echo ============================================
echo.
echo Ejecuta: %DST%\RugdraigerPlay.exe
echo.
echo Puedes copiar toda la carpeta RugdraigerPlay a tu PC
echo o crear un acceso directo al .exe
echo.
start "" "%DST%\RugdraigerPlay.exe"
pause
exit /b 0

:error
echo.
echo [ERROR] La compilacion fallo. Revisa que Visual Studio 2022
echo tenga instalado "Desarrollo de escritorio con C++".
pause
exit /b 1
