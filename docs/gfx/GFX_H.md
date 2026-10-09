# GFX-H: ground, roads, edge, shadows, blue night

Stacked on GFX-G (`cursor/gfx-g-visual-pass-a689`, `1a361fb`, PR #64).
North star: `concept_1.png`. RTX 4070 scored GFX-G at about **5.5/10**.
Opening grade is nearly right and must stay there:

| shot | 4070 GFX-G | keep |
| --- | --- | --- |
| opening_day | 81 / 44.9 / 0.46 / 71° | do not retune the day grade |
| concept | 84.8 / 47.3 / 0.48 / 66° | target look |

Day sat 1.12 / contrast 1.12 / exposure 0.86 / sun `#FFF0DE` 1.24 /
meadow `#68743A` stay. This pass fixes the four real gaps.

No RTS rewrite, no scout / night-guard / raider-outline gameplay, no
Master-volume change, no `.github/workflows` edits.

## Order

1. **Ground.** World-space meadow breakup: dirt patches, tuft striping,
   flowers, pebbles, a cheap static bump. Occupation splat keeps more
   of the road / crop colour so 37 roads are not chewed into olive.
   Farm tiles splat wheat-gold and the shader paints readable furrows.
2. **Roads.** Packed clay `#C8A064` raised to 0.088 m, wider 1.52,
   darker edges, less alpha fade. Worn hamlet lanes stay dirt.
3. **World edge + density.** Seven irregular off-map rings plus an
   on-map rim woodland. Fog veil starts at 1.5 m and covers 42 m.
   Opening dress adds crop rows, extra fences, rocks and a millpond.
   Farm halo doubles the wheat field.
4. **Shadows.** SSAO radius 0.42 (was 0.75–0.85) so the opening smear
   dies. Building / tree contact-AO 0.24. Recommended blur 0.32.
   Bevel catch-light lifted so plaster / timber / roof take form.
5. **Night.** Luma stays ~50. Moon `#A8B8D4`, ambient `#4A5E80`,
   ground tint cool blue, atmosphere 0.55. Windows / fires stay
   `#F5B36B` out to 8–9 m.

## GPU shots

Same cameras as GFX-G. `SNS_GFX_SHOTS=<dir>` on a normal Windows
export. Isolate `user://` with temp `APPDATA` / `XDG_DATA_HOME`.
See `docs/gfx/GPU_SHOTS.md`.
