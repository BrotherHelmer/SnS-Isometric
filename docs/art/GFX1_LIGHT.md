# GFX-1: Lys og farve (retning B, trin 1)

Presentation-only lighting, grade, edge forest, lit roads and building
halos. No HUD, audio, gameplay-rule or save-format changes.

## Lighting

Three authored presets in `production_identity.gd` (`day`, `dusk`, `night`)
plus `reckoning`. The production root interpolates them on the existing
day / dusk-60s / night / dawn-40s cycle.

| | Day | Dusk | Night |
| --- | --- | --- | --- |
| Sun / moon elevation | 25° | 11° | 48° |
| Orbit from camera | 120° | 120° | 300° |
| Colour | `#FFC888` 1.45 | `#FFC080` 1.10 | `#91B8FF` 0.52 |
| Ambient | `#718FA3` 0.58 | `#A87848` 0.80 | `#3A5580` 0.70 |
| Exposure / brightness | 1.06 / 1.16 | 1.22 / 1.14 | 1.14 / 1.10 |
| Saturation / contrast | 0.52 / 1.52 | 0.48 / 1.12 | 0.45 / 1.06 |

Orbit 120° keeps the sun off the camera's left shoulder (shadows
lower-right) and the 3D sun/camera angle ≥ 90°. Night uses 300°.

ACES, white 6.5, S-curve LUT (0→0, 0.18→0.11, 0.45→0.48,
0.72→0.86, 1→0.96). Depth fog only. SSIL and glow stay off.
Fog-of-war / boundary-mist / rim-fir scale day 1.0, dusk 0.55,
night 0.35. Ground shader takes a period `light_tint` so dusk
grass reads gold, not dark brown. Edge firs are lit.

Roads are muted pale stone (`#a09888`). World-up normal
(`normalize((VIEW_MATRIX * vec4(0,1,0,0)).xyz)`) plus a moonlit
emission, never an orange carpet.

## Pixel gates

`tools/gfx_pixel_gates.py` scores world pixels on the **18-step**
Day 3 / dusk / Night 2 shots (`tests/t_gfx_gate_shots.gd`, run by
`linux_ci.sh`):

* exclude y < 90 and y ≥ height − 184
* sRGB display Y'
* night road/grass needs `{stem}.roads.json` with ≥ 10 road tiles
* no hue fallback at night

| Gate | Threshold |
| --- | --- |
| Day world luminance σ | 0.15–0.24 |
| Day mean luma | 0.22–0.30 |
| Mean saturation (Y' ≥ 0.10) | ≤ 0.60 |
| Dusk warm-pixel share | 0.20–0.70 |
| Dusk mean luma | ≥ 0.16 |
| Night mean luma | ≥ 0.11 |
| Night near-black (Y' < 8/255) | ≤ 0.15 |
| Night road / grass | ≥ 1.50 |

A base-7db0725 dusk (warm ≈ 0.16) fails the warm-share floor.
Title art (warm ≈ 0.299) is the warm-share reference.

## Perf note

Budget: at most +15% frame time vs base. Day 3 settlement draws
about **630** calls in both builds. SSIL and glow stay off.

## Halos

`production_building_halo.gd`: 4–12 authored slots, revealed grass
only, no orphan fences. Farm wheat is a dense 4×4 sheaf block per
field tile. `sack` uses the wheat sheaf, not the crate mesh.
