// 预加载脚本：在渲染进程暴露受限的本地文件接口。
// 网页版（浏览器）下 window.devRealmAPI 不存在，前端自动降级为本地存储 / 云端。
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('devRealmAPI', {
  saveProject: (payload) => ipcRenderer.invoke('project:save', payload),
  openProject: () => ipcRenderer.invoke('project:open'),
  pickResource: () => ipcRenderer.invoke('resources:pick'),
  listResources: () => ipcRenderer.invoke('resources:listDir'),
  isDesktop: true
});
