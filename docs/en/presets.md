# Quality stages

ReShade presets in `stack/fivem` / `presets/`:

| File | Key | Techniques |
|---|---|---|
| `preset_1_balanced.ini` | 1 | Kernel, Feed |
| `preset_2_quality.ini` | 2 | + Anamorphic Bloom |
| `preset_3_high.ini` | 3 | + Bloom + LSAO |
| `preset_4_ultra.ini` | 4 | + Bloom + LSAO + RTAO + SSSR |

`ReShade.ini` wires:

- `PresetPath=.\preset_3_high.ini`
- `PresetShortcutKeys` 1–4
- `KeyNextPreset` Page Down, `KeyPreviousPreset` Page Up
- `ShowPresetName=1`

## Neural (all stages)

From the live plugins `ReShade.ini` `[RenoDX.DLSS5]` snapshot:

- `NREnableUpscaling=0`
- `NRPasses=2`
- `EnableHooks=2`

`dlss5-feed.cfg`:

- `enabled=1`
- `mode=2` (DLAA contract)
- `preset=5`
- `work_resolution=100`
- `work_upscale=0`

Tune intensity, style, and look in the RenoDX overlay. Those keys live
in `ReShade.ini`, not in the ReShade effect presets — switching 1–4
changes the Lumenite stack, not the neural sliders.
