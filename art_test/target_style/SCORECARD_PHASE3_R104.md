# Phase 3 — R104 Scorecard (round179) — internal only

## MY CHOICE (stated as required): switch surface to house plaster/timber walls
Reason: named back in R93 and never since addressed — plaster mottling was warm but subtle at frame scale, so house walls read comparatively flat against the target's hand-worked houses at judge scale, while the hill/trees remainders are now geometry construction limits (R103 tablets, R99 crowns).

## Changes
- `plaster_painted.png` repainted at cluster scale (mip-safe, no fine speckle): 30 large soft warm patches (150–430px on a 1024 canvas, tan/pale/grey-warm family) + 46 medium patches + faint vertical weathering streaks and soft blotches; then a ×1.4 deviation-from-mean contrast stretch after first render read too subtle. Features are sized to survive to 40–90px faces.
- `wood_painted.png` repainted for frame-scale structure: 5 strong planks with ±20% per-plank tone, dark 10px gaps, lit plank edges, long low-contrast grain streaks, sparse knots.
- Timber-frame structure made to read at full frame (`_build_house`, existing "timber" key): corner posts widened 0.25→0.31, **mid rails added on front/back/side walls** (full timber-frame grid with the existing top/bottom rails), side diagonal braces added; existing R83/R84 braces, centre posts, foundations kept. All beams proud of the plaster with real shadow gaps.
- Per-face light story on house walls: existing sun-side (+x) plaster patch kept; added a larger cooler/darker shade-side (−x) `_face_patch` (bfa87e, pattern 2) so opposite faces tell different stories, mirroring the R90 stone approach at patch level.
- Stone/roofs/meadow/trees/hill unchanged; roofs remain terracotta-distinct from the warm cream walls.

## Perf
- Full frame: **281 draws** (278 + 3 shade-patch layer keys; cap 290), prims 373,294, authored tris ~164,228.

## Judgement (full frame vs target + facade close)
- Full frame: house walls now carry large warm patch variation (tan/pale areas visible on gable and side walls) and the dark timber mid-rails/posts read as a frame grid on the settlement houses — walls no longer read as flat cream boxes at judge scale.
- Facade close: plaster patches and timber contrast hold up without speckle noise.
- Honest limit: the effect is a clear step, not a transformation — at full-frame house size (~60–90px) the patch variation still reads gentle compared with the target's strongly hand-worked walls, and the timber grid is regular (real timber framing is regular; the target's charm is irregular hand placement).

## Verdict
**R104: honest self-assessment — improvement at the named surface, borderline overall.** Flat-wall read reduced at full frame with no regressions; whether it reaches the target's hand-worked house read is Black's call. Awaiting Black. Nothing to Helmer.
