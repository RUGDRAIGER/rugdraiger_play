# Rugdraiger Play — App Android (PWA Builder)

Convierte la PWA publicada en una app Android instalable con **PWA Builder Studio** o **Bubblewrap**.

## URL de la PWA

```
https://rugdraiger.github.io/rugdraiger_play/
```

Manifest:

```
https://rugdraiger.github.io/rugdraiger_play/manifest.json
```

---

## Opción A — PWA Builder Studio (recomendado)

### 1. Instalar la extensión en VS Code / Cursor

1. Abre **Extensions** (`Cmd+Shift+X`)
2. Busca **PWABuilder Studio** ([marketplace](https://marketplace.visualstudio.com/items?itemName=PWABuilder.pwa-studio))
3. Instala la extensión de **PWABuilder**

### 2. Abrir el proyecto web

```bash
cd web
code .   # o abre la carpeta web en Cursor
```

### 3. Auditar la PWA

1. Abre la paleta de comandos (`Cmd+Shift+P`)
2. Ejecuta: **PWA Studio: Edit your Web Manifest**
3. Verifica nombre, iconos 192/512, `display: standalone`, theme color
4. Ejecuta: **PWA Studio: Generate Service Worker** (ya incluido con Vite PWA al compilar)
5. Ejecuta: **PWA Studio: Validate your PWA**

### 4. Generar el paquete Android

1. `Cmd+Shift+P` → **PWA Studio: Package your PWA for the Google Play Store**
2. Introduce la URL: `https://rugdraiger.github.io/rugdraiger_play/`
3. Selecciona **Android**
4. Configura:
   - **Package ID:** `com.rugdraiger.play`
   - **App name:** Rugdraiger Play
   - **Signing key:** crea uno nuevo o usa `android-twa/android.keystore`
5. Descarga el **APK** (pruebas) o **AAB** (Google Play)

### 5. Instalar en tu teléfono

- Copia el `.apk` al móvil e instálalo, **o**
- Conecta el teléfono por USB con depuración activada y usa Android Studio

---

## Opción B — PWA Builder web

1. Entra en [pwabuilder.com](https://www.pwabuilder.com/)
2. Pega: `https://rugdraiger.github.io/rugdraiger_play/`
3. Pulsa **Start** → revisa manifest y service worker
4. **Package for stores** → **Android** → descarga APK/AAB

---

## Opción C — Bubblewrap (CLI local)

Requisitos: **JDK 17**, **Android SDK**, variables de entorno:

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export ANDROID_HOME=~/Library/Android/sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
```

### Generar proyecto Android

```bash
cd android-twa
npm install
npx bubblewrap update
npx bubblewrap build
```

Salida:

- `app-release-signed.apk` — instalar directamente
- `app-release-bundle.aab` — subir a Google Play

### Keystore de firma

Si no existe, créalo (guarda la contraseña en lugar seguro):

```bash
keytool -genkeypair -v -storetype PKCS12 \
  -keystore android.keystore -alias rugdraiger \
  -keyalg RSA -keysize 2048 -validity 10000
```

---

## Actualizar la PWA y la app

Cada vez que cambies la web:

```bash
# 1. Compilar y publicar PWA
cd web
VITE_BASE_PATH=/rugdraiger_play/ npm run build
cd dist && git init -b gh-pages && git add -A && git commit -m "Deploy"
git push -f origin gh-pages

# 2. La app Android NO necesita recompilarse para cambios web
#    (carga la URL en vivo). Solo recompila si cambias icono, package ID o permisos.
```

---

## Digital Asset Links (pantalla completa sin barra del navegador)

Para que Android abra la PWA en modo TWA sin barra de Chrome, publica tu huella SHA-256 en:

```
https://rugdraiger.github.io/rugdraiger_play/.well-known/assetlinks.json
```

Obtén la huella:

```bash
keytool -list -v -keystore android-twa/android.keystore -alias rugdraiger
```

Plantilla en `web/public/.well-known/assetlinks.json`.

---

## Checklist PWA (Play Store)

- [x] HTTPS
- [x] Web Manifest (`manifest.json`)
- [x] Service Worker (`sw.js`)
- [x] Iconos 192×192 y 512×512
- [x] `display: standalone`
- [x] Theme / background color
- [ ] Política de privacidad (requerida en Play Store)
- [ ] Asset Links con huella de firma (recomendado para TWA)
