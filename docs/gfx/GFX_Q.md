# GFX-Q: five defects, no broad overhaul

Stacked on GFX-P (`cursor/gfx-p-visual-pass-a689`, `60171c2`, PR #73,
ChatGPT **7.1/10**, +0.1 vs O). ChatGPT's review is in
`uploads/CHATGPT_ANSWER_GFXP.md`. Helmer's holiday bar is still a
playable demo ChatGPT rates **≥ 8/10**. Day grade knobs stay frozen
(sat 1.12 / contrast 1.12 / exposure 0.86). Night stays frozen.

**Keep:** occupancy-mask fix, distance-field roads, KayKit houses / mill,
meadow baseline, forest, fog, west creek, worn-path graph.

**Do not** start another visual overhaul. Q is exactly the five defects
ChatGPT named, plus the showcase 2/5-vs-76-buildings lie.

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.

Hard rule: every package is proven from the **same GFX-P gameplay cameras**.

## Order

1. **Terrain richness.** Blend meadow / dry grass / exposed soil / rock
   using the bound 1K maps. Large-scale colour + irregular flower
   clusters. Break the sandy ridge with darker stone, ledges and
   embedded rocks. Presentation relief 0.08–0.18B on the back slope
   only. No camera-side cliff.
2. **Castle stone.** Authored `civic_keep.gltf` / `civic_castle.gltf`
   with 1K Poly Haven stone / plaster / timber / slate under warmer,
   slightly darker limestone (`#C2B394`) and foundation masonry.
   Texture mix 0.42, almost no emission. Roof is geometry, not an
   atlas classify. Houses / mill stay KayKit.
3. **Worn roads.** Keep the 512² distance field. Narrower stamps,
   circular junction pads, world-space ruts (no repeating lattice),
   softer shoulders. Raised meshes sit in the 3–6 cm dip.
4. **Water readability.** Creek surface `#2F7A7E`, wet shoreline,
   irregular stones and reeds. No emission wedge. Pond / west edge
   stay secondary.
5. **Lived-in settlement.** Visible settlers from a populated
   showcase, daytime chimney smoke, farm wheat aprons tied to the
   land, stronger contact AO. HUD building count excludes roads.
   Showcase housing / population follow the stamped houses (not 2/5).

Licences: `docs/ASSET_LICENSES.md`.

## GPU shots

Same cameras as GFX-P (`opening_day`, `pkg1_creek`, `pkg3_castle`,
`pkg2_roads`, `showcase_day`, `showcase_wide`, night raid).
`SNS_GFX_SHOTS=<dir>` on a normal Windows export. Isolate `user://`
with temp `APPDATA` / `XDG_DATA_HOME`. See `docs/gfx/GPU_SHOTS.md`.
