# Ultrawide (32:9)

Measured on a 5120×1440 120 Hz panel with FiveM at 1920×1080 windowed.

## What this pack does

Feeder writes the neural result back into the **game** swapchain. 16:9
stays 16:9. Black bars / a centered window are the desktop compositor,
not a stretch.

`NREnableUpscaling=0` stops RenoDX from targeting native monitor size.

## What stretches

kibblerz DLSS5 ReShade AIO (`standalone-dlssnr.addon64`) presents at
display native. 1920×1080 becomes a full 5120×1440 fill. Aspect-fit
would be 2560×1440 with 1280 px pillarbox. That compositor lives in the
AIO binary, not in `ReShade.ini`.

Do not load AIO and Feeder together.

## Do not “fix” stretch by editing GTA settings

`%APPDATA%\CitizenFX\gta5_settings.xml` is the game resolution. This pack
does not touch it.
