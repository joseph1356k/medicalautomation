# Ejecutar como app de escritorio

## 1) Instalar dependencias
```powershell
npm install
```

## 2) Abrir como aplicación (desarrollo)
```powershell
npm run dev
```

Esto abre el sitio en una ventana nativa de escritorio (Electron), no en una pestaña del navegador.

## 3) Generar instalador para macOS
```powershell
npm run build:mac
```

Salida esperada: carpeta `dist/` con archivo `.dmg` para instalar la app en Mac.

## 4) Generar instalador para Windows
```powershell
npm run build:win
```

Salida esperada: carpeta `dist/` con instalador `.exe`.
