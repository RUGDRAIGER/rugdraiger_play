#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK_DIR="$ROOT/apk"
FLUTTER_DIR="$ROOT/rugdraiger_player"
JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk@17}"
ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export JAVA_HOME ANDROID_HOME ANDROID_SDK_ROOT="$ANDROID_HOME"

mkdir -p "$APK_DIR" "$ROOT/web/public/apk"

echo "==> Compilando app Android nativa (Flutter)..."
cd "$FLUTTER_DIR"
flutter pub get

ICON_SRC="$FLUTTER_DIR/assets/icons/app_icon.png"
if [ -f "$ICON_SRC" ]; then
  echo "==> Aplicando icono Android..."
  RES="$FLUTTER_DIR/android/app/src/main/res"
  apply_icon() {
    local folder="$1" size="$2"
    mkdir -p "$RES/$folder"
    sips -z "$size" "$size" "$ICON_SRC" --out "$RES/$folder/ic_launcher.png" >/dev/null 2>&1 || true
    cp "$RES/$folder/ic_launcher.png" "$RES/$folder/ic_launcher_round.png" 2>/dev/null || true
  }
  apply_icon mipmap-mdpi 48
  apply_icon mipmap-hdpi 72
  apply_icon mipmap-xhdpi 96
  apply_icon mipmap-xxhdpi 144
  apply_icon mipmap-xxxhdpi 192
fi

flutter build apk --release --split-per-abi

NATIVE_APK="$FLUTTER_DIR/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
if [ ! -f "$NATIVE_APK" ]; then
  echo "Error: no se generó el APK arm64."
  exit 1
fi

cp "$NATIVE_APK" "$APK_DIR/rugdraiger-play.apk"
cp "$NATIVE_APK" "$ROOT/web/public/apk/rugdraiger-play.apk"

echo ""
echo "APK nativo listo: $APK_DIR/rugdraiger-play.apk (~arm64, teléfonos modernos)"
echo "Copia web: $ROOT/web/public/apk/rugdraiger-play.apk"
echo "Publica con: cd web && npm run build:pages && (deploy gh-pages)"
