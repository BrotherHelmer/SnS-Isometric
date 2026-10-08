# GFX-E: grade, woodland, grass, shadows (presentation only)

Stacked on GFX-D (`cursor/gfx-d-visual-pass-48a8`, PR #61 / `146b4c3`).
North star: `concept_1.png`. Target: 6/10 (GFX-D review was 4.5–5/10).

An RTX 4070 Vulkan Forward+ capture of #61 is only ~2–3% brighter than
lavapipe, with the same saturation and the same warm yellow-green. The
over-yellow look is real content and grade, not a software-render
artefact. Shadows on the 4070 are only slightly softer.

No RTS rewrite, no scout / night-guard / raider-outline gameplay, no
Master-volume change, no `.github/workflows` edits.

## Shipped

- **Neutral grade**: day sat 0.95 / exposure 0.90 / sun `#FFE1BD` at 0.95,
  ambient `#899DAA` 0.45, ground tint white. Warmth lives on the key only.
  Night moon/ambient/fill stay at the GFX-B readability floors.
- **Checkerboard gone**: vertex colour is occupation only. Meadow hue is
  world-space multi-scale noise (`macro` / `patch` / `fine`) so 2.5 m
  isometric diamonds cannot print a tile check. Palette is ChatGPT
  meadow `#657A49` / sun `#82945D` / deep `#455F3C`.
- **Woodland**: ~55% conifer / 30% deciduous / 15% LOD, scale 0.8–1.4×,
  dark firs `#233E34`. Kit is fir, fir_tall, spruce, broadleaf, oak,
  birch, fir_lod, broadleaf_lod.
- **Grass clumps**: runtime 4-blade tuft with authored greens. The tree
  foliage shader is no longer applied to short grass (that was the
  black-ant read).
- **Shadows / AO**: Recommended bias 0.04, normal 1.0, opacity 1.0, 2
  PSSM splits, tree contact AO, edge-forest shadows on. Blend splits and
  4-split stay behind High.
- **Roads / footprints**: worn earth `#A3865F`, chewed shoulders,
  softer occupy splat, ContactAO 0.28 / workyard dirt 0.10.
- **Export packing**: birch, fir_tall, oak, spruce, flowers, farm,
  fir_lod, broadleaf_lod (and companion `.res`) plus the GPU-shot
  autoload are in `export_files`. The packing audit now scans
  code-referenced `res://` model paths so a stale catalog list cannot
  report `MISSING 0` while a clean export 404s those scenes.

## Performance (4070 blocker)

`5419e50` took ~8 s to start a new game and ~112 s for the first frame
after the showcase village (GFX-D: <1 s / ~9 s). Road lookups and
per-corner colour were O(buildings × tiles × 16). Terrain/grass updates
are now batched: one lookup pass, one colour grid, occupation rebake
without a collision remesh. See `docs/gfx/GFX_E_PERF.md` and
`tests/t_gfx_e_perf.gd`.

## GPU shots

See `docs/gfx/GPU_SHOTS.md`. Env `SNS_GFX_SHOTS=<dir>` on a normal
Windows export renders the comparison cameras at 1920×1080, pauses the
sim, and quits. `fog_edge` is daytime.

## Still off

- Units remain KayKit rigs.
- Coast is still the G1 rounded-rect.
- True volumetrics / SSIL / SDFGI stay postponed.
- Opening day is still one civic cottage plus a forest rim, not the
  finished concept hamlet.
