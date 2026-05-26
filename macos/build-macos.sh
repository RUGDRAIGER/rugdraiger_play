#!/usr/bin/env bash
# Genera Rugdraiger Play para macOS.
# Preferencia: Flutter nativo si Xcode está instalado; si no, Electron (misma UI web).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_DIR="$ROOT/rugdraiger_player"
OUT_DIR="$ROOT/macos/RugdraigerPlay"
PACKAGER_OUT="$ROOT/macos/_packager-out"
ZIP_NAME="RugdraigerPlay-macOS.zip"
ZIP_PATH="$ROOT/macos/$ZIP_NAME"
PUBLIC_DIR="$ROOT/web/public/macos"
APP_NAME="Rugdraiger Play.app"

build_flutter() {
  if ! xcodebuild -version >/dev/null 2>&1; then
    return 1
  fi
  echo "==> Compilando app macOS nativa (Flutter)..."
  cd "$FLUTTER_DIR"
  flutter pub get
  flutter build macos --release || return 1
  APP_SRC="$FLUTTER_DIR/build/macos/Build/Products/Release/Rugdraiger Play.app"
  [ -d "$APP_SRC" ] || return 1
  rm -rf "$OUT_DIR"
  mkdir -p "$OUT_DIR"
  ditto "$APP_SRC" "$OUT_DIR/$APP_NAME"
  return 0
}

build_electron() {
  echo "==> Compilando app macOS (Electron — misma UI web/APK)..."
  local arch
  arch=$(uname -m)
  if [ "$arch" = "x86_64" ]; then export ELECTRON_ARCH=x64; else export ELECTRON_ARCH=arm64; fi

  # Icono de la app (.icns + .png para dock)
  local icon_src="$ROOT/web/public/icons/app-icon.png"
  local assets_dir="$ROOT/macos/desktop-shell/assets"
  local iconset="$assets_dir/app.iconset"
  local icns="$assets_dir/app-icon.icns"
  mkdir -p "$assets_dir"
  cp "$icon_src" "$assets_dir/app-icon.png"
  rm -rf "$iconset"
  mkdir -p "$iconset"
  sips -z 16 16     "$icon_src" --out "$iconset/icon_16x16.png" >/dev/null
  sips -z 32 32     "$icon_src" --out "$iconset/icon_16x16@2x.png" >/dev/null
  sips -z 32 32     "$icon_src" --out "$iconset/icon_32x32.png" >/dev/null
  sips -z 64 64     "$icon_src" --out "$iconset/icon_32x32@2x.png" >/dev/null
  sips -z 128 128   "$icon_src" --out "$iconset/icon_128x128.png" >/dev/null
  sips -z 256 256   "$icon_src" --out "$iconset/icon_128x128@2x.png" >/dev/null
  sips -z 256 256   "$icon_src" --out "$iconset/icon_256x256.png" >/dev/null
  sips -z 512 512   "$icon_src" --out "$iconset/icon_256x256@2x.png" >/dev/null
  sips -z 512 512   "$icon_src" --out "$iconset/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$icon_src" --out "$iconset/icon_512x512@2x.png" >/dev/null
  iconutil -c icns "$iconset" -o "$icns"

  # No empaquetar el ZIP macOS dentro de la propia app
  rm -f "$ROOT/web/public/macos/"*.zip
  rm -rf "$ROOT/web/dist"

  cd "$ROOT/macos/desktop-shell"
  if [ ! -d node_modules ]; then
    npm install
  fi
  npm run pack:mac

  # electron-packager crea carpetas por arquitectura
  local app_src=""
  for candidate in \
    "$PACKAGER_OUT/Rugdraiger Play-darwin-${ELECTRON_ARCH}/Rugdraiger Play.app" \
    "$PACKAGER_OUT/Rugdraiger Play-darwin-arm64/Rugdraiger Play.app" \
    "$PACKAGER_OUT/Rugdraiger Play-darwin-x64/Rugdraiger Play.app"; do
    if [ -d "$candidate" ]; then
      app_src="$candidate"
      break
    fi
  done
  if [ -z "$app_src" ]; then
    echo "Error: no se encontró Rugdraiger Play.app tras electron-packager"
    exit 1
  fi
  rm -rf "$OUT_DIR"
  mkdir -p "$OUT_DIR"
  ditto "$app_src" "$OUT_DIR/$APP_NAME"
}

apply_macos_icon() {
  local app="$1"
  local icns="$ROOT/macos/desktop-shell/assets/app-icon.icns"
  [ -d "$app" ] || return 0
  [ -f "$icns" ] || return 0
  cp "$icns" "$app/Contents/Resources/app-icon.icns"
  rm -f "$app/Contents/Resources/electron.icns"
  /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile app-icon.icns" "$app/Contents/Info.plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string app-icon.icns" "$app/Contents/Info.plist"
  mkdir -p "$app/Contents/Resources/app/assets"
  cp "$icns" "$app/Contents/Resources/app/assets/app-icon.icns"
}

package_zip() {
  apply_macos_icon "$OUT_DIR/$APP_NAME"
  rm -f "$ZIP_PATH"
  ditto -c -k --sequesterRsrc --keepParent "$OUT_DIR/$APP_NAME" "$ZIP_PATH"
  mkdir -p "$PUBLIC_DIR"
  cp "$ZIP_PATH" "$PUBLIC_DIR/$ZIP_NAME"
  SIZE=$(du -h "$ZIP_PATH" | cut -f1)
  echo ""
  echo "Listo."
  echo "  App:  $OUT_DIR/$APP_NAME"
  echo "  ZIP:  $ZIP_PATH ($SIZE)"
  echo "  Web:  $PUBLIC_DIR/$ZIP_NAME"
  echo ""
  echo "Probar: open \"$OUT_DIR/$APP_NAME\""
}

if build_flutter; then
  echo "Build Flutter nativo OK."
else
  echo "Flutter/Xcode no disponible — usando Electron."
  build_electron
fi

package_zip
