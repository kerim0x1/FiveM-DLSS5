# Fehlerbehebung

Zuerst `plugins\dlss5-feed.log` und `plugins\ReShade.log` lesen.

## Sieht aus wie normales 1080p

Kein Neural-Consumer. `renodx-dlss5.addon64` muss neben dem Feeder liegen.

## Verify ist grün, FiveM nicht

Das Skript lief neben Steam-`GTA5.exe`. FiveM lädt nur
`FiveM.app\plugins`. `Verify-FiveMDLSS5.ps1 -Client FiveM` nutzen.

## Bild auf 32:9 gestreckt

AIO (`standalone-dlssnr.addon64`) oder `NREnableUpscaling=1`. Beides
entfernen bzw. auf 0 setzen.

## Feed kompiliert für Provider 2 (VORT)

`DLSS5_MV_PROVIDER=3` setzen. VORT ist in diesem Snapshot nicht drin.

## CreateFeature 0xC0000005

Spiel **komplett neu starten**. Feeder nach dem Catch nicht im selben
Lauf wieder einschalten.

## Helper / host64 im plugins-Ordner

Löschen. FiveM ist D3D12, Helper kann das nicht.
