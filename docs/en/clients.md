# Clients

Profiles live in `profiles/*.json`. The installer reads them; it does not
guess Steam `GTA5.exe`.

## FiveM

| | |
|---|---|
| Folder | `%LOCALAPPDATA%\FiveM\FiveM.app\plugins` |
| ReShade | `d3d11.dll` |
| Process | `FiveM_bXXXX_GTAProcess.exe` |
| API | Direct3D 12, 64-bit |
| Helper | forbidden |

CitizenFX.ini `IVPath` may point at Steam GTA V. That is the *content*
path. ReShade still loads from `plugins`. Installing next to `GTA5.exe`
never reaches the FiveM process.

## RedM

Same CitizenFX injection as FiveM, under `%LOCALAPPDATA%\RedM\RedM.app\plugins`.

## RageMP

Default guess: `C:\RAGEMP`. Pass `-Target` for a custom root. ReShade
file name: `d3d11.dll`. Confirm with `Verify-FiveMDLSS5.ps1` after the
first boot.

## alt:V

ReShade file name: `dxgi.dll` next to `altv.exe`. The installer renames
the snapshot's `d3d11.dll` on copy.

## Generic

`-Target` is required. 64-bit only. Helper mode is still refused. For
32-bit games use upstream Feeder.

## Do not mix

- `dlss5-feed.addon64` and `dlss5-feed-helper.addon64`
- Feeder and `standalone-dlssnr.addon64` (kibblerz AIO)
- Two neural consumers (RenoDX + Deep Fried Chicken)
