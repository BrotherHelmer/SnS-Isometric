# GFX-L: regressions, modular façades, authored ground

Stacked on GFX-K (`cursor/gfx-k-visual-pass-a689`, `b8d7f9f`, PR #68,
ChatGPT **6.7/10**). North star: `concept_1.png`. Helmer's holiday bar
is a playable demo ChatGPT rates **≥ 8/10**. This pass removes the
ugly geometry and starts real asset work. Day grade knobs were not
retuned.

**Keep from K:** screen shroud, forest mix, wheat rows, architectural
trim names, moonlit night.

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.

## Order

1. **Regressions.** Low foundation ≤ 0.06B, face `#A99D82` / top
   `#C1B394` / edge `#756C5B`. Remove the bunker wrap plates. Remove
   straight turquoise creek planes. Tint / drop the pale dirt_plot
   square in wheat.
2. **Architecture.** Limestone `#CDBD9F`, plaster `#E0CDAE`, timber
   `#64452F`, slate `#456D68`. Modular façade panels, recessed arch,
   parapets, house plaster face. Keep K pilasters / beams / dressing.
3. **Authored ground.** Meadow `#5A7545`, lush `#344D34`, earth
   `#886C49`, road centre `#B0926C`, gravel `#929080`. Sparse rut
   decals on crossroads.
4. **Framing.** 1.5× zoom cap stays. Terrain apron continues meadow
   under the shroud. Explored brightness target 0.45; overlay alpha
   stays K's 0.55.
5. **Ridge + creek.** 6–10 bevelled masses + KayKit CC0 rocks.
   Curve3D creek, water `#315C61`, roughness 0.28.

Licences: `docs/ASSET_LICENSES.md`.

## GPU shots

Same cameras as GFX-K. `SNS_GFX_SHOTS=<dir>` on a normal Windows
export. Isolate `user://` with temp `APPDATA` / `XDG_DATA_HOME`.
See `docs/gfx/GPU_SHOTS.md`.
