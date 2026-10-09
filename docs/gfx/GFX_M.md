# GFX-M: real CC0 assets, scaled rocks, visible roads

Stacked on GFX-L (`cursor/gfx-l-visual-pass-a689`, `a21f0d4`, PR #69,
ChatGPT **6.7/10** unchanged from K). Helmer's holiday bar is a
playable demo ChatGPT rates **≥ 8/10**. Two procedural rounds sat on
6.7, so this pass does real asset work. Day grade knobs stay frozen
(sat 1.12 / contrast 1.12 / exposure 0.86).

**Keep from L/K:** screen shroud, forest mix, wheat, night, zoom cap.

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.
H = house visual height ≈ **4.09 m**.

## Order

1. **Revert + scale.** Rocks 0.15–0.55B wide, ≤ 0.35H tall, albedo
   `#8E8C78` / `#B4AA92` / `#626B61`, roughness 0.92. Moved to the
   forest flanks. Foundation ≤ 0.05B, inset 0.88 of the mesh.
2. **Roads.** Centre `#AB8963`, shoulder `#806747`, ruts `#655039`,
   gravel `#B8A388`. Wider raised meshes + more Decals. Showcase adds
   south / west / farm spokes so three connections read at zoom 26.
3. **Architecture.** Live meshes are KayKit Medieval Hexagon
   `building_castle_green`, `building_home_A_green`,
   `building_lumbermill_green`, remapped to plaster `#DDCAA8`,
   limestone `#C8BA9C`, timber `#5F422E`, slate `#426B66`.
4. **Terrain textures.** Poly Haven CC0 1024² diffs in the splat
   shader (meadow / forest / dirt / rock), world-space UVs, tinted
   toward `#526B40`.
5. **Ridge + creek.** 8 bevelled + KayKit debris on the flanks.
   Curve3D water `#315D62`, shallow `#638D86`, banks `#8A7658`,
   roughness 0.32.

Licences: `docs/ASSET_LICENSES.md`.

## GPU shots

Same cameras as GFX-L. `SNS_GFX_SHOTS=<dir>` on a normal Windows
export. Isolate `user://` with temp `APPDATA` / `XDG_DATA_HOME`.
See `docs/gfx/GPU_SHOTS.md`.
