# Phase 3 R124 - Scorecard

## Choice (stated)
Forest framing at the frame edges - composition, not village layout. No building
moves; R110-R112 positions and the R111 castle apron are frozen and verified clear.

## Diagnosis (before R124)
Target: the settlement sits inside lush framing - foreground tree clusters in the
bottom corners, woods along the left margin, trees behind the castle and climbing
toward the hill. Ours: the village ended in open grass - the bottom of the frame
was empty meadow, the left margin bare, behind the castle mostly sky/grass, and
the village-to-hill transition relied on two trees. First glance read "model on
an open disc" where the target reads "village in a wooded valley".

## What was added (existing tree construction only)
17 trees via _build_tree (R98/R99 canopy construction, R113/R114 olive cluster
language, R80 distance haze on the far ones), placed by screen-projection screening:
every position verified in-frame, passing the builder's R69 hash cull, >3.6u from
any building, >2.2u from path lines, >6.5u from the castle apron centre.
- Foreground bottom band (8, incl. two 2-tree corner clusters at bottom-left and
  bottom-right for larger foreground crowns): crowns cropped by the frame edge,
  settlement centre unobstructed.
- Left margin + background behind castle (6): top-left woods and a tree line
  behind the castle at z=-13.5..-15.
- Village->hill transition (3): seated on _h by the builder, below the mine
  switchback, slope fans (R120) and crest untouched.

## Verification
- Full frame: settlement now sits inside tree masses on three sides; castle still
  central focal, apron air clear, carriers (R119) still visible on routes, mine
  crest unobstructed, no building occluded (nearest framing tree 3.6u+ away).
- Draws unchanged at 283 (canopy is one merged mesh, trunks merge into existing
  surf keys). Prims are the honest cost: 495,717 -> 599,111 (+103k, ~6k per tree
  of canopy spheres) - reported, not hidden; authored tris ~233,864.

## Honest verdict
FAIL as an overall target match (still borderline ~6.5/10 expected), but the
composition gap named in the diagnosis is closed in kind: first glance is now a
wooded valley rather than an open disc, without touching the frozen layout.
Remainder: the target's framing is denser still (continuous woods, foreground
canopy overhanging the top of frame) and our edge trees are discrete clusters;
also the prim cost of the canopy construction is now the scene's largest single
line item, which any future density increase should reckon with.
