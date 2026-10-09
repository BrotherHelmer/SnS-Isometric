# GFX-O: diagnose the terrain pipeline, then own the final albedo

Stacked on GFX-N (`cursor/gfx-n-visual-pass-a689`, `db38020`, PR #71,
ChatGPT **6.5/10**, down from M 6.8). Helmer's holiday bar is a playable
demo ChatGPT rates **≥ 8/10**. Day grade knobs stay frozen (sat 1.12 /
contrast 1.12 / exposure 0.86).

**Revert:** chalk-white meadow output and flat dark-green cylinder
patches.

**Keep:** KayKit Hexagon architecture, roofs, Poly Haven textures,
forest, wheat.

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.
H = house visual height ≈ **4.09 m**.

Hard rule: every package is proven from the **gameplay camera**, not
from a standalone control PNG.

## Order

1. **Diagnose the terrain pipeline.** `terrain_debug` 1 = magenta,
   2 = solid `#556D3F`, 3 = red road mask over dark green. Albedo maps
   keep `source_color`. `road_control_tex` is linear (no
   `source_color`). Occupy only if `COLOR.r > COLOR.g + 0.04` so a
   dropped vertex alpha cannot paint dirt over the lawn. That was the
   GFX-N chalk-white fault.
2. **Continuous high-contrast roads.** 512² world-space distance field
   with matching Image-Y flip on CPU stamp and shader sample. Visual
   width 1.32R. `smoothstep(0.12, 0.80, mask)` last over the finished
   ground. Palette `#AD8D66` / `#866748` / `#68523B` / `#BAA88E`.
3. **Blended meadow transitions.** Shade `#3E5938`, max blend 0.35,
   35–50% feather, 5R macro. No dark-grass / cluster cylinders.
   `tex_mix` 0.12. Macro only darkens.
4. **Castle in light stone.** Walls `#CFC2A6` / `#E0D0B2` / `#847C6B`,
   timber `#61442F`, roof `#466C69`. `wall_lift` 1.32 so at least half
   the wall area reads pale limestone.
5. **Opening composition.** Clearing 2.5–3 Town Hall widths (11 cells).
   Forest on 40–55% of the perimeter, back and west. Visible ridge
   (`#B3A78E` / `#8E8A78` / `#596258`) and camera-side creek
   (`#345F65` / `#6B978F` / `#857055`).

Licences: `docs/ASSET_LICENSES.md`.

## GPU shots

Same cameras as GFX-N plus package proofs (`pkg1`–`pkg5`). Package 1
magenta / solid / red-mask frames are captured from the gameplay
camera. `SNS_GFX_SHOTS=<dir>` on a normal Windows export. Isolate
`user://` with temp `APPDATA` / `XDG_DATA_HOME`. See
`docs/gfx/GPU_SHOTS.md`.
