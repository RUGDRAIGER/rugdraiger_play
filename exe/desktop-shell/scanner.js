const fs = require('fs');
const fsp = fs.promises;
const path = require('path');

const AUDIO_EXTENSIONS = new Set([
  'mp3', 'mp2', 'mpa', 'flac', 'wav', 'wave', 'aiff', 'aif', 'aifc', 'alac', 'caf',
  'aac', 'm4a', 'm4b', 'm4p', 'mp4', 'ogg', 'oga', 'opus', 'wma', 'wmv',
  'ape', 'wv', 'tta', 'mpc', 'mka', 'webm', 'mid', 'midi', 'kar', '3gp', 'amr', 'dsf', 'dff',
]);

/** Carpetas que nunca se recorren (sistema / cachés pesadas) */
const SKIP_DIR_NAMES = new Set([
  'node_modules', '.git', '.trash', '.trashes',
  'cache', 'caches', 'logs', 'temp', 'tmp',
  'system', 'private', 'dev', 'proc', 'cores', 'net',
  'bin', 'sbin', 'usr', 'etc', 'var', 'opt', 'applications',
  '.spotlight-v100', '.fseventsd', '.documentrevisions-v100',
  'photos library.photoslibrary', 'cloudstorage',
  'saved application state', 'saved application state',
  'containers', 'group containers', 'webkit', 'google', 'microsoft',
  'slack', 'discord', 'zoom.us', 'code cache', 'gpuarchives',
  'appdata', 'program files', 'program files (x86)', 'windows',
  '$recycle.bin', 'system volume information', 'recovery',
  'perflogs', 'programdata', 'msocache',
]);

/** Subcarpetas de ~/Library que se omiten (el resto de Library sí se escanea) */
const SKIP_LIBRARY_CHILDREN = new Set([
  'caches', 'logs', 'saved application state', 'containers',
  'group containers', 'webkit', 'com.apple.bird', 'mail', 'messages',
  'safari', 'calendars', 'identityservices', 'homekit', 'sharing',
]);

function isAudioFile(name) {
  return AUDIO_EXTENSIONS.has(path.extname(name).slice(1).toLowerCase());
}

function shouldSkipDir(dirPath, name) {
  const lower = name.toLowerCase();
  if (!name || lower === '.' || lower === '..') return true;
  if (name.startsWith('.') && lower !== '.public') return true;
  if (SKIP_DIR_NAMES.has(lower)) return true;

  const normalized = dirPath.replace(/\\/g, '/');
  if (normalized.includes('/Library/')) {
    const libChild = normalized.split('/Library/')[1]?.split('/')[0]?.toLowerCase();
    if (libChild && SKIP_LIBRARY_CHILDREN.has(libChild)) return true;
  }

  // No entrar en paquetes .app / .photoslibrary
  if (lower.endsWith('.app') || lower.endsWith('.photoslibrary') || lower.endsWith('.bundle')) {
    return true;
  }

  return false;
}

function dedupePaths(paths) {
  const seen = new Set();
  const out = [];
  for (const p of paths) {
    if (!p) continue;
    const resolved = path.resolve(p);
    if (seen.has(resolved)) continue;
    seen.add(resolved);
    try {
      if (fs.existsSync(resolved) && fs.statSync(resolved).isDirectory()) {
        out.push(resolved);
      }
    } catch {
      // omitir
    }
  }
  return out;
}

function yieldToLoop() {
  return new Promise((resolve) => setImmediate(resolve));
}

/**
 * Recorre carpetas en anchura con progreso y sin bloquear el hilo principal.
 * Solo devuelve metadatos (ruta, nombre, tamaño) — no lee el contenido.
 */
async function scanMusicPaths(paths, onProgress) {
  const queue = dedupePaths(paths);
  const results = [];
  const seenPaths = new Set();
  const seenDirs = new Set();
  let foldersScanned = 0;
  let lastProgressAt = 0;

  const report = (current) => {
    const now = Date.now();
    if (now - lastProgressAt < 80 && foldersScanned % 5 !== 0) return;
    lastProgressAt = now;
    onProgress?.({
      phase: 'discovering',
      current: current || 'Escaneando…',
      foldersScanned,
      audioFound: results.length,
    });
  };

  report('Iniciando escaneo…');

  while (queue.length > 0) {
    const dir = queue.shift();
    if (!dir || seenDirs.has(dir)) continue;
    seenDirs.add(dir);

    let entries;
    try {
      entries = await fsp.readdir(dir, { withFileTypes: true });
    } catch {
      continue;
    }

    foldersScanned += 1;
    report(dir);

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        if (!shouldSkipDir(fullPath, entry.name)) {
          queue.push(fullPath);
        }
      } else if (entry.isFile() && isAudioFile(entry.name)) {
        if (seenPaths.has(fullPath)) continue;
        seenPaths.add(fullPath);
        try {
          const stat = await fsp.stat(fullPath);
          results.push({
            path: fullPath,
            name: entry.name,
            size: stat.size,
            mtime: stat.mtimeMs,
          });
          if (results.length % 25 === 0) report(fullPath);
        } catch {
          // sin permiso o archivo temporal
        }
      }
    }

    if (foldersScanned % 12 === 0) {
      await yieldToLoop();
    }
  }

  onProgress?.({
    phase: 'discovering',
    current: `${results.length} archivos de audio encontrados`,
    foldersScanned,
    audioFound: results.length,
  });

  return results;
}

module.exports = {
  AUDIO_EXTENSIONS,
  dedupePaths,
  scanMusicPaths,
};
