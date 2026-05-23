#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEB="$ROOT/web"

echo "==> Compilando PWA..."
cd "$WEB"
VITE_BASE_PATH=/rugdraiger_play/ npm run build

echo "==> Desplegando a gh-pages..."
touch dist/.nojekyll
REPO_URL="$(git -C "$WEB/.." remote get-url origin)"
cd dist
git init -b gh-pages
git remote add origin "$REPO_URL" 2>/dev/null || git remote set-url origin "$REPO_URL"
git add -A
git commit -m "Deploy PWA $(date +%Y-%m-%d)"
git push -f origin gh-pages
rm -rf .git

echo ""
echo "PWA publicada: https://rugdraiger.github.io/rugdraiger_play/"
echo "Empaqueta Android con PWA Builder Studio o pwabuilder.com"
