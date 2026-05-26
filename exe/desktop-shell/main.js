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
const isMac = process.platform === 'darwin';
const isWin = process.platform === 'win32';

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
let overlayWin = null;
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
      // omitir
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
  const platformName = isMac ? 'Mac' : 'PC';
  const extra = isMac
    ? 'macOS puede pedir permiso adicional. Si faltan archivos, activa Rugdraiger Play en Ajustes del Sistema → Privacidad y seguridad → Acceso total al disco.'
    : 'Windows puede pedir permiso al acceder a algunas carpetas.';

  const result = await dialog.showMessageBox(mainWin, {
    type: 'question',
    title: 'Autorización para escanear tu dispositivo',
    message: `¿Permites que Rugdraiger Play busque música en tu ${platformName}?`,
    detail: `Se escanearán automáticamente estas carpetas:\n\n${folderList}\n\n${extra}`,
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

function openPrivacySettings() {
  if (isMac) {
    shell.openExternal(
      'x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles',
    );
  } else if (isWin) {
    shell.openExternal('ms-settings:privacy');
  }
}

function setDockIcon() {
  if (!isMac) return;
  const icns = assetPath('assets', 'app-icon.icns');
  const iconPath = fs.existsSync(icns) ? icns : assetPath('assets', 'app-icon.png');
  if (!fs.existsSync(iconPath)) return;
  const icon = nativeImage.createFromPath(iconPath);
  if (icon && !icon.isEmpty()) app.dock.setIcon(icon);
}

function getOverlayBounds(preferredWindow) {
  const ref =
    preferredWindow && !preferredWindow.isDestroyed()
      ? preferredWindow.getBounds()
      : screen.getPrimaryDisplay().bounds;
  const display = screen.getDisplayMatching(ref);
  const { x, width } = display.bounds;
  const OVERLAY_W = 300;
  const OVERLAY_H = 58;
  return {
    x: Math.round(x + (width - OVERLAY_W) / 2),
    y: Math.round(display.workArea.y + 6),
    width: OVERLAY_W,
    height: OVERLAY_H,
  };
}

function positionOverlayWindow() {
  if (!overlayWin || overlayWin.isDestroyed()) return;
  overlayWin.setBounds(getOverlayBounds(mainWin));
}

function updateOverlayVisibility() {
  if (!overlayWin) return;
  if (!mainWin) {
    overlayWin.hide();
    return;
  }

  const appInForeground = mainWin.isFocused() && mainWin.isVisible() && !mainWin.isMinimized();
  const shouldShow = playerState.hasTrack && !appInForeground && (mainWin.isMinimized() || !mainWin.isFocused());

  if (shouldShow) {
    positionOverlayWindow();
    if (!overlayWin.isVisible()) overlayWin.showInactive();
    overlayWin.webContents.send('notch:state', playerState);
  } else {
    overlayWin.hide();
  }
}

function focusMainWindow() {
  if (!mainWin) return;
  if (mainWin.isMinimized()) mainWin.restore();
  if (!mainWin.isMaximized()) mainWin.maximize();
  mainWin.show();
  mainWin.focus();
  if (overlayWin?.isVisible()) overlayWin.hide();
  updateOverlayVisibility();
}

function createOverlayWindow() {
  const bounds = getOverlayBounds(null);

  const winOpts = {
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
    webPreferences: {
      preload: path.join(__dirname, 'notchPreload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  };

  if (isMac) {
    winOpts.type = 'panel';
  }

  if (isWin) {
    winOpts.backgroundColor = '#00000000';
    winOpts.thickFrame = false;
  }

  overlayWin = new BrowserWindow(winOpts);

  if (isMac) {
    overlayWin.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true });
  }

  if (isWin) {
    overlayWin.setAlwaysOnTop(true, 'screen-saver');
    overlayWin.setVisibleOnAllWorkspaces(true);
  }

  overlayWin.loadFile(path.join(__dirname, 'notch.html'));
}

function createWindow() {
  const iconPath = fs.existsSync(assetPath('assets', 'app-icon.ico'))
    ? assetPath('assets', 'app-icon.ico')
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
        if (overlayWin?.isVisible()) overlayWin.hide();
      }
      updateOverlayVisibility();
    });
  }
}

function registerIpc() {
  ipcMain.handle('get-default-music-paths', () => getDefaultMusicPaths());
  ipcMain.handle('request-full-scan-access', () => requestFullScanAccess());
  ipcMain.handle('open-full-disk-settings', () => {
    openPrivacySettings();
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
    updateOverlayVisibility();
    if (overlayWin?.isVisible()) overlayWin.webContents.send('notch:state', playerState);
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
  createOverlayWindow();
  screen.on('display-metrics-changed', () => positionOverlayWindow());
});

app.on('window-all-closed', () => {
  if (!isMac) app.quit();
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) createWindow();
});
