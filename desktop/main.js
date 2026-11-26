// DevRealm 桌面套壳主进程（Electron）
// 仅把现有单文件 index.html 装进桌面窗口，并通过 IPC 提供本地文件读写能力；
// 业务逻辑仍在前端页面内，网页版打开时这些接口不存在，前端自动降级。
const { app, BrowserWindow, shell, ipcMain, dialog } = require('electron');
const path = require('path');
const fs = require('fs');

let win = null;

function createWindow() {
  win = new BrowserWindow({
    width: 1280,
    height: 860,
    minWidth: 960,
    minHeight: 640,
    backgroundColor: '#0f0d1d',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
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

// 导出工程到本地 JSON 文件
ipcMain.handle('project:save', async (_e, payload) => {
  try {
    const { canceled, filePath } = await dialog.showSaveDialog(win, {
      defaultFileName: (payload && payload.name || 'project') + '.json',
      filters: [{ name: 'JSON', extensions: ['json'] }]
    });
    if (canceled || !filePath) return { ok: false };
    fs.writeFileSync(filePath, String(payload.content || ''), 'utf-8');
    return { ok: true, path: filePath };
  } catch (err) {
    return { ok: false, error: String(err && err.message || err) };
  }
});

// 从本地 JSON 文件打开工程
ipcMain.handle('project:open', async () => {
  try {
    const { canceled, filePaths } = await dialog.showOpenDialog(win, {
      filters: [{ name: 'JSON', extensions: ['json'] }],
      properties: ['openFile']
    });
    if (canceled || !filePaths || !filePaths.length) return { ok: false };
    const content = fs.readFileSync(filePaths[0], 'utf-8');
    return { ok: true, path: filePaths[0], content };
  } catch (err) {
    return { ok: false, error: String(err && err.message || err) };
  }
});

// 选择本地文件夹，列出其中图片 / 模型资源（小文件读成 dataURL）
ipcMain.handle('resources:listDir', async () => {
  try {
    const { canceled, filePaths } = await dialog.showOpenDialog(win, { properties: ['openDirectory'] });
    if (canceled || !filePaths || !filePaths.length) return { ok: false };
    const dir = filePaths[0];
    const exts = ['png', 'jpg', 'jpeg', 'glb', 'gltf'];
    const files = fs.readdirSync(dir).filter(f => exts.includes(path.extname(f).slice(1).toLowerCase())).slice(0, 30).map(f => {
      const p = path.join(dir, f);
      const ext = path.extname(f).slice(1).toLowerCase();
      const mime = ext === 'png' ? 'image/png'
        : ext === 'glb' ? 'model/gltf-binary'
        : ext === 'gltf' ? 'model/gltf+json' : 'image/jpeg';
      let dataUrl = '';
      try { const buf = fs.readFileSync(p); if (buf.length < 2 * 1024 * 1024) dataUrl = 'data:' + mime + ';base64,' + buf.toString('base64'); } catch (_) {}
      return { name: f, path: p, type: (ext === 'glb' || ext === 'gltf') ? 'model' : 'image', dataUrl };
    });
    return { ok: true, dir, files };
  } catch (err) {
    return { ok: false, error: String(err && err.message || err) };
  }
});

// 选择本地资源文件（图片 / 模型），读成 dataURL 交回前端
ipcMain.handle('resources:pick', async () => {
  try {
    const { canceled, filePaths } = await dialog.showOpenDialog(win, {
      properties: ['openFile'],
      filters: [{ name: 'Media', extensions: ['png', 'jpg', 'jpeg', 'glb', 'gltf'] }]
    });
    if (canceled || !filePaths || !filePaths.length) return { ok: false };
    const p = filePaths[0];
    const ext = path.extname(p).slice(1).toLowerCase();
    const mime = ext === 'png' ? 'image/png'
      : ext === 'glb' ? 'model/gltf-binary'
      : ext === 'gltf' ? 'model/gltf+json' : 'image/jpeg';
    const buf = fs.readFileSync(p);
    return { ok: true, name: path.basename(p), path: p, dataUrl: 'data:' + mime + ';base64,' + buf.toString('base64') };
  } catch (err) {
    return { ok: false, error: String(err && err.message || err) };
  }
});

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
