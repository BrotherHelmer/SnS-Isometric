# Scorecard Phase 3 R26 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Gardens/paths aligned: DONE. _props2 now recomputes each house's
  yaw from the same hash as _build_house and transforms garden
  blobs, door stepping-stones and barrels by that basis; house list
  extended to all 9 houses. Gardens sit beside the correct (rotated)
  walls, door stones leave from the actual door side.
- Tiny detail density: IMPROVED. Tufts 900 -> 1600 (still 1 draw),
  +260 instanced flowers in 10 clustered patches (1 draw), +170
  instanced small stones (1 draw, darkened in round70 after round69
  read too white), scatter props 10 -> 18 at smaller scale, 6 extra
  merged bushes, 3 more worn path branches. Meadow reads speckled/
  textured at full frame. Honest: instanced stones still read as
  pale pebble dots and flowers as tiny colour specks — detail is
  present but dot-like, not integrated like target's painted ground.
- Draw calls: 246 (R25: 243). Figures kept (13, ~9 draws each is
  still the dominant cost); growth held to +3 by putting all new
  repeated detail into 3 MultiMesh draws and merged geometry.
  Reported honestly, not trimmed by removing life.
- Retained: orientation, house variety, watchtower/mine/terraces,
  castle, roofs, canopies, grade. No animals invented.

## Top remaining first-glance gaps (my judgement)
1. Scale/silhouette: buildings and trees are still bigger and
   simpler than target's miniature illustrated world — the frame
   reads "low-poly diorama", target reads "painted tiny town".
2. Ground detail quality: ours is instanced dots on green; target's
   ground detail is integrated painted texture (tuft strokes, worn
   earth, stone clusters all in the surface).
3. Life scale/count: 13 relatively large figures vs target's many
   tiny workers everywhere; hill content (mine/tower/terraces)
   still sparse next to target's worked mountain.

Perf round70: 246 draw calls, 192,649 prims, ~58,410 authored tris
(includes 1600 tufts + 430 flower/stone instances, 3 draws total).
Rounds: 69 (alignment + tiny detail), 70 (stones darkened).
Screenshots: phase3/round70.png, phase3/round69.png;
scorecard SCORECARD_PHASE3_R26.png.
