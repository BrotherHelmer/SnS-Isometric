# Phase 3 R129 — continuous worn ground

Draws 283 (cap 290) | Prims 543,291 of ~550k ceiling (+10,430 vs R128)

## Gap map (door anchors crossing plain grass before)
- octstore door → main path; roundhouse ↔ octstore (centre-east); hut(8.2,6.8) → roundhouse(12,2.5); west chain roundbarn → aframe, west hut → roundbarn; west house (door west) → branch path; east house (door west) → branch path; south octstore → branch end; hill hut → east house (light, edge). Centre working area between castle/octstore/roundhouses thinnest.

## Changes (ground treatment only)
- New `_worn_link(a,b,seed,strength)`: broken worn discs in R118 fringe language (a8895a mid-step always, d9ba7c centre with seeded gaps, 7fae4a fringe blobs), width/position seeded, strength centre .85–.9 / edges .6–.7. 9 links as mapped. First render read too thin — widened (×~1.3–1.5 width, outer step +0.45); same disc counts/keys.
- 4 broad `_ground_patch` worn areas: centre (3.5,0.5 r2.6), (7,3.5 r2.2), west-centre (-2,4.5 r1.9), east-centre (10.5,2 r1.8).
- Paths/props/carriers/yards unchanged; castle apron + hill untouched; no building/tree moves, no new transparent decals.

## Coverage (same HSV warm-earth classifier, both rounds)
- Settlement crop (180,90)-(1150,650): worn 24.29% → 24.58% (+0.29pp)
- Centre crop (450,250)-(950,620): worn 31.13% → 31.87% (+0.74pp)
- Grass still dominant (~3/4 non-worn): worn network on grass, not a dirt carpet.

## Honest verdict
FAIL (self-assessment), borderline ~6.5/10. Connectivity improved in kind — centre + yard-to-yard links read as one lived surface at close/mid distance. At full judge frame the gain is modest (sub-1pp measured) because the R117/R118 path network already carried much of the centre; target's continuous trampled floor remains broader within frozen geometry. Deliberately stopped short of a dirt carpet (constraint + target balance).
