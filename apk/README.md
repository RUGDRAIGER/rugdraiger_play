# Rugdraiger Play — APK Android

App Android (TWA) que carga la PWA publicada en GitHub Pages.

## Descargar

**Archivo:** `rugdraiger-play.apk` (~3.3 MB)

**URL pública (GitHub Pages):**

```
https://rugdraiger.github.io/rugdraiger_play/apk/rugdraiger-play.apk
```

## Instalar en Android

1. Descarga el APK en tu teléfono.
2. Abre el archivo descargado.
3. Si Android pide permiso, activa **Instalar apps desconocidas** para tu navegador o gestor de archivos.
4. Confirma la instalación.

## Regenerar el APK

```bash
./scripts/build-apk.sh
```

Requisitos: `curl`, `unzip`, JDK 17, Android SDK Build Tools (`apksigner`).

## Notas

- La app es un contenedor de la web; los cambios en la PWA se ven sin reinstalar el APK.
- Solo hace falta un APK nuevo si cambias icono, nombre o permisos Android.
- El keystore de firma (`release.keystore`) no se sube a Git; se crea localmente al ejecutar el script.
