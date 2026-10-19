# SCORECARD — Phase 3 R85 (round160): per-stone irregular relief (internal only)

Reference: R84 round159. Target bottom half, full frame + facade close.
All gains R69-R84 kept (coverage continuous, background R82, terracotta).

## Per-stone irregularity — 6/10
Every relief stone is now seeded-irregular (same geometry counts, same keys):
- Castle keep/towers: width 0.24-0.52u, height 0.20-0.38u, proud depth
  0.05-0.11u, position jitter ±0.035u, tilt ±0.05 rad with ~18% of stones
  tilted to ±0.16 rad; row offsets already staggered so vertical joints
  do not align.
- House foundations: per-house seeded rng (seed from house position), front +
  side blocks varied the same way, so no two houses share a foundation rhythm.
- Roundhouse courses: block width/height/depth and arc angle jittered per
  block on both courses.
**Does masonry still read as uniform rows? At full frame, partly yes** — the
underlying uv-0.55 stone texture's own courses dominate the read and the relief
stones sit in courses by construction (hand-laid masonry does too, but the
target's is more broken). In the facade close the grid is visibly broken:
varied block sizes/depths and shadow gaps no longer line up. Irregularity
landed geometrically; its full-frame read is limited by stone texture regularity
underneath, which is texture work, not relief.

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R85 round160: **273 draws / 312,737 prims / ~141,279 authored tris** — identical
to R84 (same stone counts/keys, only transforms/sizes changed).

Renders: evidence `phase3/round160.png` + `phase3/round160_close.png` (1280x800).
