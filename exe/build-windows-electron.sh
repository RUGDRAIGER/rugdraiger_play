#!/usr/bin/env bash
# Genera Rugdraiger Play para Windows (Electron — misma UI web/macOS).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT/exe/RugdraigerPlay"
PACKAGER_OUT="$ROOT/exe/_packager-out"
ZIP_NAME="RugdraigerPlay-Windows.zip"
ZIP_PATH="$ROOT/exe/$ZIP_NAME"
PUBLIC_DIR="$ROOT/web/public/windows"
APP_FOLDER="Rugdraiger Play-win32-x64"

echo "==> Compilando app Windows (Electron — misma UI web/macOS)..."

icon_src="$ROOT/web/public/icons/app-icon.png"
assets_dir="$ROOT/exe/desktop-shell/assets"
mkdir -p "$assets_dir"
cp "$icon_src" "$assets_dir/app-icon.png"

rm -f "$ROOT/web/public/windows/"*.zip
rm -rf "$ROOT/web/dist"

cd "$ROOT/exe/desktop-shell"
if [ ! -d node_modules ]; then
  npm install
fi
npm run pack:win

app_src=""
for candidate in \
  "$PACKAGER_OUT/Rugdraiger Play-win32-x64/Rugdraiger Play.exe" \
  "$PACKAGER_OUT/Rugdraiger Play-win32-ia32/Rugdraiger Play.exe"; do
  if [ -f "$candidate" ]; then
    app_src="$(dirname "$candidate")"
    break
  fi
done

if [ -z "$app_src" ]; then
  echo "Error: no se encontró Rugdraiger Play.exe tras electron-packager"
  exit 1
fi

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
ditto "$app_src" "$OUT_DIR"

rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$OUT_DIR" "$ZIP_PATH"
mkdir -p "$PUBLIC_DIR"
cp "$ZIP_PATH" "$PUBLIC_DIR/$ZIP_NAME"

SIZE=$(du -h "$ZIP_PATH" | cut -f1)
echo ""
echo "Listo."
echo "  App:  $OUT_DIR"
echo "  ZIP:  $ZIP_PATH ($SIZE)"
echo "  Web:  $PUBLIC_DIR/$ZIP_NAME"
