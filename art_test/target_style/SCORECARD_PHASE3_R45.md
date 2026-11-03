# Scorecard Phase 3 R45 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Centre spread: deformed/irregular forms now at frame centre,
  not just edges. Castle: main keep and centre tower rebuilt as
  noised_box stone masses, stepped side wing with cone added,
  deformed prism roof (roof2) over the rear keep, merlon heights
  varied (0.27-0.52). Market stall: flat slab canopy replaced by
  a deformed prism canopy. Huts: noised walls + tilted thatch
  cones. Roundhouses/round barn/oct-store: cone/frustum roofs
  tilted (0.05-0.07 rad) and offset per building.
- Central silhouettes: castle no longer a flat-topped block —
  prism roof + wing + uneven merlons read at full frame (see
  round101 centre-top). Stall/huts read less slab-like.
  Honest limit (same lesson as R43/R44): the wall bulge and
  cone tilts themselves are near-invisible at 25-unit frame;
  what reads is the large additions (castle prism roof, wing).
- Composition: centre now mixes cones, deformed prisms,
  A-frame, round forms and castle towers at first glance;
  no single repeated silhouette dominates the middle.
- Retained: all R43/R44 work, crowd, hill/summit, grade.
  No animals invented.

## Updated top-3 first-glance gaps (honest)
1. Render style itself: textured low-poly models vs target's
   painted illustration — silhouettes/facet planes still
   dominate brushwork at frame scale.
2. Trees: large faceted green masses, taller/bigger than
   target's painted foliage, dominate centre edges.
3. Mountain/terrain: faceted heightfield with features on it
   vs target's painted, edge-to-edge worked landscape;
   figures/props still larger-scale than target's miniature
   detail.

Perf round101: 285 draw calls (unchanged — new roofs merged/
grouped as before), 386,155 prims, ~124,760 authored tris.

Rounds: 101 (full + close).
Screenshots: phase3/round101.png, phase3/round101_close.png;
scorecard SCORECARD_PHASE3_R45.png.
