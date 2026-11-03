# SCORECARD — Phase 3 R82 (round157): irregular background variation (internal only)

Reference: R81 round156. Target bottom half, full frame + crest crop.
Single focus per Black. Foreground untouched, baked only, depth structure and
muted treeline kept.

## Irregular variation, mixed sizes — 7/10
**Does the background pattern still repeat at first glance? No — not at full
frame.** Changes:
- Terrain haze noise replaced: R81's single-period 3-sine product (visible
  period across the top strip) -> 4-octave sum at non-integer frequency ratios
  (0.83/0.61, 1.93/1.47, 3.71/2.93, plus a diagonal term), weighted
  0.28/0.20/0.14/0.10 and clamped — large thinned areas sit beside small pale
  patches with no common period to lock onto.
- Seated crest passages (R81 rock fans / snow patches): sizes mixed
  0.85-2.9u (rock) and 0.55-1.6u (snow), count 3->5 each, irregular spacing.
- Crest haze fans and mountain-face rock fans: seeded size variation
  (haze 1.9-3.6u, rock 1.4-3.2u) instead of uniform radii.
Honest remainder: if you study the crest crop, the wash mottling still has a
procedural origin (smooth sine blends, not hand-placed strokes) — but the
first-glance repetition Black flagged is gone, and the recession reads organic
at the size it is actually judged.

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R82 round157: **273 draws / 311,333 prims / ~139,923 authored tris** — draws
identical to R81/R80/R79 (all variation reuses existing colour keys).

Renders: evidence `phase3/round157.png` (1280x800, full frame).
