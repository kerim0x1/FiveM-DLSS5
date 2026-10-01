# Contributing

Contact: contact@kerim0x1.com

## Ground rules

- FiveM and RedM install into `*.app\plugins`. Never document Steam `GTA5.exe` as the FiveM target.
- Do not add `dlss5-feed-helper.addon64` or `host64\` to the default stack.
- Do not enable `NREnableUpscaling` in shipped `ReShade.ini`.
- Do not commit NVIDIA, RenoDX, ReShade, or LumeniteFX binaries/shaders.
- Keep scripts Windows PowerShell 5.1 compatible.

## Snapshot

The payload is `stack/fivem`, copied from a live plugins folder:

```powershell
.\scripts\Sync-FromPlugins.ps1
```

Review the diff before any commit. Scrub user paths.

## Pull requests

1. Describe the client you tested (FiveM build, GPU, driver).
2. Attach `dlss5-feed.log` and `ReShade.log` from `plugins`, not from Steam GTA V.
3. Run `.\scripts\Verify-FiveMDLSS5.ps1 -Client FiveM -NoPause`.
