# GFX-K: 90-minute art-direction sprint

Stacked on GFX-J (`cursor/gfx-j-visual-pass-a689`, `76fdc32`, PR #67).
North star: `concept_1.png`. ChatGPT scored GFX-I at **6.5/10** and
expected ~7 after J. This pass follows the timeboxed GFX-K plan.
Day grade knobs (sat 1.12 / contrast 1.12 / exposure 0.86) were not
retuned.

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.

Keep from J: screen shroud, limestone plates, meadow patches, ridge,
1.5× zoom cap, blue night, local lighting.

No RTS rewrite, no scout / night-guard / raider-outline gameplay, no
Master-volume change, no `.github/workflows` edits.

## Order

1. **Fog / boundary.** Explored alpha 0.55. 1.25-cell feather. Noise
   displacement ≤ 0.15 cells. Missing mask = unexplored. BG `#17272A`.
2. **Architecture hierarchy.** Limestone `#CBBCA0`, plaster `#E0CDA9`,
   timber `#62432F`, slate `#426C67`, stone `#817968`. Pilasters, two
   bands, house beams / shutters / chimney, workshop awning.
3. **Opening landmark.** Ridge 1.8W × 0.35W, 6–10 bevelled rocks,
   creek 0.18W `#37646A`. Camera focus ~53% / 56%.
4. **Worn roads.** Centre `#9F8260`, shoulders, ruts, gravel. Routing
   unchanged.
5. **Three-scale ground.** Broad 3.0R / medium 0.8R. Meadow `#60764A`.
   Clusters 12–18 / 100 R².
6. **Woodland edge.** 55 / 25 / 20 mix, height bands, understory
   transition ~1.2W.
7. **Settlement dressing.** Notice board + flag, house woodpile,
   extra lumber stacks. Deterministic, no path blocks.
8. **Lighting A/B.** Evaluated `#FFE9D3` / 1.08 / ambient 0.30 /
   SSAO 0.60. **Rolled back** — same-camera delta was marginal.

## GPU shots

Same cameras as GFX-J, except opening_day uses `opening_camera_focus()`.
`SNS_GFX_SHOTS=<dir>` on a normal Windows export. Isolate `user://`
with temp `APPDATA` / `XDG_DATA_HOME`. See `docs/gfx/GPU_SHOTS.md`.
