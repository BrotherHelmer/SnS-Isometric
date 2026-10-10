# GFX-T: lush terrain, supporting buildings, scenic creek

Stacked on GFX-S (`cursor/gfx-s-visual-pass-a689`, `5533a7b`, PR #76,
ChatGPT **8.0/10**, +0.3 vs R). ChatGPT's review is in
`uploads/CHATGPT_ANSWER_GFXS.md`. Helmer's holiday bar is still a
playable demo ChatGPT rates **≥ 8/10**. Target **8.5**.

**Rule:** only what is visible at native **1280×720** gameplay cameras
counts. Showcase shots are clean — no RAID popup.

**Keep:** occupancy, distance-field roads, KayKit houses / mill, meadow
identity `#536C3F`, forest coverage 0.38–0.58, fog, west creek, S
gatehouse names, visual_w 0.72, night, and grade knobs (sat 1.12 /
contrast 1.12 / exposure 0.86). Day *light* may refine; night stays
frozen.

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.

## Order

1. **Lush terrain.** Denser 3×3 clumps of tufts / flowers / weeds /
   stones, plus shader weed and reward-patch variation. Meadow stays
   `#536C3F`.
2. **Supporting buildings.** Porches, doors, chimneys, loading docks
   and workyard gardens on houses, farm and workshop. KayKit meshes
   stay.
3. **Scenic creek.** Irregular banks, deep run, reed clumps, shoreline
   stones and a timber footbridge. Water stays `#2F7A7E`.
4. **Forest-edge mix.** Wider tree scale, more deciduous mid-story and
   nested understory. Coverage stays planted / candidates (0.38–0.58).
5. **Lived-in hamlet.** Gardens, wash-line, pitchfork, extra wood and
   barrels. Warmer day ambient `#A8A088` / fill `#C8B488` / horizon
   `#C8B8A0` without losing S material separation. Night unchanged.

## GPU shots

Same cameras as GFX-S / GFX-R / GFX-Q / GFX-P at 1280×720. Showcase
frames dismiss the raid banner and clear hostiles.

Playtest: `docs/gfx/GFX_T_PLAYTEST.md` + `docs/gfx/gfx_t_playtest.csv`.
