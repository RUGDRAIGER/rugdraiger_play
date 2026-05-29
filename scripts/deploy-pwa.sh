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
AUTHOR_NAME="$(git -C "$WEB/.." log -1 --format='%an')"
AUTHOR_EMAIL="$(git -C "$WEB/.." log -1 --format='%ae')"
cd dist
git lfs install 2>/dev/null || true
git lfs track "windows/*.zip" 2>/dev/null || true
git lfs track "macos/*.zip" 2>/dev/null || true
git lfs track "Win_install/*.exe" 2>/dev/null || true
git init -b gh-pages
git remote add origin "$REPO_URL" 2>/dev/null || git remote set-url origin "$REPO_URL"
git add -A
GIT_AUTHOR_NAME="$AUTHOR_NAME" GIT_AUTHOR_EMAIL="$AUTHOR_EMAIL" \
  GIT_COMMITTER_NAME="$AUTHOR_NAME" GIT_COMMITTER_EMAIL="$AUTHOR_EMAIL" \
  git commit -m "Deploy PWA $(date +%Y-%m-%d)"
git push -f origin gh-pages
rm -rf .git

echo ""
echo "PWA publicada: https://rugdraiger.github.io/rugdraiger_play/"
echo "Empaqueta Android con PWA Builder Studio o pwabuilder.com"
