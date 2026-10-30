#!/usr/bin/env bash
# Genera Rugdraiger Play para macOS Apple Silicon con Electron.
# Flutter queda disponible de forma explícita con --flutter y requiere Xcode completo.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_DIR="$ROOT/rugdraiger_player"
OUT_DIR="$ROOT/macos/RugdraigerPlay"
PACKAGER_OUT="$ROOT/macos/_packager-out"
ZIP_NAME="RugdraigerPlay-macOS.zip"
ZIP_PATH="$ROOT/macos/$ZIP_NAME"
PUBLIC_DIR="$ROOT/web/public/macos"
APP_NAME="Rugdraiger Play.app"
PUBLISH_ARTIFACT=false
USE_FLUTTER=false

for arg in "$@"; do
  case "$arg" in
    --publish-artifact) PUBLISH_ARTIFACT=true ;;
    --flutter) USE_FLUTTER=true ;;
    *) echo "Argumento no reconocido: $arg" >&2; exit 2 ;;
  esac
done

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
  echo "==> Compilando app macOS arm64 (Electron)..."
  local arch
  arch=$(uname -m)
  if [ "$arch" = "x86_64" ]; then
    export ELECTRON_ARCH=x64
  elif [ "$arch" = "arm64" ]; then
    export ELECTRON_ARCH=arm64
  else
    echo "Arquitectura macOS no compatible: $arch" >&2
    exit 1
  fi

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

  rm -rf "$ROOT/web/dist"

  cd "$ROOT/macos/desktop-shell"
  npm ci
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
  /usr/libexec/PlistBuddy -c "Set :LSMinimumSystemVersion 13.0" "$app/Contents/Info.plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 13.0" "$app/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Add :LSApplicationCategoryType string public.app-category.music" "$app/Contents/Info.plist" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :NSHighResolutionCapable bool true" "$app/Contents/Info.plist" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :NSDesktopFolderUsageDescription string Rugdraiger Play necesita leer tu música cuando eliges el Escritorio." "$app/Contents/Info.plist" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :NSDocumentsFolderUsageDescription string Rugdraiger Play necesita leer los archivos de música que autorices en Documentos." "$app/Contents/Info.plist" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :NSDownloadsFolderUsageDescription string Rugdraiger Play necesita leer los archivos de música que autorices en Descargas." "$app/Contents/Info.plist" 2>/dev/null || true
  mkdir -p "$app/Contents/Resources/app/assets"
  cp "$ROOT/macos/desktop-shell/assets/app-icon.png" "$app/Contents/Resources/app/assets/app-icon.png"
}

package_zip() {
  local app="$OUT_DIR/$APP_NAME"
  apply_macos_icon "$app"
  # Documents puede estar administrado por File Provider, que vuelve a añadir
  # FinderInfo inmediatamente después de limpiarlo. Firmar en /tmp evita esa
  # carrera y garantiza que el ZIP distribuido no contenga esos atributos.
  local staging_dir
  local staged_app
  staging_dir=$(mktemp -d /tmp/rugdraiger-play-build.XXXXXX)
  staged_app="$staging_dir/$APP_NAME"
  ditto --norsrc --noextattr --noqtn --noacl "$app" "$staged_app"
  xattr -cr "$staged_app"
  codesign --force --deep --sign - "$staged_app"
  codesign --verify --deep --strict --verbose=2 "$staged_app"

  local executable="$staged_app/Contents/MacOS/Rugdraiger Play"
  local actual_arch
  local expected_arch="${ELECTRON_ARCH:-$(uname -m)}"
  actual_arch=$(lipo -archs "$executable")
  if [ "$expected_arch" = "arm64" ] && [[ "$actual_arch" != *"arm64"* ]]; then
    echo "Error: el ejecutable generado no contiene arm64 ($actual_arch)" >&2
    exit 1
  fi

  rm -f "$ZIP_PATH"
  # No conservar xattrs del volumen de trabajo: FinderInfo/fileprovider no
  # pertenecen a la app y vuelven inválida la firma al descomprimir el ZIP.
  ditto -c -k --norsrc --noextattr --noqtn --noacl --keepParent "$staged_app" "$ZIP_PATH"
  unzip -tq "$ZIP_PATH"

  # Dejar también una copia ejecutable en el proyecto. File Provider puede
  # añadirle metadatos externos después, pero el código firmado es el mismo.
  rm -rf "$app"
  ditto --norsrc --noextattr --noqtn --noacl "$staged_app" "$app"
  rm -rf "$staging_dir"
  shasum -a 256 "$ZIP_PATH" > "$ZIP_PATH.sha256"
  if [ "$PUBLISH_ARTIFACT" = true ]; then
    mkdir -p "$PUBLIC_DIR"
    cp "$ZIP_PATH" "$PUBLIC_DIR/$ZIP_NAME"
  fi
  SIZE=$(du -h "$ZIP_PATH" | cut -f1)
  echo ""
  echo "Listo."
  echo "  App:  $OUT_DIR/$APP_NAME"
  echo "  ZIP:  $ZIP_PATH ($SIZE)"
  echo "  SHA:  $ZIP_PATH.sha256"
  echo "  Arch: $actual_arch"
  if [ "$PUBLISH_ARTIFACT" = true ]; then
    echo "  Web:  $PUBLIC_DIR/$ZIP_NAME"
  fi
  echo ""
  echo "Probar: open \"$OUT_DIR/$APP_NAME\""
}

if [ "$(uname -s)" != "Darwin" ]; then
  echo "Este build solo puede ejecutarse en macOS." >&2
  exit 1
fi

if [ "$USE_FLUTTER" = true ]; then
  if build_flutter; then
    echo "Build Flutter nativo OK."
  else
    echo "No se pudo compilar Flutter. Instala Xcode completo y ejecuta flutter doctor." >&2
    exit 1
  fi
else
  build_electron
fi

package_zip
