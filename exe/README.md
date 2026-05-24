# Rugdraiger Play — Escritorio Windows

Reproductor de escritorio basado en la misma app Flutter de la APK Android.

## Características incluidas

- Mismo diseño oscuro con acento rojo (#FF2020)
- Inicio, biblioteca, canciones, álbumes, artistas, playlists
- Favoritos, lo más escuchado, recientes
- Reproductor completo con carátulas
- Búsqueda manual de carátula (iTunes)
- Ecualizador (presets guardados)
- Escanear carpeta de música o biblioteca automática (`Música`, `Descargas`)

## Requisitos para compilar en Windows

1. **Windows 10/11** (64 bits)
2. **Flutter SDK** estable: https://docs.flutter.dev/get-started/install/windows
3. **Visual Studio 2022** con carga de trabajo **“Desarrollo de escritorio con C++”**
4. Ejecutar una vez: `flutter doctor` y corregir lo que falte

## Compilar el .exe

### Opción A — Script automático (recomendado)

```powershell
cd exe
.\build-windows.ps1
```

### Opción B — Manual

```powershell
cd rugdraiger_player
flutter pub get
flutter build windows --release
```

El ejecutable quedará en:

```
exe\RugdraigerPlay\RugdraigerPlay.exe
```

## Ejecutar

Abre `exe\RugdraigerPlay\RugdraigerPlay.exe`.

En el primer arranque escaneará las carpetas `Música` y `Descargas` de tu usuario. También puedes usar **Escanear carpeta** en Inicio.

## Notas

- El `.exe` **solo se puede generar en un PC con Windows** (Flutter no compila Windows desde macOS).
- La app de escritorio usa la misma base de código que la APK; no se sube a GitHub hasta confirmación del usuario.
- Para distribuir, copia toda la carpeta `RugdraigerPlay` (incluye DLLs necesarias).
