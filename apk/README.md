# Rugdraiger Play — APK Android nativo

App **nativa Flutter** con la misma interfaz y mecánica que la web ([rugdraiger_play](https://rugdraiger.github.io/rugdraiger_play/)).

## Descargar

**Archivo:** `rugdraiger-play.apk` (~20 MB, ARM64)

**URL pública:**

```
https://rugdraiger.github.io/rugdraiger_play/apk/rugdraiger-play.apk
```

## Diferencia con la versión web

| | Web / PWA | APK nativo (este) |
|---|-----------|-------------------|
| Interfaz | Idéntica | Idéntica (Flutter nativo) |
| Tecnología | Navegador | Flutter + MediaStore + ExoPlayer |
| Música local | Selector de archivos | Escaneo nativo del almacenamiento |
| Segundo plano | Limitado | Notificación de reproducción nativa |

## Instalar

1. Descarga el APK en tu Android (ARM64: Samsung, Xiaomi, etc. recientes).
2. Abre el archivo e instala.
3. Activa **Instalar apps desconocidas** si Android lo pide.

## Regenerar

```bash
./scripts/build-apk.sh
```

Requisitos: Flutter SDK, JDK 17, Android SDK.

La carpeta `web/android/` (Capacitor/WebView) **no** se usa para el APK publicado.
