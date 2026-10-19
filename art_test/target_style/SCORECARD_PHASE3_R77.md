# SCORECARD — Phase 3 R77 (round152): texture density + atmosphere (internal only)

Reference: R76 round151. Target bottom half, full frame + facade close.
Terrace seating untouched. No post/global shaders (R69 crispness kept).

## Large-face variation — 6/10 (large-scale only, per R18/R41/R65/R66 evidence)
- Stone/plaster painted-texture features enlarged per face (uv1_scale 1.0 -> 0.55 in
  `mat_for`), so stone blocks/plaster variation survive at 40-90px faces; stone also
  got tint-through (warm base lerp 45% by mesh colour, same root fix as rock in R73).
  Facade close shows castle/roundhouse stonework reading as large blocks now.
- Castle: 6 large tonal stone patch panels (front wall + keep, +/-10-24% value,
  0.7-1.3u) and shadow-half strips on all 4 corner towers.
- Houses (in `_build_house`, local coords): lit plaster patch + shadow plaster patch
  on the front, a full shadow-side face panel, and one large light wear patch + one
  dark wear patch on the roof slopes.
- Mountain face: 6 large rock-tone fans (2.3u, `_ground_patch` system) draped on the
  slope for tonal variation at face scale.
Honest remainder: panels read as applied tonal slabs at close size (flat colour, no
internal texture of their own - the enlarged stone texture underneath does most of
the real work), and roofs read more saturated red this round than R76's terracotta.

## Atmosphere (baked, not post) — 5.5/10
- Far/back trees (z<-11) tinted toward hazy light green in `_build_tree` colours.
- 4 translucent haze fans (alpha 0.30-0.32, 3.1u) baked over the far crest.
Depth reads a little softer at the back without touching post: no vignette/FXAA
reintroduced, MSAA crispness and cast shadows intact. Effect is subtle - honest
read: atmosphere is still mostly carried by palette, not by layered depth.

**Overall honest self-score ~6.5/10 (R76 ~6.5). Not a Black PASS claim.**
Draw watch: 247 -> 266 this round (haze alpha fans + new patch colour keys mint
new merged meshes). Still <=290, but the merged-by-colour system taxes every new
colour; future richness should reuse existing keys.

## Perf
R77 round152: **266 draws / 305,395 prims / ~133,729 authored tris** (R76: 247 draws).

Renders: evidence `phase3/round152.png` + `phase3/round152_close.png` (1280x800).
