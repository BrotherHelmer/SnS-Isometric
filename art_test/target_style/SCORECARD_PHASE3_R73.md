# SCORECARD — Phase 3 R73 (round148) (internal only)

Reference: R72 round147. Target bottom half, full frame + slope close.
All prior gains kept (terraces grounded, trees, crisp, paths, muted palette, mine frame).

## Lever 1 — Irregular gully snow — 6.5/10
R72's smooth ellipsoids deleted. New `_snow_patch()`: 11-vertex jagged star fans,
radius jitter 0.42-1.28, elongated x1.9 along the local fall line (downhill from the
`_h` gradient at each patch), every vertex seated at `_h+0.07`. Same 16 face areas +
16 smaller satellites as R72. In full frame and slope close the snow now streaks down
gullies/shelves on the camera-facing face instead of pasted ovals. Remainder: fan
outlines are still geometric at close size; patches sit on the face but do not yet
collect preferentially in carved gully geometry (the face has no true gullies).

## Lever 2 — Crest grey competition / mine focal — 5.5/10
Root cause found for why R72's warm tints under-delivered: `mat_for` set
`albedo_color = 0.88 grey` for every textured surface, overriding the per-mesh rock
tint entirely. Rock material now uses a warm base (1.06, 0.97, 0.87) lerped 50%
toward each mesh's own colour, and all remaining `6e665c`/`6e6355` rock colours were
warmed (8f7355/87704f) — tint now actually applies crest-wide. The crest reads warmer
and the mine's timber frame + wheel (top of slope close) remains focal at full frame.
Remainder: a cluster of dark pillar-like rock/tower forms beside the mine still
competes in silhouette at close size; tint alone did not dissolve them — next step
would be geometry (lower/merge them), which Black's order reserved until after tint.

**Overall honest self-score ~6/10 (R72 ~6/10). Not a Black PASS claim.**
Snow improved in kind; crest warmth improved in tone but not yet in silhouette.

## Perf
R73 round148: **226 draws / 291,617 prims / ~125,060 authored tris** (R72: 227 draws).
Budget <=290 met. Slope close: 118 draws.

Renders: evidence `phase3/round148.png` + `phase3/round148_slope.png` (1280x800).
