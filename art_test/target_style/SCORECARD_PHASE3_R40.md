# Scorecard Phase 3 R40 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Hidden forms fixed: A-frame moved (-11.5,-6.5) -> (-6.5,-10)
  and oct-store (11.8,7.5) -> (12.5,11); gardens followed.
  Both now sit in open ground; the A-frame's steep roof and the
  store's stone octagon read in the full frame.
- More real forms: 3 more cottages converted — roundhouse #2 at
  (7.2,-3.8), A-frame #2 at (-3.4,4.6), oct-store #2 at
  (3.2,-1.2) by the castle. Non-box buildings are now 7 of ~12
  (round barn, 2 roundhouses, 2 oct-stores, 2 A-frames) — a
  majority. In round94 the village reads as mixed round/steep/
  box forms, much less cloned. Remaining box cottages keep the
  parametric variants from R24-36.
- Animated activity uphill: DONE via KayKit. Two animated
  statics added on the hill (Farmer_A Chopping on a terrace at
  (6,-6.8), Farmer_B Hammering at (11,-11)) — log-verified
  clips playing, joining the mine worker. Animated figures are
  now 15 KayKit (8 carriers + 7 statics) + 11 static minis.
- Draw calls: 285 (<=290 met). Funding method, reported: dumped
  the merged-key list (107 keys), unified 11 near-duplicate
  prop/stone colours into existing keys (boulders, talus, sacks,
  stepping stones, cart, fence rails...) — that saved ~15 draws,
  more than paying for the 2 KayKit figures (+18) net of other
  merges. Round93 peaked at 300 before unification. No life or
  content removed; palette shifts are sub-perceptual at frame.
- Retained: summit landmark, top band, castle, shingles,
  canopies, grade. No animals invented.

Perf round94: 285 draw calls, 393,923 prims, ~121,452 authored
tris (down vs R39 — converted cottages are cheaper, palette
unification removed no geometry).

Rounds: 93 (moves/conversions/animated uphill, 300 draws),
94 (palette unification -> 285).
Screenshots: phase3/round94.png, phase3/round93.png;
scorecard SCORECARD_PHASE3_R40.png.
