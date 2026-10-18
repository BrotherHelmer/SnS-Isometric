# Scorecard Phase 3 R34 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point (MATCHES / NOT)
- Composition / summit in frame: NOT. Summit moved twice
  (16,-16) -> (15.5,-14) -> (18,-11.5, taller stones), camera
  widened/reframed toward the hill twice. In round81 full frame
  the standing stones are still NOT clearly visible — they sit
  at the right edge partly behind slope trees/boulders. The
  reframing also pushed more empty meadow into the lower-left.
  Honest miss: summit placement fights the hill's tree line;
  it needs a cleared shoulder, not just coordinates/camera.
- Upper face filled: PARTIAL. _upper_fill added 4 mid field
  strips with rows, 5 trees, a second slope hut, a connecting
  path network (mine -> fields -> tower -> summit) and fence
  posts between existing features. Upper third has distributed
  content now; in the full frame it still reads sparser than
  the village and the rock expanse between features remains.
- House bodies at distance: NOT (small gains only). Sloped stone
  apron at the wall base, bevel trim under eaves, two shallow
  plaster relief panels per front. In round81_close these read;
  at full frame house bodies still read as plain white boxes —
  the relief is centimetre-scale against a 25-unit frame.
- Shingles decision: KEEP segmented geometry with deepened
  contrast (tints 0.22/0.15, shadow gap 0.46). Evidence:
  round81_close shows individual tiles with tint variance and
  shadow gaps clearly; full frame gains stepped roof texture.
  Cost ~7k tris over R32's 4-row version — pays in close/mid
  read, stated honestly; not reverting.
- Retained: castle relief/spires, canopies, flowers, figures,
  geology/snow, grade. No animals invented.

Perf round81: 292 draw calls (cap ~290 — 2 over, from new
upper-fill merged colours; reported), 327,253 prims,
~103,202 authored tris (R33: 95,818; +8% shingles/hill).

Rounds: 80 (summit lower + house relief, summit still cut),
81 (summit right-third + taller, still tree-occluded).
Screenshots: phase3/round81.png, round81_close.png,
round81_hill.png; scorecard SCORECARD_PHASE3_R34.png.
