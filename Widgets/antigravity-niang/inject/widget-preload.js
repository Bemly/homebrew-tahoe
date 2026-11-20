'use strict';

const { contextBridge, ipcRenderer } = require('electron');

let seq = 0;
function once(channel, payload) {
  return new Promise((resolve) => {
    const reply = 'gy:reply:' + ++seq;
    ipcRenderer.once(reply, (_e, result) => resolve(result));
    ipcRenderer.send(channel, payload ? Object.assign({}, payload, { channel: reply }) : { channel: reply });
  });
}

contextBridge.exposeInMainWorld('gyWidget', {
  onState(cb) {
    ipcRenderer.on('gy:state', (_e, state) => cb(state));
    ipcRenderer.invoke('gy:state');
  },
  selectCharacter: (id) => ipcRenderer.send('gy:select-character', id),
  setScale: (scale) => ipcRenderer.send('gy:set-scale', scale),
  refreshQuota: () => ipcRenderer.send('gy:refresh-quota'),
  contextMenu: () => ipcRenderer.send('gy:context-menu'),
  ready: (info) => ipcRenderer.send('gy:renderer-ready', info),
  setIgnoreMouse: (ignore) => ipcRenderer.send('gy:set-ignore-mouse', !!ignore),
  dragBy: (dx, dy) => ipcRenderer.send('gy:drag-by', { dx, dy }),
  importCharacter: () => once('gy:import-character'),
  removeCharacter: (id) => once('gy:remove-character', { id }),
  restoreCharacter: (id) => once('gy:restore-character', { id }),
});
