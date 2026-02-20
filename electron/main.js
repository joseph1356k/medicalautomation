const path = require("path");
const { app, BrowserWindow, shell } = require("electron");

function createWindow() {
  const mainWindow = new BrowserWindow({
    width: 1366,
    height: 860,
    minWidth: 980,
    minHeight: 680,
    autoHideMenuBar: true,
    title: "Daiwo Coffee",
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  mainWindow.loadFile(path.join(__dirname, "..", "index.html"));

  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: "deny" };
  });
}

app.whenReady().then(() => {
  createWindow();

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});
