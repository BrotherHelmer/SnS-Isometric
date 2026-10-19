# Phase 3 R137 — FIRST WHOLESALE VILLAGE RE-LAYOUT (round213, round 1 of re-layout)

Draws 288 (cap 290; R135: 283) | Prims 521,021 (~550k ceiling; R135: 543,291) | Internal only — nothing shown to Helmer (Black PASS only).
Start point verified: HEAD b6c9ce5 (R135). Partial R136 (roof-shader tweak in target_style_scene.gd + evidence round212.png) was found uncommitted and RESTORED to b6c9ce5 before starting (`git checkout b6c9ce5 -- art_test/target_style`); round212 is superseded by round213. Closed colour classes stone/canopy/dirt NOT reopened; sun/shadow rig R108/R109 unchanged; no material/texture changes at all this round — placement only.

## Layout plan (written as designed, before results)
Target composition read: castle is the central focal with a clear apron; the settlement spreads WIDER on a larger-feeling disc in loose small groups, with trees BETWEEN buildings (buildings inside woods); an organic branching path network runs from the castle gate to each group with market/workplace nodes; worn ground flows continuously along paths/yards; the hill/mine/watchtower side stays the worked-slope backdrop, mine sole crest focal point.
Zones/groups (castle kept at (-1.5,-3.5), apron kept clear):
- Centre-east group: octstore (7.8,0.8) on its own castle-east branch — moved off the castle's shoulder.
- East group: roundhouse (13.8,-2.2) + roundhouse (15.5,4.5) + house (18.5,10.5) + hill-foot hut (20.5,3.5), stepping toward (not onto) the hill; watchtower/mine/hill huts unmoved in the hill zone.
- South group: hut (5.5,10.8) beside the market stall node (4.2,9.0, kept) on the southern main path; SE octstore (12.5,14.2).
- SW group: aframe (-9.5,10.8) + house (-11.5,13.8).
- West group: hut (-14.5,-1.0) + roundbarn (-15.5,6.5), tree between them at (-15,2.8).
- North group: aframe (-9.5,-11.5) behind-left of the castle, on its own branch.
- Forest framing (R124/R125 far treelines) kept as the valley frame; R127 nestling trees REPLACED by between-building trees: (-15,2.8) west pair, (-5.5,-7.5) castle↔north, (-11,13) SW pair, (9,13.5) south gap, (14.7,1.2) east pair, (-8,-2.5) castle↔west, (10.8,-0.5) centre-east gap, plus the 5+9 existing-language trees re-seated in group gaps.
Path network (one design, three layers):
- Main A (R118 ribbon): west barn front (-15.5,8.8) → SW group → (-3,8) → junction (0.8,8.6) → market (4.2,10.4) → south hut front → SE octstore front (12.5,15.2).
- Castle branch B: castle gate (-1.2,-1.2) → (0.8,8.6) joins A.
- Branches (dirt boxes + R117 worn wpath + R129 worn links): castle→centre-east octstore, castle→east junction→both east roundhouses→east house→hill-foot hut, castle→west junction→west hut→barn, castle→north aframe, castle→hill (existing summit route kept).
- Market node at (4.2,9) where A, B and the cart (2.8,7.2) meet.

## What moved and why (every reference carried together)
All 12 non-castle buildings moved outward from the castle cluster (old radius ~5–11 → new ~8–17, spread x −15.5..20.5 / z −11.5..14.2 vs old −10.5..19.2 / −10..14.2, in looser pairs/triples instead of a ring). For EACH moved building, together: R76 ground patch + contact disc (bp9 list), R128 worked yard on its door side (yp128/hp128 lists; house door dir recomputed from the R105 hang formula at the new position — both SW and east houses now hang PI/north, yards and worn links follow that, not the old side), _detail_pass homes detail/lanterns, _props2 gardens/door-stones, shadow discs, tall flags, barrels/sacks, fences, gardens/plots, bloom zones.
Paths: path_pts polyline redesigned (A+B, break moved i==6→9), branch segment list replaced (9 segments), R117 wpath polylines replaced (5 routes), R129 worn links + 4 worn centres moved to the new doors/junctions.
Life: 8 GLB carriers + 3 merged carriers re-seated ON the new routes (A/B/castle-east/west junctions — verified in close view on the octstore path); shoulder-goods list and _spawn_carriers cps kept identical to each other; statics re-seated at west hut / castle guard / SW yard / hill (hill three unmoved); _mini settlers re-pointed at new path points. One idle GLB static (Rogue, castle-branch) removed — its merged _mini settler remains at (-1,3.5) — to recover draws (see perf).
Hill zone: mine, watchtower, hill huts, terraces, slope zones (R120), aprons — NOT moved (sole crest focal point kept).

## Before/after composition read vs target
Before (R135/round211): castle cluster — most buildings within one tree-length of the castle or hidden behind foreground crowns; centre reads as a dense modelled diorama, disc feels small.
After (round213): castle sits centre-frame with a genuinely clear green apron south and west; buildings read as groups at the frame edges (west pair left, SW pair lower-left, market+south hut bottom-centre, SE store bottom-centre foreground, east pair centre-right, north aframe behind the castle, north-west hut top-left) with meadow and path between them — first-glance disc feels larger, and trees stand between buildings in the west, east and south gaps, not only as a frame. The branching path fan from the castle gate is visible in the full frame (southern main + east/west worn routes).
Still modelled, honestly: in screen space the centre-east octstore + east roundhouses still cluster fairly tight right of the castle; the west/SW houses are partly frame-truncated (target truncates foreground houses too, but ours lose more); foreground forest crowns (R124, unmoved) still veil the lower-left; buildings are the same low-poly forms — no form or colour class was touched, per the hard keeps.

## Perf
Draws 288/290 (R135 283): surf keys identical (169, measured), prims DOWN 543,291→521,021 (position-hash tree cull + one GLB static). The +13 layout draws before trim were character meshes entering the frame on the wider routes; −8 recovered by the one static removal, net +5, inside the hard cap with 2 to spare. Authored tris 231,594 (was ~244k).

## Honest verdict
FAIL (self-assessment), borderline ~6.5/10 — composition improved in kind (wider disc, grouped settlement, castle apron, trees between, branching paths with life on them), not yet in degree: screen-space centre-east density, frame truncation at the west/SW edge, and the unchanged low-poly form language keep first glance at the standing borderline. Colour classes remain closed and measured-stable by construction (no material diff). Nothing shown to Helmer; awaiting Black PASS/FAIL.
