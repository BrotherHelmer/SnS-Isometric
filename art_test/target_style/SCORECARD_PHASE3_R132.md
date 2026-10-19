# Phase 3 R132 — measurement-led rock/hill colour

Draws 283 (cap 290) | Prims 543,291 (~550k ceiling) | Authored tris unchanged — texture/material/shader-tone only.

## Choice
Measurement-led rock/hill: by R130/R131 guard tables the largest remaining fixable colour deviation (rock dRGB .098–.110; canopy residual .055 next, roofs guarded).

## Before (classify_r130.py rerun on round207)
Rock/hill median HSV (.176,.510,.569) vs target (.174,.585,.463): hue matched, value +.106 (too light), saturation −.075, dRGB .098. Dedicated hill-brown measure (hill close, hue 8–58° pixels): ours (135,111,51) val .529 — already darker than target's hill crop (164,125,88) val .643. So "too light" belongs to the rock/lich/scree class specifically, not overall hill brown; stated plainly rather than darkening the whole hill.

## Roots, tried in measured order
1. `rock_painted.png`: saturation ×1.22, value ×0.84 (median sat/val .453/.537 → .517/.471). Result: only 1.8% of full-frame pixels moved — terrain steep shader, distance haze and flat zone tones dominate the hill read. Texture kept (it feeds cliffs/ledges) but insufficient alone.
2. Terrain/material roots (two measured steps): terrain rock vertex `8f7a5f`→`6e5638`; terrain shader `rock_c` multiplier (1.06,.88,.66)·(0.30+0.50·v_c) → (0.74,0.60,0.45)·(0.22+0.36·v_c); shader haze on steep faces ×(1−0.62·steep) (snow sits on flat faces and keeps its haze); rock-texture material tint (1.06,.97,.87)→(0.92,.84,.74); cliff albedo 1.30→1.12; pale rock band `bfb096`→`ac9f83`, mottle `c9bda6`→`b0a189`; lich-on-rock `5f8140`→`49682f` (gully vegetation at R120 line untouched). R120 fan/scree/gully colours (a89a80, c9b18a, 7fae4a…) untouched — zones preserved by construction. R100 Voronoi pattern preserved (affine texture transform).

Incident: a `//` comment inserted inside the terrain shader string blanked ALBEDO for one intermediate render (pale frame, same failure mode as R107); caught visually, removed, re-rendered. Final renders verified.

## After (round208, same classifier)
- Rock/hill: dRGB .098 → .075; value .569 → .541 (gap .106 → .078); saturation .510 → .522 (target .585); hue .174 exact.
- Hill-brown close: (135,111,51) → (134,109,49), val .525 — same family; scree fans, grass tongues, pale washes and mine apron still read as zones in the hill panel, not flattened.
- Guards: canopy dRGB .055 → .055 identical; grass .038 → .038; roofs .077 → .081 (classifier spill); dirt .069 → .078 (deepened hill pixels sit in the dirt class — stated). Stone classifier .042 → .075: **no stone material or texture was changed in R132** (diff = rock lines + rock texture only); the class median moved by reclassification spill and the R130 stone root itself is unmoved (texture median still (142,137,129)). Per Black, stone is closed — do not re-cool it on this number.

## Honest verdict
FAIL (self-assessment), borderline ~6.5/10. Rock closed only ~23% (dRGB .098→.075): diminishing returns, because the remaining rock-class lightness lives in the preserved zone tones (pale scree, lich, fan colours) and lit cliff walls that this brief orders kept, and the hill's brown is already darker than target's. Pushing further would flatten R120 zones or chase a classifier artefact. Canopy value/saturation residual remains the next candidate. Nothing shown to Helmer.
