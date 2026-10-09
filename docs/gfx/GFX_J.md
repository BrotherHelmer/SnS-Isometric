# GFX-J: screen shroud, limestone, meadow, ridge

Stacked on GFX-I (`cursor/gfx-i-visual-pass-a689`, `6d0ce8e`, PR #66).
North star: `concept_1.png`. ChatGPT scored GFX-I at **6.5/10** and
approved it as the baseline — no reverts. Target is **7**. This pass
does not retune the global grade (sat 1.12 / contrast 1.12 /
exposure 0.86).

Keep from I: no haze, vegetation, wheat, roads, opening village,
conifers, blue night, local lighting.

No RTS rewrite, no scout / night-guard / raider-outline gameplay, no
Master-volume change, no `.github/workflows` edits.

## Order

1. **Screen-composited shroud.** Environment background `#17272A`.
   Visible 0, explored 0.45, unexplored / off-map 1.0. Frontier
   1–1.5 cells. Zoom-out cap 1.5× (`STRATEGIC_ZOOM` 39). World-space
   sheet and skirts stay hidden so they cannot print a triangle.
2. **Landmark limestone.** `#C5B69B` / plaster `#D8C7A8` / timber
   `#59402B` / slate `#456966` / stone `#776F60`. Roughness 0.85,
   metallic 0. Quoins, door surround, window lintels.
3. **Organic meadow.** Dark-grass patches 1–3 road widths, 15–25%
   coverage. Road shoulders 20–35%. Bright beige patches softened.
4. **Unmistakable ridge / creek.** 1.5–2 Town Hall widths west of the
   hall, rock `#B3A78A` / `#66685B`, creek `#315D66`, in the opening
   camera.

## GPU shots

Same cameras as GFX-I, except fog-edge / far use the 1.5× cap.
`SNS_GFX_SHOTS=<dir>` on a normal Windows export. Isolate `user://`
with temp `APPDATA` / `XDG_DATA_HOME`. See `docs/gfx/GPU_SHOTS.md`.
