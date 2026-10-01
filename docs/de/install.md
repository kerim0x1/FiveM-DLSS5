# Installation

## FiveM — ein Zip, in plugins ziehen

1. FiveM **komplett** schließen.
2. Von Releases herunterladen: `FiveM-DLSS5-1.0.0-plugins.zip`
3. Inhalt entpacken nach:

```text
%LOCALAPPDATA%\FiveM\FiveM.app\plugins
```

`Win + R` → `%LOCALAPPDATA%\FiveM\FiveM.app\plugins` → Enter.

4. FiveM starten. **Home**. Kernel über Feed. Tasten **1–4**.

Nicht neben `GTA5.exe` in Steam legen.

## Maintainer / andere Clients

```powershell
.\scripts\Pack-FiveMRelease.ps1
.\scripts\Install-FiveMDLSS5.ps1 -Client RedM -Yes -Force
```
