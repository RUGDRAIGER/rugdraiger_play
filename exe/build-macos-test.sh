#!/usr/bin/env bash
# Prueba local de escritorio en macOS (misma base que Windows).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/rugdraiger_player"
flutter pub get
flutter build macos --release
echo ""
echo "App macOS: build/macos/Build/Products/Release/rugdraiger_player.app"
echo "Abrir: open build/macos/Build/Products/Release/rugdraiger_player.app"
