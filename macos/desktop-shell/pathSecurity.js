const fs = require('fs');
const path = require('path');

function realPath(targetPath) {
  if (typeof targetPath !== 'string' || targetPath.length === 0 || targetPath.length > 4096) {
    throw new TypeError('Ruta local inválida');
  }
  return fs.realpathSync.native(path.resolve(targetPath));
}

function isWithinRoot(targetPath, rootPath) {
  const relative = path.relative(rootPath, targetPath);
  return (
    relative === '' ||
    (relative !== '..' && !relative.startsWith(`..${path.sep}`) && !path.isAbsolute(relative))
  );
}

function allowedRealRoots(roots) {
  const result = [];
  for (const root of roots || []) {
    try {
      const resolved = realPath(root);
      if (fs.statSync(resolved).isDirectory() && !result.includes(resolved)) result.push(resolved);
    } catch {
      // La carpeta pudo desaparecer o no estar autorizada por macOS.
    }
  }
  return result;
}

function assertAllowedPath(targetPath, roots, expectedType = 'file') {
  const resolved = realPath(targetPath);
  const permitted = allowedRealRoots(roots).some((root) => isWithinRoot(resolved, root));
  if (!permitted) throw new Error('Acceso denegado: la ruta está fuera de las carpetas autorizadas');

  const stat = fs.statSync(resolved);
  if (expectedType === 'directory' && !stat.isDirectory()) {
    throw new Error('La ruta autorizada no es una carpeta');
  }
  if (expectedType === 'file' && !stat.isFile()) {
    throw new Error('La ruta autorizada no es un archivo');
  }
  return resolved;
}

function filterAllowedDirectories(paths, roots) {
  const result = [];
  for (const candidate of paths || []) {
    try {
      const resolved = assertAllowedPath(candidate, roots, 'directory');
      if (!result.includes(resolved)) result.push(resolved);
    } catch {
      // Las rutas inyectadas o inaccesibles se descartan.
    }
  }
  return result;
}

module.exports = {
  allowedRealRoots,
  assertAllowedPath,
  filterAllowedDirectories,
  isWithinRoot,
};
