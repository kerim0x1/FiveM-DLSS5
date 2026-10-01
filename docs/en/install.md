# Install

## FiveM — one zip into plugins

1. Close FiveM completely.
2. Download `FiveM-DLSS5-1.0.0-plugins.zip` from Releases.
3. Extract the **contents** into:

```text
%LOCALAPPDATA%\FiveM\FiveM.app\plugins
```

Run dialog: `Win + R` → `%LOCALAPPDATA%\FiveM\FiveM.app\plugins` → Enter.

4. Launch FiveM. **Home**. Kernel above Feed. Keys **1–4**.

Do not drop the zip next to Steam `GTA5.exe`.

## Maintainers / other clients

```powershell
.\scripts\Pack-FiveMRelease.ps1
.\scripts\Install-FiveMDLSS5.ps1 -Client RedM -Yes -Force
```
