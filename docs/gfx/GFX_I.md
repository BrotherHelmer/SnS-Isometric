# GFX-I: shroud, local light, ground clumps, trim, ridge

Stacked on GFX-H (`cursor/gfx-h-visual-pass-a689`, `58ae447`, PR #65).
North star: `concept_1.png`. ChatGPT scored GFX-H at **6.0/10**;
target is **7**. This pass does not retune the global grade
(sat 1.12 / contrast 1.12 / exposure 0.86).

Keep from H: vegetation, wheat, roads, opening village, conifers,
blue night. Revert only the GFX-H haze.

No RTS rewrite, no scout / night-guard / raider-outline gameplay, no
Master-volume change, no `.github/workflows` edits.

## Order

1. **Haze off + world-space shroud.** Environment fog and volumetric
   fog stay disabled. FOW is a world-space sheet: visible 0, explored
   0.55, unexplored 1.0, colour `#17272A`, irregular 1–2 cell feather.
   Off-map stays opaque so zoom-out cannot read a diamond board.
2. **Local lighting.** Sun `#FFE8CE` at 1.10 and 38°, shadow_opacity
   0.85, blur 1.0, ambient `#91A29A` at 0.32, SSAO radius 0.55 /
   intensity 1.10. Night stays moonlit blue.
3. **Medium-scale ground patches.** Chunked MultiMesh clumps (40 m)
   of darker grass, soil, flowers and stones. Existing splat / wheat /
   roads stay.
4. **Trim sheets.** Town Hall, house and bakery share plaster
   `#D6C5A2`, timber `#553C2B`, roof `#426863`, stone `#A39A85`.
   Town Hall masonry has a luma floor so it is not near-black.
5. **Opening landmark.** A rocky ridge and creek west of the millpond,
   about one to two Town Hall widths, presentation only.

## GPU shots

Same cameras as GFX-H. `SNS_GFX_SHOTS=<dir>` on a normal Windows
export. Isolate `user://` with temp `APPDATA` / `XDG_DATA_HOME`.
See `docs/gfx/GPU_SHOTS.md`.
