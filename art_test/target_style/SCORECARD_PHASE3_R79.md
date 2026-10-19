# SCORECARD — Phase 3 R79 (round154): per-stone pattern inside panels (internal only)

Reference: R78 round153. Target bottom half, full frame + facade close.
Terracotta roofs and all R69-R78 gains kept.

## Per-stone / pattern variation inside panels — 6/10
`_face_patch()` gained pattern modes; mortar is the panel base showing in gaps:
- **Mode 1 stones** (castle front/keep panels, roundhouse stone base): 3x3 large
  jagged stone fans per panel (~0.35-0.45u), staggered rows, each with a random
  texture UV crop so the uv-0.55 stone texture reads differently per stone, and
  value cycling through the panel's existing 3 layer tones.
- **Mode 3 shingles** (house roof wear): 4 rows of wide flat jagged shingles on
  both slope fans, same value cycling.
- **Mode 2 plaster blobs** (house front/side plaster fans, roundhouse drum):
  irregular sub-patches with random plaster-texture crops.
- Tower shadow strips: internal stone insets increased 3 -> 5 per tower, still
  using pre-existing relief colour keys.
- Scene-wide: castle front+keep, 4 towers, every `_build_house` facade, and both
  `_build_roundhouse` facades (new fans on stone base + plaster drum, front tangent).
Draw discipline: stones reuse the panels' 3 layer colour keys exactly (merged surf
meshes), so per-stone geometry costs no new draws except the roundhouse bases
(+4 total).

Honest remainder: at full frame the per-stone pattern mostly enriches the texture
read rather than reading as individually modelled stones — the facade close shows
the layering, full frame shows denser surfaces. It is a step from R78's tonal
layers, not yet target's hand-painted stone-by-stone density. Terracotta held
(no re-saturation; roofs sampled in-frame remain brown-terracotta).

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R79 round154: **273 draws / 307,185 prims / ~135,785 authored tris** (R78: 269 draws).

Renders: evidence `phase3/round154.png` + `phase3/round154_close.png` (1280x800).
