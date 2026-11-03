# SCORECARD — Phase 3 R100 (round175): rocky hill surface (internal only)

## My choice: switch to the rocky hill/mountain
Trees have had two rounds; their remainder is a construction limit of the
geometry (finer break-up mip-averages, R66). The hill is the largest remaining
non-building surface still reading modelled, and the stone-wall rubble method
has never been applied to rock terrain.

## Diagnosis + rock work — 6/10
Diagnosis: `rock_painted.png` was **horizontal strata bands** with thin
vertical crack lines — the same banding root the stone work removed in
R86-R88 — sampled by the terrain shader's two-plane projection, over a smooth
welded heightfield; geometry rocks (talus/ribs) sat on top of that smooth read.
- Texture repainted (seed 10001, toroidal multi-scale Voronoi like R88):
  broken warm brown-grey rock masses (89 cells, varied areas via clustered
  seeding), multi-direction joints with darker warm crack lines (45% of
  stones), edge shading, blotches. No horizontal bands anywhere in the tile.
- Modelled relief: 8 broken outcrops (flattened deformed spheres, 1.4-2.4u)
  seated into the mid/lower face on existing rock keys (8f7355/96795c|"rock"),
  placed away from the mine so **the mine remains the sole crest focal point**
  (no crest pillars reintroduced, R74 kept) and composition is unchanged
  (one slope in the upper-right, R70).
- Snow: R72/R73 jagged snow patches and both shader snow layers untouched;
  outcrops sit below the snow areas and were checked not to cover patches in
  the hill close. Meadow/trees/buildings/background unchanged; no clash found.
**Does rock stop reading as smooth modelled slope at full frame? Partly.**
Banding is gone and the hill close shows broken rock masses with outcrop
relief; at full frame the face still reads smoother than the target's broken
hill, because the underlying heightfield is a smooth welded surface — texture
and outcrops break the surface read, not the silhouette. That geometry
smoothness is the remaining root if the hill gets another round.

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R100 round175: **275 draws / 372,384 prims / ~163,318 authored tris** — draws
identical (outcrops on existing rock keys); prims +0.3k vs R99.

Renders: evidence `phase3/round175.png` + `phase3/round175_hill.png` (1280x800).
