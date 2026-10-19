# SCORECARD — Phase 3 R78 (round153): terracotta roofs + painted panels (internal only)

Reference: R77 round152. Target bottom half, full frame + facade close.
All R69-R77 gains kept (stone tint-through, uv 0.55 stone/plaster, terraces, trees,
crisp MSAA, paths, snow, mine focal).

## 1) Roof red muted to terracotta — 7/10
Root cause note: the painted roof texture itself is already terracotta
(~170,97,66 sampled); the saturated red came from the `bf3f27` roof colour used
for shingle slabs/eaves and untinted roof families.
- Main roof family `bf3f27 -> a15f43` (presets also muted), roof-group material
  tints greyed toward brown, `roofp` materials got muted tint-through
  (0.93,0.84,0.75 lerp colour 0.28), one flag-red roof eave recoloured to 9c4a34.
- Full frame now reads muted terracotta across castle cones, house roofs and
  roundhouses; hue families (terracotta / brown-red / thatch / slate-grey tints)
  remain distinct. Small saturated reds left are intentional fabric (banners,
  market stripes, clothing), not roofs.

## 2) Panels painted, not glued — 6/10
New `_face_patch()` helper: 5-layer jagged fans (outer patch + dark/light sub-fans
+ two mini sub-patches reusing the same layer colour keys), irregular stepped
edges in the R73/R76 fan language, and UVs mapped across the fan so the enlarged
stone/plaster texture shows *inside* the panel instead of a flat tone.
- Castle: all 6 R77 rectangular stone panels replaced by fans on one shared base
  key (`stone.darkened(0.17)` + its dark/light layers = 3 keys for all patches,
  fewer than R77's 6 panel keys); tower shadow strips kept but given internal
  stone insets using pre-existing relief keys (no new draws).
- Houses: lit/shadow front patches and shadow side face replaced by plaster fans
  (same R77 base keys f5ecd2/d3bd96/d8c49c); roof wear replaced by slope fans
  lying on both roof planes (same roof.lightened/darkened base keys).
- Rock fans (R77): already jagged layered `_ground_patch` fans with sub-tones,
  furrows and seated stones — left as-is, they already met this point.
Honest remainder: fans are subtle at full frame (by design — large tonal areas),
and in close they still read as layered tonal shapes over texture rather than
fully modelled stone-by-stone painting. No clean flat rectangles remain.

**Overall honest self-score ~6.5/10 (R77 ~6.5, with the roof regression fixed). Not a Black PASS claim.**

## Perf
R78 round153: **269 draws / 306,059 prims / ~134,481 authored tris** (R77: 266 draws).
Net +3 despite new sub-tones: castle fan keys consolidated, tower insets and roof
fans reuse existing keys.

Renders: evidence `phase3/round153.png` + `phase3/round153_close.png` (1280x800).
