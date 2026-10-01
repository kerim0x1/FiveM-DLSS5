# Architecture

## Pipeline

```text
game color (swapchain)
        │
        ▼
ReShade 6.8+  (FiveM: plugins\d3d11.dll)
        │
        ├─ Lumenite Kernel     motion + depth helpers
        │
        ▼
DLSS5_Feed.fx                  publishes color, MV, depth, mask
        │
        ▼
dlss5-feed.addon64             synthetic DLAA contract (NGX SuperSampling)
        │
        ▼
renodx-dlss5.addon64           neural pass on that contract
        │
        ▼
write-back into the same backbuffer
```

The feeder does not own a native compositor. Output size equals the game
swapchain. On a 5120×1440 monitor with the game at 1920×1080, the picture
stays 16:9.

## Why helper mode is banned here

`dlss5-feed-helper.addon64` + `host64\` exists for 64-bit processes that
cannot run NGX (shadPS4) and for 32-bit games. It supports D3D10/11,
OpenGL, Vulkan. **Not Direct3D 12.** FiveM is D3D12. If both add-ons sit
in `plugins`, in-process `addon64` stands down.

## Why Steam GTA V is the wrong folder

```text
Steam\...\GTA5.exe     + dxgi.dll     →  story-mode ReShade
FiveM.app\plugins\d3d11.dll           →  FiveM ReShade
```

`Verify-DLSS5Feeder.ps1` next to `GTA5.exe` can print 18 OK and still
leave FiveM untouched.

## Ultrawide

AIO-style add-ons composite to the monitor native size, which stretches
16:9 to 32:9. This pack keeps `NREnableUpscaling=0` so RenoDX does not
invent a native fill either.

## Motion vectors

`DLSS5_MV_PROVIDER=3` (Lumenite Kernel). Kernel must run **before** Feed.
QuantMotion (`provider=4`) is shipped in the shader tree but is not the
compiled provider unless you change the preprocessor definition.
