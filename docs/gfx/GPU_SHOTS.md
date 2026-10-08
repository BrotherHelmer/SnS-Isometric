# GPU_SHOTS — real-GPU comparison cameras from a Windows export

Use this to render GFX-E (and later) on an RTX-class machine without
opening the editor. The hook is an autoload
(`production_gfx_shots.gd`) so it works in a packaged export. It stays
inert unless `SNS_GFX_SHOTS` or `--gfx-shots` is set.

When the hook is active it parks the window off-screen from `_init`
(before the first paint): borderless, no-focus, `(-10000, -10000)`.
Default `project.godot` window chrome stays unchanged.

Godot **ignores** `--user-data-dir`. Isolate `user://` with a temporary
`APPDATA` / `LOCALAPPDATA` (Windows) or `XDG_DATA_HOME` (Linux).

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

From cmd.exe after exporting "Windows Desktop". Pass `--position` so
the engine creates the window off-screen; the autoload also parks it
from `_init`. Optional `override.cfg` beside the exe (not in the `.pck`)
can set borderless / no_focus / initial position if you want the same
chrome before scripts run.

```bat
set SNS_GFX_SHOTS=D:\shots\gfx-e
set APPDATA=D:\shots\gfx-e-appdata
set LOCALAPPDATA=D:\shots\gfx-e-local
ShardAndSovereign.exe --audio-driver Dummy --position -10000,-10000 --resolution 1920x1080
```

PowerShell:

```powershell
$env:SNS_GFX_SHOTS = "D:\shots\gfx-e"
$env:APPDATA = "D:\shots\gfx-e-appdata"
$env:LOCALAPPDATA = "D:\shots\gfx-e-local"
.\ShardAndSovereign.exe --audio-driver Dummy --position -10000,-10000 --resolution 1920x1080
```

Or pass the dest after `--`:

```bat
set APPDATA=D:\shots\gfx-e-appdata
set LOCALAPPDATA=D:\shots\gfx-e-local
ShardAndSovereign.exe --audio-driver Dummy --position -10000,-10000 -- --gfx-shots=D:\shots\gfx-e
```

`user://` for this project is `%APPDATA%\ShardAndSovereign\Playtest`.
Pointing `APPDATA` at an empty folder keeps the real save untouched.
The process writes the PNGs, prints `GPU_SHOTS PASS`, and quits.

## Linux / lavapipe (editor)

```bash
SNS_GFX_SHOTS=/tmp/gfx_e_gpu \
XDG_DATA_HOME=/tmp/gfx_e_xdg \
  godot --path . --audio-driver Dummy --position -10000,-10000 \
  --resolution 1920x1080 -- --gfx-shots=/tmp/gfx_e_gpu
```

`user://` is `$XDG_DATA_HOME/ShardAndSovereign/Playtest` (or
`~/.local/share/...` if `XDG_DATA_HOME` is unset).

Headless `--script` tests (`t_gfx_e_shots.gd`, `t_gfx_e_playtest.gd`)
are the software-Vulkan counterparts; they do not replace a 4070 pass.

## Do not

- Do not set `window/size/no_focus`, `borderless`, or a parked
  `initial_position` in `project.godot`. Those break normal play.
  Use `--position`, `SNS_GFX_SHOTS` / `SNS_GFX_OFFSCREEN`, or a
  next-to-exe `override.cfg` for capture runs only.
- Do not commit `.import` UID churn from a local Godot run.
- Do not use `--user-data-dir` expecting it to isolate `user://`.
  Godot ignores that flag.
