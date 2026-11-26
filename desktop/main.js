// DevRealm 桌面套壳主进程（Electron）
// 仅把现有单文件 index.html 装进桌面窗口，业务逻辑仍在前端页面内。
const { app, BrowserWindow, shell } = require('electron');
const path = require('path');

function createWindow() {
  const win = new BrowserWindow({
    width: 1280,
    height: 860,
    minWidth: 960,
    minHeight: 640,
    backgroundColor: '#0f0d1d',
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true
    }
  });

  // 加载仓库根目录的单文件前端
  win.loadFile(path.join(__dirname, '..', 'index.html'));

  // 外部链接交给系统浏览器打开，不在套壳窗口内跳转
  win.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
