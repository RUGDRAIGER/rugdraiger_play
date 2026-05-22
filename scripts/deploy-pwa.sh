#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEB="$ROOT/web"

echo "==> Compilando PWA..."
cd "$WEB"
VITE_BASE_PATH=/rugdraiger_play/ npm run build

echo "==> Desplegando a gh-pages..."
touch dist/.nojekyll
cd dist
git init -b gh-pages
git add -A
git commit -m "Deploy PWA $(date +%Y-%m-%d)"
git push -f origin gh-pages
rm -rf .git

echo ""
echo "PWA publicada: https://rugdraiger.github.io/rugdraiger_play/"
echo "Empaqueta Android con PWA Builder Studio o pwabuilder.com"
