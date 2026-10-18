# Scorecard Phase 3 R22 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Glow pockets: SOURCE FOUND, mostly killed. Round61 turned glow
  OFF entirely and pockets persisted unchanged — so bloom was NOT
  the source. Actual source: lit snow shelves (sun + sky ambient
  stacking on near-white snow) plus cream-blown boulder undersides.
  Fixes: snow albedo aebfce -> 9fb2c2 (darker blue-grey), snow only
  on slope <=0.90, stone colours darkened (talus/face/scatter).
  round62_hill.png: no blooming pockets; snow reads bright grey-blue
  on shelves, boulder undersides no longer blow cream. Small light
  patches remain where snow shelves sit behind talus — lit snow,
  not bloom. Note: glow is now OFF (its R17 contribution was minor).
- Lichen real: IMPROVED. Larger patch field (sin 1.4/1.1), threshold
  0.52, up to 0.85 lerp to 5f8140. Green-grey lichen areas are now
  visible on the shaded face at hill-close and faintly at full
  frame. Still less crusty/spotted than real lichen texture would be.
- Grass shade light-driven: PARTIAL. Added baked sun-facing slope AO
  (terrain colour darkened by height-gradient facing away from sun,
  x0.16) and AO discs under every tree (extends building AO discs).
  Depth now partly derives from geometry/sun direction and object
  contact, not only painted patches (R21 patches kept). At full
  frame tree contact shadows ground the trees; grass still flatter
  than target's because real-time shadow spread in ortho sun is thin.
- Retained: houses/castle/roofs/canopies/density/composition.
  No animals invented.

## My top-3 remaining first-glance gaps (honest, vs target)
1. Geometry is still plainly flat-shaded low-poly: simple box houses,
   blob trees, faceted terrain. Target reads as painted illustrated
   surfaces over denser modelled detail. This is now THE gap; grade
   and texture tracks are near their limit in this test scene.
2. Ground richness/density: target meadow is dense with tufts,
   stones, worn paths, many small props and figures at smaller
   scale; ours is a smoother green field with larger, sparser
   buildings and fewer, bigger figures.
3. Mountain integration: target's hill is a worked landscape (mine
   entrance, watchtower, paths up, broad snow) woven into the
   settlement; ours is a faceted tan-grey slope with boulders beside
   the village, composition right but content empty.

Rounds: 61 (glow off — pockets persisted, source hunt; lichen up,
sunface AO, tree AO discs), 62 (snow/stones darkened — pockets gone).
Perf round62: 171 draw calls, 110,413 prims, ~28,066 authored tris.
Screenshots: phase3/round62.png, phase3/round62_hill.png;
scorecard SCORECARD_PHASE3_R22.png.
