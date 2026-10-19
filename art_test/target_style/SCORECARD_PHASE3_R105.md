# Phase 3 — R105 Scorecard (round180) — internal only

## Change (`target_style_scene.gd`)
Per-house seeded irregularity (`rng105`, seed from house position; same lessons as stone R85/R92, cones R95):
- **Timber:** corner posts varied in width (0.22–0.38), position (±0.04) and slight tilt; mid rails at per-house heights (±0.24) and widths (0.14–0.21); diagonal braces varied in angle (0.34–0.80 rad), length and placement; centre posts asymmetric (0.16–0.50·wf). **Density varies per house:** sparse houses drop the back/side rails, one brace or a centre post; dense houses gain side diagonals and an extra front stud. Structural readability and shadow gaps kept; no house is chaotic.
- **Plaster patches:** positions (±0.28·wf / ±0.45 on sides), scales (0.80–1.50×) and warmth (seeded choice from the existing 4-tone palette — sun side restricted to the light half, shade side to the darker half, so the R104 sun/shade story survives) vary per house and per face. Cluster scale only, no speckle. Palette reuse means **zero new draw keys**.
- **Scope correction found while working:** only two `_build_house` houses exist; the settlement's plaster/timber motif also lives in 3 huts, 2 aframes and 2 roundhouses. The same seeded treatment was extended there (roundhouse ring posts jittered in angle/radius/width/height + occasional mid ring; aframe/hut corner posts, jittered front rails, irregular plaster front patches) — otherwise the round's effect would have been invisible at judge scale. All use the existing timber key and palette keys.
- First internal render check caught timidity: measured pixel change vs R104 was 0.04% — jitter ranges were amplified (rail ±0.24, patch offsets to ±0.45, scales to 1.5×) before delivery; final measured change 0.37% of frame pixels, concentrated on the buildings.
- Kept: R104 plaster/wood textures, per-face sun/shade story, stone/roofs/meadow/trees/hill unchanged.

## Perf
- Full frame: **281 draws** (unchanged, cap 290), prims 374,256, authored tris ~165,190.

## Judgement (full frame vs target + facade close)
- Full frame: no two plaster buildings now share the same framing — rail heights, post widths, brace angles and patch placement/warmth differ house to house; the regular-grid read of R104 is broken while framing still reads as structure.
- Facade close: patches sit irregularly with soft jagged edges, timber sits proud with shadow gaps, nothing reads as speckle or noise.
- Honest limit: variation is hand-placed but still tidy — posts remain near their structural positions (by design; larger chaos would stop reading as timber framing). The target's walls remain more strongly worked.

## Verdict
**R105: honest self-assessment — the named R104 failure (regular grid) is addressed at the root; borderline overall.** Awaiting Black. Nothing to Helmer.
