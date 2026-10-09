# GFX-N: lush meadow, union roads, KayKit remapped

Stacked on GFX-M (`cursor/gfx-m-visual-pass-a689`, `83670a8`, PR #70,
ChatGPT **6.8/10**, up from L 6.7). Helmer's holiday bar is a playable
demo ChatGPT rates **≥ 8/10**. ChatGPT projected **7.2–7.6** if the
five items below land. Day grade knobs stay frozen (sat 1.12 /
contrast 1.12 / exposure 0.86).

**Revert:** green roofs, sandy terrain colours, pale meadow rocks.

**Keep:** KayKit Hexagon meshes, Poly Haven texture system, creek,
forest, night, frozen grade.

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.
H = house visual height ≈ **4.09 m**.

## Order

1. **Lush green terrain.** Meadow albedo `#556D3F` / sunlit `#758851`
   / shadow `#394F33` / forest `#354834`. Poly Haven maps are
   luminance detail only (`tex_mix` 0.20). Roughness 0.94, metallic 0.
2. **Unmistakable roads.** Diagnose the splat first (magenta
   `road_debug`). 512² RGBA8 world-space `road_control_tex` unions
   disks + capsules so intersections stay solid. Centre `#AE906D`,
   clay `#92704C`, ruts `#6C543C`, gravel `#B7A187`.
3. **KayKit remap.** Keep the Hexagon castle / home / lumbermill
   meshes. `settlement_kaykit_remap.gdshader` remaps the green atlas
   to limestone `#CDBD9F`, plaster `#DFCBA9`, timber `#60432E`, muted
   teal slate `#426B68` plus terracotta `#A96343`. No emerald. Town
   Hall walls lift to light limestone.
4. **Rocks + creek.** Ridge debris `#898776` / `#B6AC94` / `#5E655B`,
   r 0.92, 0.12–0.28B. Pale meadow rocks hidden. Curve3D water
   `#345E64`, shallow `#719B93`, banks `#847257`, r 0.35.
5. **Clustered groundcover.** 4–5 tufts at forest edges, 3 at yards,
   sparse meadow centre.

Licences: `docs/ASSET_LICENSES.md`.

## GPU shots

Same cameras as GFX-M plus package proofs (`pkg1`–`pkg5`).
`SNS_GFX_SHOTS=<dir>` on a normal Windows export. Isolate `user://`
with temp `APPDATA` / `XDG_DATA_HOME`. See `docs/gfx/GPU_SHOTS.md`.
