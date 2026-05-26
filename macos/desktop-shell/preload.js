const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  isDesktop: true,
  platform: process.platform,

  getDefaultMusicPaths: () => ipcRenderer.invoke('get-default-music-paths'),
  requestFullScanAccess: () => ipcRenderer.invoke('request-full-scan-access'),
  openFullDiskSettings: () => ipcRenderer.invoke('open-full-disk-settings'),
  pickMusicFolder: () => ipcRenderer.invoke('pick-music-folder'),

  scanMusicPaths: (paths, onProgress) => {
    const progressHandler = (_event, data) => onProgress?.(data);
    if (onProgress) ipcRenderer.on('scan:progress', progressHandler);
    return ipcRenderer
      .invoke('scan-music-paths', paths)
      .finally(() => ipcRenderer.removeListener('scan:progress', progressHandler));
  },

  readLocalFile: (filePath) => ipcRenderer.invoke('read-local-file', filePath),
  getLocalFileUrl: (filePath) => ipcRenderer.invoke('get-local-file-url', filePath),
  sendPlayerState: (state) => ipcRenderer.send('player-state', state),

  onNotchCommand: (callback) => {
    const listener = (_event, command) => callback(command);
    ipcRenderer.on('notch:command', listener);
    return () => ipcRenderer.removeListener('notch:command', listener);
  },
});
