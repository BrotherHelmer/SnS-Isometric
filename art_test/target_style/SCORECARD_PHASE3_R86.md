# SCORECARD — Phase 3 R86 (round161): irregular stone texture (internal only)

Reference: R85 round160. Target bottom half, full frame + facade close.
Relief geometry R83-R85 unchanged; this round is the texture under it only.

## Stone texture rework — 7/10
`textures_painted/stone_painted.png` repainted (Pillow, seed 8607, same 2048px
tile, muted warm-grey family so R77 tint-through works unchanged):
- Course heights vary 82-225px (was uniform), stone widths 170-560px with
  staggered broken joints, ~20% of tall stones split into stacked pairs,
  per-stone vertical jitter ±7px so course lines are not ruler-straight.
- Per-stone value spread (±20) + warm/cool shift, lit-top/shadow-bottom
  modelling per stone, soft blotches, sparse large cracks — all at large
  feature scale for uv-0.55 faces (stones are ~150-500px in the tile).
- Stones drawn with x-wrap copies so cylinder (tower) seams do not show a cut.
**Do texture courses still read regular at full frame? No repeating period** —
castle keep/towers and roundhouse bases now show varied block sizes and
warm/cool per-stone values with no tile rhythm to lock onto; masonry courses
remain (they should — it is coursed stone), but they no longer tell the same
uniform story as the relief. In close, texture stones + R85 relief stones are
sometimes hard to tell apart, which is the intent.
Honest remainder: course bands are still broadly horizontal (ashlar-like)
where the target's masonry is more rubble-irregular, and the tile, while
internally non-repeating, is still one tile across all stone faces.

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R86 round161: **273 draws / 312,737 prims / ~141,279 authored tris** — identical
to R85 (texture-only change; no new geometry or colour keys).

Renders: evidence `phase3/round161.png` + `phase3/round161_close.png` (1280x800).
