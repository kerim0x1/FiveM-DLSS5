# stack/fivem

Drop-in copy of a working

`%LOCALAPPDATA%\FiveM\FiveM.app\plugins`

tree. The installer deploys this folder. It is the source of truth, not
a fresh download of Feeder.

Refresh:

```powershell
.\scripts\Sync-FromPlugins.ps1
```

Logs and `*.bak` are excluded. `ReShade.ini` is scrubbed of machine-local
cache paths on sync.

Files that must not be pushed are listed in the repo `.gitignore`
(NVIDIA, RenoDX, ReShade DLL, LumeniteFX). They still belong in a local
snapshot so Install-FiveMDLSS5.ps1 can copy a complete tree.
