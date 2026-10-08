# GFX-F: shadows, grade, terrain, opening, fog, night

Stacked on the perf-fixed GFX-E head (`cursor/gfx-e-visual-pass-a689`,
`33fc3bc`). North star: `concept_1.png`. ChatGPT scored GFX-E **5.0/10**
on the 4070; this pass targets **6.5/10**.

No RTS rewrite, no scout / night-guard / raider-outline gameplay, no
Master-volume change, no `.github/workflows` edits.

## ChatGPT order

1. **Directional shadows.** Recommended is 4 PSSM splits, bias 0.06,
   blur 0.8, fade 0.85, angular distance 0. Day key `#FFF0DE` at 1.20
   against ambient `#8799AA` 0.25 so buildings cast longer, darker
   shadows with warm sun / cool fill.
2. **Tonemap + materials.** Filmic exposure 0.78, white 6.0, sat 1.10,
   contrast 1.08. Meadow `#536B3E` / sunlit `#72884D` / shadow
   `#344D35` / forest `#304735`. 4070 GFX-E sat was ~0.30 vs the
   concept's 0.48, luma 113–125 vs 85, contrast std 34–37 vs 47. The
   LUT now pulls midtones down and cools shadows after the Filmic
   baseline, not instead of it.
3. **Terrain at gameplay zoom.** Larger grass tufts, more dirt (0.34),
   worn-earth roads `#92714E` / `#B09268`, flower and shrub scatter
   that should read at zoom 26.
4. **Opening 30 seconds.** Presentation-only `OpeningDress`: forest
   frame, rock landmark, worn approach path. The founding hall stays
   on a playable clearing. Wheat crops force gold `#C9A24A`.
5. **Fog / world boundary.** Off-map fog alpha is opaque wilderness
   `#17262A`. Beach / water / horizon lose the peach rim and teal
   void. Skirts and hills sit at `#17262A`.
6. **Night.** Moon `#9CACC8` 0.18, ambient `#52647C` 0.16, exposure
   0.67, sat 0.95, window `#F5B36B`. Raids stay playable.

## Performance

The 4070 8 s start / 112 s first-frame regression was fixed on GFX-E
(`33fc3bc`) before this branch. See `docs/gfx/GFX_E_PERF.md` and
`tests/t_gfx_e_perf.gd`. GFX-F keeps the batched terrain lookups.

## GPU shots

Same cameras as GFX-E. `SNS_GFX_SHOTS=<dir>` on a normal Windows
export. Isolate `user://` with temp `APPDATA` / `XDG_DATA_HOME`.
See `docs/gfx/GPU_SHOTS.md`.
