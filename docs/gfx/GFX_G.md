# GFX-G: night lift, yellow-olive hue, hamlet, dirt, hidden diamond

Stacked on GFX-F (`cursor/gfx-f-visual-pass-a689`, `3386cbd`). North
star: `concept_1.png`. RTX 4070 scored GFX-F at luma / contrast std /
sat / hue:

| shot | 4070 GFX-F | concept |
| --- | --- | --- |
| concept | — | 84.8 / 47.3 / 0.48 / 66° |
| showcase_day | 88.7 / 31.7 / 0.35 / 68° | keep luma ~85 |
| showcase_wide | 75.2 / 38.4 / 0.37 / 102° | warm hue 65–75° |
| opening_day | 77.7 / 39.5 / 0.33 / 111° | hamlet + warm hue |
| night_raid | 17.9 / 10.0 / 0.34 / 183° | luma 45–60 |
| fog_edge | 87.3 / 33.6 / 0.28 / 153° | hide diamond / dark rim |

4070 first frame was 0.5 s. Perf is not a GFX-G blocker.

No RTS rewrite, no scout / night-guard / raider-outline gameplay, no
Master-volume change, no `.github/workflows` edits.

## Order

1. **Night.** Moon `#9CACC8` 0.42, ambient `#5A6E88` 0.30, exposure
   0.84, atmosphere 0.62, window / fire pools `#F5B36B` out to 8 m.
   Target luma 45–60. 18 was unplayable.
2. **Hue.** Meadow `#68743A` / sunlit `#8A9848` / forest `#3E4E28`.
   Foliage leaves the teal `#15281E` hole. Wide and opening should
   return to 65–75°.
3. **Sat / contrast.** Dirt 0.48, more grass clumps, worn hamlet
   lanes. Day sat 1.16 / contrast 1.14. Target sat ~0.45 and contrast
   std ~45+ without lifting showcase_day off ~85.
4. **Opening hamlet.** Presentation-only: 3–5 cottages / a shed,
   fences, a well (barrel + stone), carts, stacked wood. No TILE_GRASS
   consume, no economy change.
5. **Diamond edge.** Irregular five-ring edge forest, shore and water
   dissolve into fog `#17262A`, no dark beach rim on showcase_wide /
   fog_edge.

## GPU shots

Same cameras as GFX-F. `SNS_GFX_SHOTS=<dir>` on a normal Windows
export. Isolate `user://` with temp `APPDATA` / `XDG_DATA_HOME`.
See `docs/gfx/GPU_SHOTS.md`.
