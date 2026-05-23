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
echo "Publica con: cd web && VITE_BASE_PATH=/rugdraiger_play/ npm run build && (deploy gh-pages)"
