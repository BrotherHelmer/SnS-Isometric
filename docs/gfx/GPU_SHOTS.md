# GPU_SHOTS — real-GPU comparison cameras from a Windows export

Use this to render GFX-E (and later) on an RTX-class machine without
opening the editor. The hook is an autoload
(`production_gfx_shots.gd`) so it works in a packaged export. It stays
inert unless `SNS_GFX_SHOTS` or `--gfx-shots` is set.

Default window chrome is unchanged. The hook only moves the window
off-screen and goes borderless **while a shot run is active**.

## What it captures

All frames are 1920×1080, seed `DEFAULT_SEED` (260821), sim paused:

| file | framing |
| --- | --- |
| `showcase_day.png` | 15-building showcase, zoom 26 |
| `showcase_wide.png` | same village, zoom 42 |
| `opening_day.png` | fresh opening, zoom 26 |
| `after_day_close.png` | opening, zoom 34 |
| `scout_day.png` | patrol scout (Y) toward the west fog |
| `night_raid.png` | night + two raiders |
| `fog_edge.png` | **day**, zoom 68 |

`fog_edge` is forced back to day. The GFX-D playtest left that shot at
night.

## Windows (clean export)

From a cmd.exe / PowerShell after exporting "Windows Desktop":

```bat
set SNS_GFX_SHOTS=D:\shots\gfx-e
ShardAndSovereign.exe --user-data-dir D:\shots\gfx-e-user
```

PowerShell:

```powershell
$env:SNS_GFX_SHOTS = "D:\shots\gfx-e"
.\ShardAndSovereign.exe --user-data-dir D:\shots\gfx-e-user
```

Or pass the dest after `--`:

```bat
ShardAndSovereign.exe --user-data-dir D:\shots\gfx-e-user -- --gfx-shots=D:\shots\gfx-e
```

`--user-data-dir` (Godot) / a dedicated folder keeps `user://` out of
the real `%APPDATA%\ShardAndSovereign` save. The process writes the
PNGs, prints `GPU_SHOTS PASS`, and quits.

## Linux / lavapipe (editor)

```bash
SNS_GFX_SHOTS=/tmp/gfx_e_gpu \
  godot --path . --audio-driver Dummy --resolution 1920x1080 \
  -- --gfx-shots=/tmp/gfx_e_gpu
```

Headless `--script` tests (`t_gfx_e_shots.gd`, `t_gfx_e_playtest.gd`)
are the software-Vulkan counterparts; they do not replace a 4070 pass.

## Do not

- Do not set `window/size/no_focus`, `borderless`, or a parked
  `initial_position` in `project.godot`. Those were local-only hacks
  and they break normal play.
- Do not commit `.import` UID churn from a local Godot run.
