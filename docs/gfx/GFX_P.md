# GFX-P: hide the wedge, wear the paths, lighten the castle

Stacked on GFX-O (`cursor/gfx-o-visual-pass-a689`, `8870238`, PR #72,
ChatGPT **7.0/10**, up from N 6.8). ChatGPT approved O as the playable
baseline and expects P at **7.5–7.8**. Helmer's holiday bar is still a
playable demo ChatGPT rates **≥ 8/10**. Day grade knobs stay frozen
(sat 1.12 / contrast 1.12 / exposure 0.86). Night stays frozen.

**Keep:** occupancy-mask fix (`COLOR.r > COLOR.g + 0.04`), distance-field
roads, KayKit Hexagon meshes, meadow baseline, forest, fog logic.

**Do not revert** the roads — refine their edges so they read as worn
earth, not rectangles.

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.
H = house visual height ≈ **4.09 m**.

Hard rule: every package is proven from the **gameplay camera**.

## Order

1. **Remove the artificial creek wedge.** Relocate the ribbon to the
   west forest. `Curve3D` bake 0.15R, sample 0.20R, water width
   0.55–0.75R ±12%, bank 0.20R/side. Water `#345F65`, shallow
   `#668F89`, bank `#786C50`, roughness 0.35, no emission. Continues
   under the trees; no triangular cap across the village.
2. **Naturally worn paths.** Keep the 512² distance-field graph and
   widths. Displace the edge ±0.07R with noise. Centre `#9F805B`
   (65–70%), compacted `#816344`, shoulder `#776B4E` (15–17.5%),
   gravel `#B3A084`, ruts `#665039`. Raised meshes match `#9F805B`.
3. **Genuinely light-stone castle.** Keep the KayKit mesh. Civic walls
   **ignore the green atlas RGB** and emit `#CDBFA2` / `#E0D0B2` /
   `#82796A` from the world normal. Roof `#456B68` only on upward
   faces. Timber `#5F442F`. Roughness 0.90. At least **50% light wall
   area** on the gameplay camera.
4. **Meadow material richness.** Keep occupy + Poly Haven luma
   modulation. Main `#536C3F`, deep `#405A36`, sunlit `#728853`,
   forest `#344B33`, dry soil `#8B7050`. Broad 4R @ 0.12, local 0.8R
   @ 0.08, `tex_mix` 0.16, roughness 0.94.
5. **Environmental composition and depth.** Clearing stays ≥2.75B
   (11 cells). Forest 40–55% of the perimeter, back and west. One
   back/upper rock formation 1.5–2.0B × 0.4–0.7B
   (`#B9AC92` / `#918C79` / `#61675B`). No large foreground rocks.
   Creek is secondary, not a diagonal obstruction.

Licences: `docs/ASSET_LICENSES.md`.

## GPU shots

Same cameras as GFX-O plus package proofs (`pkg1`–`pkg5`).
`SNS_GFX_SHOTS=<dir>` on a normal Windows export. Isolate `user://`
with temp `APPDATA` / `XDG_DATA_HOME`. See `docs/gfx/GPU_SHOTS.md`.

## GFX-Q plan (the path to 8)

ChatGPT's 8/10 bar is an authored Nordic diorama, not another remap
of the green Hexagon atlas. GFX-Q should land three things:

1. **Authored castle.** Replace the KayKit Hexagon castle as the live
   Town Hall with a purpose-built keep: limestone walls, slit windows,
   a teal-slate roof that is geometry (not an atlas classify), and a
   footprint that still sits on the 4×4 / 10 m Town Hall. Keep KayKit
   houses / mill if they still read; the civic landmark must stop
   fighting a dark green atlas.
2. **Architecture textures.** Real stone, plaster, timber, and slate
   maps (1K CC0, luminance-or-detail only under the P palettes). Stop
   asking a shader to invent masonry from a cartoon atlas. Door and
   beam trims become texture+mesh, not luma guesses.
3. **Terrain relief.** The meadow is still a flat plane with painted
   richness. Add low-frequency height (0.08–0.18B) so the back ridge
   grows out of the ground, the west creek sits in a shallow cut, and
   the worn paths dip 3–6 cm. Keep the occupy mask and the
   distance-field roads. Do not raise a cliff in front of the camera.

Do not touch the frozen grade or night. Do not reopen the occupy
mask. Do not claim 8 until a gameplay-camera composite against the
concept painting supports it on lavapipe *and* a hardware GPU.
