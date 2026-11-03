# Scorecard Phase 3 R38 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Choice on summit (stated as requested)
ACCEPT the shoulder landmark (stones visible at (9,-8.8), R37)
AND make the actual top read worked — did not attempt a re-peaked
hill/camera. _top_band adds along the frame-top band: 7 trees
(z -11.8..-17), 5 snow drifts + rock outcrops, a rocky strip and
2 field strips. In round90 the top edge reads tree/snow/rock
worked rather than bare; the true peak is still terrain, not a
composed summit.

## Per point
- Forms beyond boxes: PARTIAL. New round tower house (cylinder
  plaster wall, timber posts, cone roof, stone chimney) replaces
  one cottage at (9.6,1.8) — its round silhouette reads clearly
  centre-right in the full frame, the strongest non-box form so
  far. vi1 houses now have tapered 4-segment cylinder walls
  (radius 1.0 -> 0.90, scaled) instead of a box; at game distance
  the taper is subtle and hard to distinguish from boxes.
  Remaining houses/castle remain box/cylinder constructions.
- Upper density: IMPROVED. _top_band + 2 more field strips
  thicken the upper third; trees/fields now run continuously
  from village to frame top. Still noticeably thinner than
  the village (fewer props/figures up there).
- Draw calls: 289 (<=290 met). Round89 hit 292 with the new
  content; trimmed by recolouring the roundhouse wall and the
  top rocky strip to existing merged keys (-3), no content
  removed. Tris grew to ~128,692 (roundhouse + tapered walls +
  top band).

Perf round90: 289 draw calls, 400,467 prims, ~128,692 tris.
Rounds: 89 (roundhouse, tapered walls, top band), 90 (trim).
Screenshots: phase3/round90.png, phase3/round89.png;
scorecard SCORECARD_PHASE3_R38.png.
