# Phase 3 R138 — re-layout round 2 (round214): Black's three points

Draws 288 (cap 290, aim ≤288 met — unchanged from R137) | Prims 490,797 (≤~550k; R137: 521,021) | Internal only, nothing to Helmer.
Start: HEAD fffec92 (R137) verified. Placement/screen-space only: no material, texture, colour-class (stone/canopy/dirt closed) or R108/R109 rig changes. Castle kept at (-1.5,-3.5), apron clear, mine sole crest focal (hill zone unmoved). Screen positions below are computed from the actual judge camera (ortho 24.5, pos (13.5,11,11.6) → (3.4,0.6,-2.4), 1280×720), px quoted in 1280-wide frame.

## 1. Centre-east opened (was a tight column/row at px ~690–884, y 453–668)
Moved together, all references carried (ground patch/contact, door yard, detail, props2 gardens, flags, barrels, fences, worn links, branch/wpath segments, carriers/minis/sacks re-tied):
- octstore (7.8,0.8) → (10.5,-3.5): screen (690,453) → (828,425), NE of castle with meadow+path between.
- roundhouse (13.8,-2.2) → (18.0,1.0): (884,470) → (930,546), far right.
- roundhouse (15.5,4.5) → (13.5,7.0): (810,567) → (719,580), down-left — the old vertical column (x≈780–884 for four buildings) is broken into a diagonal fan (828/930/719/831 across y 425–669).
- house (18.5,10.5) → (20.0,9.5): door hang recomputed -PI/2 (west door; was PI/north) — yard, worn link (18,9.5)→(15,9.2) and east wpath follow the west door.
- hill-foot hut (20.5,3.5) → (22.0,4.5) east, opening the roundhouse gap.
- East junction moved (10,-1) → (12,0) (worn centre + branches + wpath re-tied); between-trees re-seated in the opened gaps: (16,4.8) + (17,5.5) between the roundhouses, (11,1.5) + (12.5,2.8) between octstore and roundE2, (19.5→ log pile/sacks/fence re-pointed). GLB carrier (10.5,-0.8) → (8.5,-1.2) on the octstore branch; mini (14,6) → (16,2.5) on the roundE route.

## 2. West/SW pulled into the frame (was house px 6, barn px 37 — hard truncated)
- house (-11.5,13.8) → (-5.5,12.5): screen centre px 6 → ~171, fully inside; hang recomputed 0 (south door; was PI) — yard south, worn link (-5.5,14.7)→(-7,12) to the aframe front.
- roundbarn (-15.5,6.5) → (-12.0,5.0): px 37 → 146, fully inside.
- aframe (-9.5,10.8) → (-7.0,9.8): px 106 → 182, inside.
- hut (-14.5,-1.0) → (-12.5,-1.5): px 189 → 246.
All references carried as R137 (bp9 patches, worked yards, detail homes, props2, tall flags, shadow disc). Path network re-tied: main A west end now barn front (-12,7.2) → (-9.8,9) → aframe front (-7,12) → (-4.5,10.3) → junction; west junction moved (-9,-1.8) → (-8.5,-1.8) with branches to hut door and barn front; west between-tree → (-12.3,1.8) (hut↔barn) and (-10,8) (barn↔aframe); fences/plots/statics (Farmer_A → (-11,0.5), Farmer_B → (-6.2,11.3) between the SW pair)/carriers ((-11,10.2) → (-10.5,8.5) on A) followed. Disc is narrower on the west by design — Black's point was frame truncation, and target's west houses sit inside the image.

## 3. Foreground crowns, bottom-left (R124 near crowns at px 196/241/347, y ~590–600, blurred the corner)
- Two near foreground trees at (-0.5,18) and (0.8,17.2) (px 196/241) REMOVED.
- Remaining bottom band (6.5,17.5), (8,18.5), (13,18) converted from near _build_tree (14+7 crowns) to _build_tree_far (4 low crowns, R125 language): framing trunks/low crowns stay along the bottom edge, occlusion/blur goes. Near foreground framing kept only at the right corner cluster (20,9.5), (21.5,14), (20.3,13.2).
- Supporting moves: south-meadow between-tree (-4,13) → (-1,12.5) off the corner; outer tree (-5,15) → (-10.5,15.5) to the left edge; SW between-tree moved to (-10,8) mid-left, not over the pulled-in houses.

## Before/after screen-space read
R137 (round213): centre-east column right of castle; west house/barn cut at left edge; bottom-left veiled by big near crowns.
R138 (round214): castle still central with clear apron; centre-east reads as a spaced diagonal fan (octstore NE, far roundhouse right, second roundhouse lower-centre, house bottom-right) with trees in the gaps; west group (barn, aframe, house, hut) now sits fully inside the left frame like target's west houses; bottom-left is open green meadow framed by low far crowns at the very bottom edge and the left forest margin. Close view: castle apron/path and carriers clean, no floaters, no door blocked (octstore moved NE out of the close frame, path/minis carry it). Hill view unchanged in content.

## Perf
Draws 288 — EXACTLY unchanged from R137 and at the ≤288 aim (2 under the 290 hard cap): all moves are merged-geometry re-seats; the two removed near trees and three far conversions are canopy-merged (no draw change), and character visibility netted zero. Prims 521,021 → 490,797 (-30,224: far crowns at 4×48 tris replacing near crowns, 2 near trees removed, position-hash cull). Authored tris 219,800.

## Honest verdict
FAIL (self-assessment), borderline ~6.5/10. All three of Black's concrete points are addressed measurably (screen px above) and read at first glance: centre-east opened, west inside frame, bottom-left clear. What remains is exactly what Black named as now-dominant and out of scope this round: form language — buildings/crowns still read as low-poly models against the target's painted masses, and composition gains cannot lift that. Nothing shown to Helmer; awaiting Black PASS/FAIL.
