# Rugdraiger Play — APK Android nativo

App **nativa** compilada con Flutter (no es un contenedor de Chrome).

## Descargar

**Archivo:** `rugdraiger-play.apk` (~20 MB, ARM64)

**URL pública:**

```
https://rugdraiger.github.io/rugdraiger_play/apk/rugdraiger-play.apk
```

## Diferencia con la versión web

| | Web / PWA | APK nativo (este) |
|---|-----------|-------------------|
| Tecnología | Navegador / Chrome | Flutter + Android |
| Música local | Carpeta del navegador | Acceso directo al almacenamiento |
| Sensación | Página web | App instalada nativa |
| Tamaño | ~3 MB (TWA) | ~20 MB |

## Instalar

1. Descarga el APK en tu Android (ARM64: Samsung, Xiaomi, etc. recientes).
2. Abre el archivo e instala.
3. Activa **Instalar apps desconocidas** si Android lo pide.

## Regenerar

```bash
./scripts/build-apk.sh
```

Requisitos: Flutter SDK, JDK 17, Android SDK.
