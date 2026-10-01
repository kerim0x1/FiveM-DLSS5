# Troubleshooting

Read `plugins\dlss5-feed.log` and `plugins\ReShade.log` first.

## Looks like vanilla 1080p

Feeder is running without a neural consumer, or RenoDX never armed.

- `renodx-dlss5.addon64` must sit next to `dlss5-feed.addon64`
- Overlay → Add-ons → both loaded
- Log line: `renodx-dlss5.addon64 v…`
- Log line: `frame N delivered`

## Verify is green, FiveM is not

The script was run next to Steam `GTA5.exe`. FiveM loads
`FiveM.app\plugins`. Run `Verify-FiveMDLSS5.ps1 -Client FiveM`.

## Stretched on 32:9

AIO compositor or `NREnableUpscaling=1`. This pack ships upscaling off.
Remove `standalone-dlssnr.addon64`.

## Overlay says Feed compiled for provider 2

VORT is not in this snapshot. Set `DLSS5_MV_PROVIDER=3` in
`[DLSS5_Feed.fx]` and in `[GENERAL] PreprocessorDefinitions`, then reload.

## CreateFeature 0xC0000005 in renodx-dlss5

Caught by the feeder; after that it refuses to call into RenoDX again
(deadlock). **Fully restart** the game. Do not toggle the feeder off/on
in the same session.

`NRStyle=2` has crashed on some present paths. The live snapshot uses
`NRStyle=0`.

## Two copies of nvngx_dlss.dll

Game-local `nvngx_dlss.dll` plus the driver `_nvngx.dll`. RenoDX hooks
both. If create keeps failing, remove the game-local DLSS DLL or update
RenoDX (v4.7+ / v8.x).

## Neural only on RTX 50

Signed `nvngx_dlssnr.dll` 310.8 creates feature 18 on 50-series only.
Older GPUs need a Discord build of that DLL.

## Depth probe flat / MV 0%

Generic Depth is on the wrong buffer, or you are standing still. Overlay
→ Add-ons → Generic Depth. Move the camera; MV should become non-zero.

## Helper add-on in plugins

Delete `dlss5-feed-helper.addon64` and `host64\`. FiveM is D3D12.
