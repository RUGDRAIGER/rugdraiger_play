#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK_DIR="$ROOT/apk"
JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17}"
ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export JAVA_HOME ANDROID_HOME ANDROID_SDK_ROOT="$ANDROID_HOME"

mkdir -p "$APK_DIR/extracted"

echo "==> Generando paquete Android (PWABuilder)..."
curl -sS -X POST "https://pwabuilder-cloudapk.azurewebsites.net/generateAppPackage" \
  -H "Content-Type: application/json" \
  -o "$APK_DIR/rugdraiger-play-package.zip" \
  --data-raw '{
    "packageId": "com.rugdraiger.play",
    "host": "https://rugdraiger.github.io",
    "name": "Rugdraiger Play",
    "launcherName": "Rugdraiger",
    "display": "standalone",
    "themeColor": "#0A0A0A",
    "themeColorDark": "#0A0A0A",
    "navigationColor": "#0A0A0A",
    "navigationColorDark": "#000000",
    "navigationDividerColor": "#000000",
    "navigationDividerColorDark": "#000000",
    "backgroundColor": "#0A0A0A",
    "enableNotifications": false,
    "startUrl": "/rugdraiger_play/",
    "iconUrl": "https://rugdraiger.github.io/rugdraiger_play/icons/icon-512.png",
    "maskableIconUrl": "https://rugdraiger.github.io/rugdraiger_play/icons/icon-512.png",
    "monochromeIconUrl": "https://rugdraiger.github.io/rugdraiger_play/icons/icon-192.png",
    "splashScreenFadeOutDuration": 300,
    "appVersion": "1.0.0",
    "appVersionCode": 1,
    "webManifestUrl": "https://rugdraiger.github.io/rugdraiger_play/manifest.json",
    "fallbackType": "customtabs",
    "enableSiteSettingsShortcut": true,
    "isChromeOSOnly": false,
    "orientation": "default",
    "signingMode": "none",
    "shortcuts": [],
    "features": {},
    "additionalTrustedOrigins": []
  }'

unzip -o "$APK_DIR/rugdraiger-play-package.zip" -d "$APK_DIR/extracted"

KEYSTORE="$APK_DIR/release.keystore"
if [ ! -f "$KEYSTORE" ]; then
  echo "==> Creando keystore de firma..."
  "$JAVA_HOME/bin/keytool" -genkeypair -v -storetype PKCS12 \
    -keystore "$KEYSTORE" -alias rugdraiger \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass rugdraigerplay -keypass rugdraigerplay \
    -dname "CN=Rugdraiger Play, OU=Mobile, O=Rugdraiger, L=ES, ST=ES, C=ES"
fi

APKSIGNER="$(ls -d "$ANDROID_HOME"/build-tools/*/apksigner | sort -V | tail -1)"
echo "==> Firmando APK..."
"$APKSIGNER" sign \
  --ks "$KEYSTORE" \
  --ks-key-alias rugdraiger \
  --ks-pass pass:rugdraigerplay \
  --key-pass pass:rugdraigerplay \
  --out "$APK_DIR/rugdraiger-play.apk" \
  "$APK_DIR/extracted/Rugdraiger Play-unsigned.apk"

mkdir -p "$ROOT/web/public/apk"
cp "$APK_DIR/rugdraiger-play.apk" "$ROOT/web/public/apk/rugdraiger-play.apk"

echo ""
echo "APK listo: $APK_DIR/rugdraiger-play.apk"
echo "Copia web: $ROOT/web/public/apk/rugdraiger-play.apk"
echo "Publica con: cd web && VITE_BASE_PATH=/rugdraiger_play/ npm run build && (deploy gh-pages)"
