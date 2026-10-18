# Scorecard Phase 3 R52 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Brown mass right third: east lobe enlarged (start x14->
  16 crest pulled in, +7.0 high, z falloff /18) on top of
  the R51 lobe; heightfield extended 64 -> 120 units /
  230 steps so the mass and its faces stay in frame.
  Snow threshold raised h>2.7 -> h>4.2 so the lower east
  face is brown rock, not washed snow; east face (x>18)
  now gets explicit rock+strata colour (its z-gradient
  slope previously classified it as olive dirt/grass —
  that featureless olive face was much of the "pale void"
  read). Result: a brown, strata-banded slope occupies
  the right side from mid-frame to the top-right hill.
  Honest: still not target's full-height right-third
  mountain wall; the mass is a broad slope, village still
  centre-left of it.
- Terrain edge closed: diagnostics this round — cull
  disabled and texture-repeat enabled on the terrain
  material (kept, both correct), flat under-plane v1
  (round114) rejected as mint patches, replaced in
  round120 by a textured far-ground plane (400 units,
  detail texture x120 repeat, y-0.30). No sky/void shows
  anywhere now; honest: a pale fogged far-ground strip is
  still discernible at the extreme bottom-right corner
  beyond the mountain foot.
- Village/castle/paths to mine+summit all kept readable
  left/centre; foot hut/house remain at the mass base.
  No animals invented.

Perf round120: 282 draw calls, 471,341 prims (rise is
the 230-step terrain), ~155,280 authored tris.

Rounds: 113 (lobe+terrain84), 114 (under-plane v1 reject),
115 (terrain120), 116-117 (cull/repeat), 118 (crest in),
119 (east rock strata), 120 (far-ground plane).
Screenshots: phase3/round113.png, round119.png,
round119_hill.png, round120.png;
scorecard SCORECARD_PHASE3_R52.png.
