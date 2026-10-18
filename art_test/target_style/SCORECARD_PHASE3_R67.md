# Scorecard Phase 3 R67 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point (judged FULL frame only)
- Value structure (biggest move): sun 0.88 -> 1.04,
  ambient 0.50 -> 0.37, shadow opacity 0.40 -> 0.50,
  grade contrast 1.02 -> 1.08. Forms now separate into
  clearer lit/shadow sides across the whole frame —
  castle, houses, wall and trees all read with stronger
  modelling at first glance (compare the round137
  reference panel in the scorecard).
- Large colour areas: prism-roof instance groups are
  now hue families (warm terracotta / clay brown /
  weathered grey) instead of neutral tints; ground
  large-patch contrast widened (vertex shade factor
  0.74+0.40 -> 0.66+0.54), so meadow zones read as big
  colour areas, not uniform green.
- Canopy two-tone: top-face lightening 0.26 -> 0.38,
  low-face darkening 0.28 -> 0.42 in add_canopy —
  canopies read as light/shadow masses at frame.
- Silhouette: house prism roofs widened 3.35 -> 3.62
  (overhang), main chimney 0.37 -> 0.47 wide. Small at
  frame but in the right direction; cone/canopy
  silhouettes unchanged this round.
- Honest: this is a visible first-glance improvement in
  value/colour structure — the frame has more contrast
  and colour separation than round137. It does not by
  itself make the scene a painting; forms are still
  low-poly geometry, now more strongly lit.

Perf round139: 288 draw calls, 482,213 prims, ~164,788
authored tris (light/material/roof-width only).

Rounds: 139 (full; round137 kept as reference panel).
Screenshots: phase3/round139.png;
scorecard SCORECARD_PHASE3_R67.png.
