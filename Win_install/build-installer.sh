#!/usr/bin/env bash
# Genera instalador NSIS de Rugdraiger Play (solo Windows).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    powershell -ExecutionPolicy Bypass -File "$SCRIPT_DIR/build-installer.ps1"
    ;;
  *)
    echo "El instalador NSIS solo puede generarse en Windows."
    echo "Usa GitHub Actions: gh workflow run build-windows-installer.yml"
    exit 1
    ;;
esac
