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
  net,
  protocol,
  session,
  safeStorage,
} = require('electron');
const { scanMusicPaths, dedupePaths } = require('./scanner');
const { assertAllowedPath, filterAllowedDirectories } = require('./pathSecurity');
const {
  buildApiUrl,
  fetchNavidromeLibrary,
  normalizeServerUrl,
  normalizeUsername,
  pingNavidrome,
  validatePassword,
} = require('./navidromeClient');
const { createNavidromeStore } = require('./navidromeStore');

const isDev = !app.isPackaged;
const APP_NAME = 'Rugdraiger Play';

/** Carpetas estándar donde normalmente se almacena música en macOS. */
const STANDARD_FOLDER_KEYS = ['desktop', 'documents', 'downloads', 'music'];

const STANDARD_FOLDER_LABELS = {
  desktop: 'Escritorio',
  documents: 'Documentos',
  downloads: 'Descargas',
  music: 'Música',
};

let mainWin = null;
let notchWin = null;
let playerState = { hasTrack: false, title: '', artist: '', isPlaying: false, artwork: '', accentColor: '#FF2020' };
let grantedScanRoots = [];
const navidromeStore = createNavidromeStore({
  configPath: () => path.join(app.getPath('userData'), 'navidrome-credentials.json'),
  safeStorage,
});

app.enableSandbox();
protocol.registerSchemesAsPrivileged([{
  scheme: 'rugdraiger-media',
  privileges: { standard: true, secure: true, supportFetchAPI: true, corsEnabled: true, stream: true },
}]);
const hasSingleInstanceLock = app.requestSingleInstanceLock();
if (!hasSingleInstanceLock) app.quit();
app.on('second-instance', () => focusMainWindow());

function assetPath(...parts) {
  return isDev
    ? path.join(__dirname, ...parts)
    : path.join(process.resourcesPath, 'app', ...parts);
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

function getPermittedRoots() {
  return getStandardScanPaths(grantedScanRoots);
}

function scanRootsFile() {
  return path.join(app.getPath('userData'), 'authorized-music-folders.json');
}

async function loadGrantedScanRoots() {
  try {
    const data = JSON.parse(await fsp.readFile(scanRootsFile(), 'utf8'));
    grantedScanRoots = dedupePaths(Array.isArray(data) ? data : []);
  } catch {
    grantedScanRoots = [];
  }
}

async function saveGrantedScanRoots() {
  const target = scanRootsFile();
  const temporary = `${target}.tmp`;
  await fsp.mkdir(path.dirname(target), { recursive: true });
  await fsp.writeFile(temporary, JSON.stringify(grantedScanRoots, null, 2), 'utf8');
  await fsp.rename(temporary, target);
}

function assertMainSender(event) {
  if (!mainWin || mainWin.isDestroyed() || event.sender !== mainWin.webContents) {
    throw new Error('Solicitud IPC rechazada');
  }
}

function isMainSender(event) {
  return !!mainWin && !mainWin.isDestroyed() && event.sender === mainWin.webContents;
}

function isNotchSender(event) {
  return !!notchWin && !notchWin.isDestroyed() && event.sender === notchWin.webContents;
}

function openExternalHttp(url) {
  try {
    const parsed = new URL(url);
    if (parsed.protocol === 'https:' || parsed.protocol === 'http:') {
      void shell.openExternal(parsed.href);
    }
  } catch {
    // URL externa inválida: se ignora.
  }
}

function registerNavidromeMediaProtocol() {
  protocol.handle('rugdraiger-media', async (request) => {
    try {
      if (request.method !== 'GET' && request.method !== 'HEAD') {
        return new Response('Método no permitido', { status: 405 });
      }
      const requested = new URL(request.url);
      const mediaId = decodeURIComponent(requested.pathname.replace(/^\/+/, ''));
      if (!mediaId || mediaId.length > 256) return new Response('ID inválido', { status: 400 });

      const credentials = await navidromeStore.getCredentials();
      if (!credentials) return new Response('Navidrome no está conectado', { status: 401 });

      let upstream;
      if (requested.hostname === 'stream') {
        upstream = buildApiUrl('stream', credentials, { id: mediaId, format: 'raw' });
      } else if (requested.hostname === 'cover') {
        const requestedSize = Number(requested.searchParams.get('size'));
        const size = Number.isFinite(requestedSize) ? Math.max(64, Math.min(1200, Math.round(requestedSize))) : 600;
        upstream = buildApiUrl('getCoverArt', credentials, { id: mediaId, size });
      } else {
        return new Response('Recurso no encontrado', { status: 404 });
      }

      const headers = {};
      const range = request.headers.get('range');
      if (range) headers.Range = range;
      const response = await net.fetch(upstream.href, {
        method: request.method,
        headers,
        bypassCustomProtocolHandlers: true,
      });
      const responseHeaders = new Headers(response.headers);
      responseHeaders.set('Access-Control-Allow-Origin', '*');
      responseHeaders.set('Cache-Control', requested.hostname === 'cover' ? 'private, max-age=86400' : 'no-store');
      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: responseHeaders,
      });
    } catch {
      return new Response('No se pudo recuperar el recurso de Navidrome', { status: 502 });
    }
  });
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
  const iconPath = assetPath('assets', 'app-icon.png');
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
  if (notchWin && !notchWin.isDestroyed()) return;
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
      sandbox: true,
    },
  });

  notchWin.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true });
  notchWin.loadFile(path.join(__dirname, 'notch.html'));
  notchWin.on('closed', () => {
    notchWin = null;
  });
}

function createWindow() {
  if (mainWin && !mainWin.isDestroyed()) return;
  const iconPath = assetPath('assets', 'app-icon.png');

  mainWin = new BrowserWindow({
    width: 1280,
    height: 800,
    minWidth: 900,
    minHeight: 640,
    backgroundColor: '#0A0A0A',
    title: APP_NAME,
    icon: iconPath,
    autoHideMenuBar: true,
    show: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
      backgroundThrottling: false,
    },
  });

  const showMainWindow = () => {
    if (mainWin && !mainWin.isDestroyed() && !mainWin.isVisible()) mainWin.show();
  };
  mainWin.once('ready-to-show', showMainWindow);
  mainWin.webContents.once('did-finish-load', showMainWindow);

  mainWin.loadFile(distIndexPath()).catch(console.error);
  mainWin.webContents.setWindowOpenHandler(({ url }) => {
    openExternalHttp(url);
    return { action: 'deny' };
  });
  mainWin.webContents.on('will-navigate', (event, url) => {
    const localIndex = pathToFileURL(distIndexPath()).href;
    if (url === localIndex || url.startsWith(`${localIndex}#`)) return;
    event.preventDefault();
    openExternalHttp(url);
  });
  mainWin.on('closed', () => {
    mainWin = null;
    if (notchWin && !notchWin.isDestroyed()) notchWin.destroy();
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
  ipcMain.handle('get-default-music-paths', (event) => {
    assertMainSender(event);
    return getDefaultMusicPaths();
  });

  ipcMain.handle('request-full-scan-access', (event) => {
    assertMainSender(event);
    return requestFullScanAccess();
  });

  ipcMain.handle('open-full-disk-settings', (event) => {
    assertMainSender(event);
    openFullDiskAccessSettings();
    return true;
  });

  ipcMain.handle('pick-music-folder', async (event) => {
    assertMainSender(event);
    const result = await dialog.showOpenDialog(mainWin, {
      title: 'Elegir carpeta de música',
      properties: ['openDirectory'],
      defaultPath: os.homedir(),
    });
    if (result.canceled || !result.filePaths.length) return null;
    grantedScanRoots = dedupePaths([...grantedScanRoots, result.filePaths[0]]);
    await saveGrantedScanRoots();
    return result.filePaths[0];
  });

  ipcMain.handle('scan-music-paths', async (event, paths) => {
    assertMainSender(event);
    const sender = event.sender;
    const safePaths = filterAllowedDirectories(
      Array.isArray(paths) ? paths : [],
      getPermittedRoots(),
    );
    if (safePaths.length === 0) throw new Error('No hay carpetas autorizadas para escanear');
    return scanMusicPaths(safePaths, (progress) => {
      if (!sender.isDestroyed()) {
        sender.send('scan:progress', progress);
      }
    });
  });

  ipcMain.handle('read-local-file', async (event, filePath) => {
    assertMainSender(event);
    const safePath = assertAllowedPath(filePath, getPermittedRoots(), 'file');
    const stat = await fsp.stat(safePath);
    const bytesToRead = Math.min(stat.size, 64 * 1024 * 1024);
    const file = await fsp.open(safePath, 'r');
    try {
      const buffer = Buffer.allocUnsafe(bytesToRead);
      const { bytesRead } = await file.read(buffer, 0, bytesToRead, 0);
      return buffer.buffer.slice(
        buffer.byteOffset,
        buffer.byteOffset + bytesRead,
      );
    } finally {
      await file.close();
    }
  });

  ipcMain.handle('get-local-file-url', (event, filePath) => {
    assertMainSender(event);
    const safePath = assertAllowedPath(filePath, getPermittedRoots(), 'file');
    return pathToFileURL(safePath).href;
  });

  ipcMain.handle('navidrome:get-config', async (event) => {
    assertMainSender(event);
    return navidromeStore.getPublicConfig();
  });

  ipcMain.handle('navidrome:connect', async (event, input) => {
    assertMainSender(event);
    const serverUrl = normalizeServerUrl(input?.serverUrl);
    const username = normalizeUsername(input?.username);
    let password = input?.password;

    if (!password) {
      const current = await navidromeStore.getCredentials();
      if (!current || current.serverUrl !== serverUrl || current.username !== username) {
        throw new Error('Ingresa la contraseña para esta cuenta de Navidrome');
      }
      password = current.password;
    }
    validatePassword(password);

    const credentials = { serverUrl, username, password };
    const connectionInfo = await pingNavidrome(credentials);
    const config = await navidromeStore.saveCredentials(credentials, connectionInfo);
    return { config, connectionInfo };
  });

  ipcMain.handle('navidrome:test', async (event) => {
    assertMainSender(event);
    const credentials = await navidromeStore.getCredentials();
    if (!credentials) throw new Error('Todavía no hay una cuenta Navidrome guardada');
    const connectionInfo = await pingNavidrome(credentials);
    const config = await navidromeStore.saveCredentials(credentials, connectionInfo);
    return { config, connectionInfo };
  });

  ipcMain.handle('navidrome:sync-library', async (event) => {
    assertMainSender(event);
    const credentials = await navidromeStore.getCredentials();
    if (!credentials) throw new Error('Conecta una cuenta Navidrome antes de sincronizar');
    const sender = event.sender;
    return fetchNavidromeLibrary(credentials, (progress) => {
      if (!sender.isDestroyed()) sender.send('navidrome:sync-progress', progress);
    });
  });

  ipcMain.handle('navidrome:disconnect', async (event) => {
    assertMainSender(event);
    await navidromeStore.clear();
    return navidromeStore.getPublicConfig();
  });

  ipcMain.on('player-state', (event, state) => {
    if (!isMainSender(event)) return;
    playerState = {
      hasTrack: !!state?.hasTrack,
      title: state?.title || '',
      artist: state?.artist || '',
      isPlaying: !!state?.isPlaying,
      artwork: state?.artwork || '',
      accentColor: state?.accentColor || '#FF2020',
    };
    updateNotchVisibility();
    if (notchWin?.isVisible()) notchWin.webContents.send('notch:state', playerState);
  });

  ipcMain.on('notch-command', (event, command) => {
    if (!isNotchSender(event)) return;
    if (!mainWin) return;
    if (command === 'focus') {
      focusMainWindow();
      mainWin.webContents.send('notch:command', command);
      return;
    }
    mainWin.webContents.send('notch:command', command);
  });
}

app.whenReady().then(async () => {
  app.setName(APP_NAME);
  await loadGrantedScanRoots();
  registerNavidromeMediaProtocol();
  session.defaultSession.setPermissionRequestHandler((_webContents, _permission, callback) => {
    callback(false);
  });
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
  if (!mainWin || mainWin.isDestroyed()) createWindow();
  if (!notchWin || notchWin.isDestroyed()) createNotchWindow();
});
