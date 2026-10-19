# Phase 3 — R114 Scorecard (round189) — internal only

## MY CHOICE (stated as required): tree canopy internal break-up
A different root than R98/R99 (silhouette/smooth form): the crown's *internal* reading. All layout positions frozen; no wholesale re-layout (Helmer's pending decision).

## Diagnosis
`add_canopy` coloured each canopy face with a continuous sine tone but then shaded it with **smooth radial normals** (`sn2 = (v-origin).normalized()`) — so whatever tonal variation existed was blended into a smooth lump by the lighting. The foliage texture was likewise mapped at small effective scale. Internal read = smooth sub-masses (R99's stated limit), regardless of silhouette work.

## Changes (`add_canopy` + `foliage_painted.png`; colour/shading only, no geometry change)
- **Flat cluster-cell normals:** canopy faces now use the flat face normal `fn` instead of the smooth radial normal — each face is a tonal cell lit as a unit.
- **Quantized cluster tones:** the continuous per-face vary (0.92–1.22 sine) is quantized to 4 steps (0.84/0.96/1.08/1.20), so neighbouring faces group into medium sunlit/mid/deep cluster patches (existing sun-facing warm / shade-cool logic in `add_canopy` kept on top). Faces on the 13×7 canopy sphere are ~0.2–0.4u on a ~2u crown — cluster scale, not leaf dots (R66/R98 no-speckle rule kept).
- `foliage_painted.png` repainted at larger cluster scale: 110 soft cluster cells (55–150px) in the R113 warm olive family (sunlit/mid/deep) with short cluster strokes — mean kept in family (104.8, 126.5, 55.6).
- R113 olive family kept (palette/material unchanged this round except the texture root), counts/spacing/sizes unchanged, canopy still one merged mesh and still a shadow caster (R108), layout and all other surfaces unchanged.

## Perf
- **283 draws**, prims 458,132, authored tris ~165,974 — identical to R113 (no geometry change; normals/tones only).

## Judgement (full frame vs target + tree crops before/after)
- Full frame: crowns no longer read as smooth lumps — internal faceted cluster patches (bright sunlit cells against deep shade clusters) break each crown at judged size, without dot speckle or noise.
- Tree close/crops: cluster cells are clearly visible as medium flat tones following crown curvature. Honest limit: the cells read as *faceted low-poly clusters*, not as painted leaf masses — this is the same construction-limit family Black noted for crowns, but the internal smooth-lump read that R99 left is gone; some shade faces run dark (deep clusters + flat shading), though no crown reads near-black as a whole.

## Verdict
**R114: honest self-assessment — crown internal break-up achieved at cluster scale; borderline overall.** Awaiting Black. Nothing to Helmer.
