# GFX-1: Lys og farve (retning B, trin 1)

Presentation-only lighting, grade, edge forest, lit roads and building
halos. No HUD, audio, gameplay-rule or save-format changes.

## Lighting

Three authored presets in `production_identity.gd` (`day`, `dusk`, `night`)
plus `reckoning`. The production root interpolates them on the existing
day / dusk-60s / night / dawn-40s cycle.

| | Day | Dusk | Night |
| --- | --- | --- | --- |
| Sun / moon elevation | 25° | 16° | 48° |
| Orbit from camera | 120° | 120° | 300° |
| Colour | `#FFC888` 1.45 | `#FF9A61` 0.85 | `#91B8FF` 0.45 |
| Ambient | `#718FA3` 0.55 | `#435A78` 0.58 | `#2A4466` 0.55 |
| Exposure | 0.95 | 1.00 | 1.00 |

Orbit 120° puts the sun off the camera's left shoulder so light enters
upper-left and shadows fall lower-right, and the 3D sun/camera angle stays
≥ 90°. Night uses 300° (opposite side) so dawn does not lerp the light
*through* the camera.

ACES, white 6.5, contrast 1.10, mild S-curve LUT (0→0, 0.18→0.145,
0.45→0.50, 0.72→0.82, 1→0.96) with teal shadows and warm highlights.
Depth fog only (28–65 m day). No foreground haze. Volumetric fog stays
off in both profiles. Fog-of-war and boundary-mist colours scale with
the palette (day 1.0, dusk 0.55, night 0.35).

Recommended and `scalable_low` both keep SSIL and glow off. Glow stays
off rather than cheap: the software-render proxy already sat at the
+15% frame-time budget once SSIL+glow were disabled.

## Pixel gates

`tools/gfx_pixel_gates.py` scores **world pixels only** on evidence shots
(1280×720), in **sRGB display space**:

* exclude y < 90 (top bar + loop bar)
* exclude y ≥ height − 184 (console / minimap)
* saturation ignores pixels with Y' < 0.10
* night road/grass prefers `{stem}.roads.json` (tile-centre mask)

| Gate | Threshold |
| --- | --- |
| Day world luminance σ | 0.09–0.24 |
| Mean saturation (Y' ≥ 0.10) | ≤ 0.60 |
| Dusk warm-pixel share (H 8–50°, S≥0.28, V≥0.18) | ≤ 0.70 |
| Night near-black (Y' < 8/255) | ≤ 0.15 |
| Night road / grass luminance | ≥ 1.20 |

The title painting itself is the calibration reference and must pass.
HUD pixels are not part of the score. GFX-1 must not change HUD theme,
layout or fonts.

## Perf note

Budget: at most +15% frame time on the owner's Windows box. A Day 3
settlement draws about **630** calls in both the base build and GFX-1
(the older 340–380 figure was a first-view / zoomed-in capture, not
this scene).

* Edge forest and building halos are MultiMesh (a handful of extra
  instances, not per-tree / per-prop nodes). Edge firs do not cast
  shadows and spawn only outside the playable map.
* Recommended: 4-split PSSM, shadow distance 62 m, SSAO on, SSIL off,
  glow off. Volumetrics off.
* Low profile: shadows / SSAO / SSIL / glow / volumetrics off, thinner
  foliage.

## Halos

`production_building_halo.gd` is a data table (4–12 authored slots per
building). Placement is deterministic, outside the footprint, and
skipped when a slot would land on a road, door, rock, tree or
unrevealed tile. Isolated fence pieces are dropped. Visual only.
The farm gets a dense gold wheat-field block when the neighbouring
grass tiles are free. `sack` uses the wheat sheaf, not the crate mesh.
