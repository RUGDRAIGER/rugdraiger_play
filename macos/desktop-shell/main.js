const fs = require('fs');
const fsp = fs.promises;
const path = require('path');
const os = require('os');
const { pathToFileURL } = require('url');
const {
  app,
  BrowserWindow,
  ipcMain,
  shell,
  dialog,
  screen,
  nativeImage,
} = require('electron');
const { scanMusicPaths, dedupePaths } = require('./scanner');

const isDev = !app.isPackaged;
const APP_NAME = 'Rugdraiger Play';

/** Carpetas estándar del Mac: Escritorio, Documentos, Descargas, Videos, Imágenes, Música */
const STANDARD_FOLDER_KEYS = ['desktop', 'documents', 'downloads', 'videos', 'pictures', 'music'];

const STANDARD_FOLDER_LABELS = {
  desktop: 'Escritorio',
  documents: 'Documentos',
  downloads: 'Descargas',
  videos: 'Videos',
  pictures: 'Imágenes',
  music: 'Música',
};

let mainWin = null;
let notchWin = null;
let playerState = { hasTrack: false, title: '', artist: '', isPlaying: false, artwork: '' };
let grantedScanRoots = [];

function assetPath(...parts) {
  return path.join(__dirname, ...parts);
}

function distIndexPath() {
  return isDev
    ? path.join(__dirname, '../../../web/dist/index.html')
    : path.join(process.resourcesPath, 'dist/index.html');
}

function getStandardScanPaths(extraPaths = []) {
  const paths = [];
  for (const key of STANDARD_FOLDER_KEYS) {
    try {
      const folderPath = app.getPath(key);
      if (folderPath) paths.push(folderPath);
    } catch {
      // carpeta no disponible en este sistema
    }
  }
  return dedupePaths([...paths, ...extraPaths]);
}

function getStandardScanLabels() {
  return STANDARD_FOLDER_KEYS.map((key) => STANDARD_FOLDER_LABELS[key]).join(', ');
}

function getDefaultMusicPaths() {
  return getStandardScanPaths(grantedScanRoots);
}

async function requestFullScanAccess() {
  const folderList = getStandardScanLabels();
  const result = await dialog.showMessageBox(mainWin, {
    type: 'question',
    title: 'Autorización para escanear tu dispositivo',
    message: '¿Permites que Rugdraiger Play busque música en tu Mac?',
    detail:
      `Se escanearán automáticamente estas carpetas:\n\n${folderList}\n\n` +
      'macOS puede pedir permiso adicional. Si faltan archivos, activa Rugdraiger Play en ' +
      'Ajustes del Sistema → Privacidad y seguridad → Acceso total al disco.',
    buttons: ['Autorizar y escanear', 'Cancelar'],
    defaultId: 0,
    cancelId: 1,
  });

  if (result.response === 1) {
    return { granted: false, paths: [] };
  }

  const paths = getStandardScanPaths();
  if (paths.length === 0) {
    return { granted: false, paths: [] };
  }

  grantedScanRoots = dedupePaths([...grantedScanRoots, ...paths]);
  return { granted: true, paths };
}

function openFullDiskAccessSettings() {
  shell.openExternal(
    'x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles',
  );
}

function setDockIcon() {
  if (process.platform !== 'darwin') return;
  const icns = assetPath('assets', 'app-icon.icns');
  const iconPath = fs.existsSync(icns) ? icns : assetPath('assets', 'app-icon.png');
  if (!fs.existsSync(iconPath)) return;
  const icon = nativeImage.createFromPath(iconPath);
  if (icon && !icon.isEmpty()) app.dock.setIcon(icon);
}

function getNotchBounds(preferredWindow) {
  const ref =
    preferredWindow && !preferredWindow.isDestroyed()
      ? preferredWindow.getBounds()
      : screen.getPrimaryDisplay().bounds;
  const display = screen.getDisplayMatching(ref);
  const { x, width } = display.bounds;
  const NOTCH_W = 300;
  const NOTCH_H = 58;
  return {
    x: Math.round(x + (width - NOTCH_W) / 2),
    y: Math.round(display.workArea.y + 6),
    width: NOTCH_W,
    height: NOTCH_H,
  };
}

function positionNotchWindow() {
  if (!notchWin || notchWin.isDestroyed()) return;
  notchWin.setBounds(getNotchBounds(mainWin));
}

function updateNotchVisibility() {
  if (!notchWin || process.platform !== 'darwin') return;
  if (!mainWin) {
    notchWin.hide();
    return;
  }

  const appInForeground = mainWin.isFocused() && mainWin.isVisible() && !mainWin.isMinimized();
  const shouldShow = playerState.hasTrack && !appInForeground && (mainWin.isMinimized() || !mainWin.isFocused());

  if (shouldShow) {
    positionNotchWindow();
    if (!notchWin.isVisible()) notchWin.showInactive();
    notchWin.webContents.send('notch:state', playerState);
  } else {
    notchWin.hide();
  }
}

function focusMainWindow() {
  if (!mainWin) return;
  if (mainWin.isMinimized()) mainWin.restore();
  if (!mainWin.isMaximized()) mainWin.maximize();
  mainWin.show();
  mainWin.focus();
  if (notchWin?.isVisible()) notchWin.hide();
  updateNotchVisibility();
}

function createNotchWindow() {
  if (process.platform !== 'darwin') return;
  const bounds = getNotchBounds(null);

  notchWin = new BrowserWindow({
    width: bounds.width,
    height: bounds.height,
    x: bounds.x,
    y: bounds.y,
    frame: false,
    transparent: true,
    alwaysOnTop: true,
    skipTaskbar: true,
    hasShadow: false,
    resizable: false,
    movable: false,
    minimizable: false,
    maximizable: false,
    fullscreenable: false,
    focusable: true,
    show: false,
    type: 'panel',
    webPreferences: {
      preload: path.join(__dirname, 'notchPreload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  notchWin.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true });
  notchWin.loadFile(path.join(__dirname, 'notch.html'));
}

function createWindow() {
  const iconPath = fs.existsSync(assetPath('assets', 'app-icon.icns'))
    ? assetPath('assets', 'app-icon.icns')
    : assetPath('assets', 'app-icon.png');

  mainWin = new BrowserWindow({
    width: 1280,
    height: 800,
    minWidth: 900,
    minHeight: 640,
    backgroundColor: '#0A0A0A',
    title: APP_NAME,
    icon: iconPath,
    autoHideMenuBar: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  mainWin.loadFile(distIndexPath()).catch(console.error);
  mainWin.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });

  for (const ev of ['focus', 'blur', 'minimize', 'restore', 'show', 'hide']) {
    mainWin.on(ev, () => {
      if (ev === 'focus' || ev === 'restore' || ev === 'show') {
        if (notchWin?.isVisible()) notchWin.hide();
      }
      updateNotchVisibility();
    });
  }
}

function registerIpc() {
  ipcMain.handle('get-default-music-paths', () => getDefaultMusicPaths());

  ipcMain.handle('request-full-scan-access', () => requestFullScanAccess());

  ipcMain.handle('open-full-disk-settings', () => {
    openFullDiskAccessSettings();
    return true;
  });

  ipcMain.handle('pick-music-folder', async () => {
    const result = await dialog.showOpenDialog(mainWin, {
      title: 'Elegir carpeta de música',
      properties: ['openDirectory'],
      defaultPath: os.homedir(),
    });
    if (result.canceled || !result.filePaths.length) return null;
    grantedScanRoots = dedupePaths([...grantedScanRoots, result.filePaths[0]]);
    return result.filePaths[0];
  });

  ipcMain.handle('scan-music-paths', async (event, paths) => {
    const sender = event.sender;
    return scanMusicPaths(paths || [], (progress) => {
      if (!sender.isDestroyed()) {
        sender.send('scan:progress', progress);
      }
    });
  });

  ipcMain.handle('read-local-file', async (_event, filePath) => {
    const stat = await fsp.stat(filePath);
    if (stat.size > 400 * 1024 * 1024) {
      throw new Error('Archivo demasiado grande para leer metadatos');
    }
    const buffer = await fsp.readFile(filePath);
    return buffer.buffer.slice(buffer.byteOffset, buffer.byteOffset + buffer.byteLength);
  });

  ipcMain.handle('get-local-file-url', (_event, filePath) => pathToFileURL(filePath).href);

  ipcMain.on('player-state', (_event, state) => {
    playerState = {
      hasTrack: !!state?.hasTrack,
      title: state?.title || '',
      artist: state?.artist || '',
      isPlaying: !!state?.isPlaying,
      artwork: state?.artwork || '',
    };
    updateNotchVisibility();
    if (notchWin?.isVisible()) notchWin.webContents.send('notch:state', playerState);
  });

  ipcMain.on('notch-command', (_event, command) => {
    if (!mainWin) return;
    if (command === 'focus') {
      focusMainWindow();
      mainWin.webContents.send('notch:command', command);
      return;
    }
    mainWin.webContents.send('notch:command', command);
  });
}

app.whenReady().then(() => {
  registerIpc();
  setDockIcon();
  createWindow();
  createNotchWindow();
  screen.on('display-metrics-changed', () => positionNotchWindow());
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) createWindow();
});
