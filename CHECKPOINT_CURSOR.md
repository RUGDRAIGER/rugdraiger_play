# Checkpoint Cursor — Rugdraiger Play
**Fecha:** 2026-05-24

## Estado del proyecto

### APK Android (completo)
- Carátulas en notificación, pantalla bloqueada y widget de escritorio
- Controles rojos, tipografía grande en widget
- Favoritos, lo más escuchado, búsqueda manual de carátula
- **Descarga:** https://rugdraiger.github.io/rugdraiger_play/apk/rugdraiger-play.apk
- Rama `main` y `gh-pages` publicadas

### Versión escritorio Windows (en progreso)
- Código Flutter adaptado para Windows/macOS en `rugdraiger_player/`
- Carpeta `exe/` con scripts de build
- **Limitación:** el `.exe` nativo Flutter **solo se genera en un PC Windows** (no desde Mac)
- Compilación macOS probada OK: `Rugdraiger Play.app`

### Pendiente al reiniciar Cursor
1. **EXE Windows nativo (Flutter):** ejecutar en PC Windows:
   - `exe\INSTALAR-Y-GENERAR-EXE.bat`
   - O `exe\build-windows.ps1`
2. **EXE portable (Electron):** alternativa desde Mac en `exe/desktop-shell/`:
   - `npm run pack:win` (genera `exe/RugdraigerPlay-Portable/RugdraigerPlay-Portable.exe`)
   - Build interrumpido — reintentar si hace falta
3. **GitHub Actions Windows:** archivo plantilla en `exe/build-windows-exe.workflow.yml`
   - Copiar a `.github/workflows/` requiere token con scope `workflow`
4. **No subir a GitHub** hasta confirmación del usuario (excepto commit local)

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
