# GFX-1: Lys og farve (retning B, trin 1)

Presentation-only lighting, grade, edge forest, lit roads and building
halos. No HUD, audio, gameplay-rule or save-format changes.

## Lighting

Three authored presets in `production_identity.gd` (`day`, `dusk`, `night`)
plus `reckoning`. The production root interpolates them on the existing
day / dusk-60s / night / dawn-40s cycle.

| | Day | Dusk | Night |
| --- | --- | --- | --- |
| Sun / moon elevation | 28° | 10° | 48° |
| Orbit from camera | 110° | 110° | 290° |
| Colour | `#FFD09A` 1.25 | `#FF9A61` 0.85 | `#91B8FF` 0.33 |
| Ambient | `#718FA3` 0.62 | `#435A78` 0.48 | `#182A45` 0.36 |
| Exposure | 0.95 | 0.90 | 0.86 |

Orbit 110° puts the sun off the camera's left shoulder so light enters
upper-left and shadows fall lower-right. Night uses 290° (opposite side)
so dawn does not lerp the light *through* the camera.

ACES, white 6.5, contrast 1.10, mild S-curve LUT (0→0, 0.18→0.12,
0.45→0.50, 0.72→0.82, 1→0.96) with teal shadows and warm highlights.
Depth fog only (28–65 m day). No foreground haze. Volumetric fog stays
off in both profiles.

`scalable_low` turns off SSIL, glow and volumetrics, including when the
quality dropdown is changed mid-session via `apply_quality_profile`.

## Pixel gates

`tools/gfx_pixel_gates.py` scores **world pixels only** on evidence shots
(1280×720):

* exclude y < 90 (top bar + loop bar)
* exclude y ≥ height − 184 (console / minimap)

| Gate | Threshold |
| --- | --- |
| Day world luminance σ | 0.14–0.16 |
| Mean saturation | ≤ 0.60 |
| Dusk warm-pixel share (H 8–50°, S≥0.28, V≥0.18) | ≤ 0.70 |
| Night near-black (Y < 0.05) | ≤ 0.15 |
| Night road / grass luminance | ≥ 1.20 |

HUD pixels are not part of the score. GFX-1 must not change HUD theme,
layout or fonts.

## Perf note

Budget: at most +15% frame time on the owner's Windows box. Draw calls
should stay near the capture-scene 340–380.

* Edge forest and building halos are MultiMesh (a handful of extra
  instances, not per-tree / per-prop nodes).
* Recommended: 4-split PSSM, shadow distance 62 m, SSAO + subtle SSIL +
  glow levels 2–4. Volumetrics off.
* Low profile: shadows / SSAO / SSIL / glow / volumetrics off, thinner
  foliage.

If the Windows capture exceeds +15%, drop SSIL first, then glow.

## Halos

`production_building_halo.gd` is a data table (4–12 authored slots per
building). Placement is deterministic, outside the footprint, and
skipped when a slot would land on a road or door tile. Visual only.
The farm gets a gold wheat-field block when the neighbouring tiles are
free.
