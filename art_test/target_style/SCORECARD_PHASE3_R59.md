# Scorecard Phase 3 R59 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Light patch: snow in the vertex path now only where
  slope <= 0.55 (was 0.90), so steep faces no longer get
  snow tint through the shader. The remaining light area
  low-right is the lobe's flat high plateau top (gentle
  slope, snow legitimately there by the rule) seen in
  projection against the wall — reduced, not eliminated;
  eliminating it would also strip summit snow.
- Wall breakup: 6 flattened talus cones at the wall foot
  (x16.5-18.5, z-2..-12, half-buried, rock texture) and 5
  outcrop shells protruding on the face (x19.5-21), all
  merged into the existing rock mesh key — no new draws.
  The wall base now reads loose/talus in stretches at
  full frame; the upper face is still largely one plane.
- Life/work on face: a switchback path of dirt discs now
  zigzags ON the face (15.5,-0.5 -> 19.8,-12, following
  _h per disc) with 3 mini workers on it, joining the
  existing face terraces/ledges/props. Path reads faintly
  at full frame, clearly in the hill close area.
- Retained: brown strata wall, clean meadow shader
  separation, village/castle/paths. No animals invented.

Perf round130: 283 draw calls (unchanged), 466,813
prims, ~154,940 authored tris.

Rounds: 130 (full + hill close).
Screenshots: phase3/round130.png, round130_hill.png;
scorecard SCORECARD_PHASE3_R59.png.
