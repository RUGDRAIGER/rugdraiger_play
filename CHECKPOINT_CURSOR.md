# Checkpoint Cursor — Rugdraiger Play
**Fecha:** 2026-05-24

## Estado del proyecto

### APK Android (completo)
- Carátulas en notificación, pantalla bloqueada y widget de escritorio
- Controles rojos, tipografía grande en widget
- Favoritos, lo más escuchado, búsqueda manual de carátula
- **Descarga:** https://rugdraiger.github.io/rugdraiger_play/apk/rugdraiger-play.apk
- Rama `main` y `gh-pages` publicadas

### Versión escritorio Windows ✅ LISTA
- **ZIP para instalar:** `exe/RugdraigerPlay-Windows.zip` (~248 MB)
- **Ejecutable:** `exe/RugdraigerPlay/Rugdraiger Play-win32-x64/Rugdraiger Play.exe`
- Instrucciones: `exe/COMO-INSTALAR-EN-WINDOWS.txt`
- Build con `@electron/packager` (misma UI web/APK)
- Versión Flutter nativa: `exe/INSTALAR-Y-GENERAR-EXE.bat` (solo en PC Windows)

## Último commit
```
88cf928 Añadir versión escritorio Windows (Flutter) y carpeta exe.
```

## Archivos clave
| Ruta | Descripción |
|------|-------------|
| `rugdraiger_player/lib/main.dart` | Bootstrap desktop + Android |
| `rugdraiger_player/lib/core/platform/` | DB FFI, rutas música desktop |
| `exe/INSTALAR-Y-GENERAR-EXE.bat` | Generador one-click en Windows |
| `exe/desktop-shell/` | Wrapper Electron (misma UI web) |
| `ENTREGA_IA.txt` | Documentación entrega |

## Comandos útiles
```bash
# Probar escritorio en Mac
open "rugdraiger_player/build/macos/Build/Products/Release/Rugdraiger Play.app"

# Build APK
./scripts/build-apk.sh

# Electron portable Windows (desde Mac)
cd exe/desktop-shell && npm run pack:win
```
