const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('notchAPI', {
  sendCommand: (command) => ipcRenderer.send('notch-command', command),
  onState: (callback) => {
    const listener = (_event, state) => callback(state);
    ipcRenderer.on('notch:state', listener);
    return () => ipcRenderer.removeListener('notch:state', listener);
  },
});
