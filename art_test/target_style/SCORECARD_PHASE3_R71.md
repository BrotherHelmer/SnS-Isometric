# SCORECARD — Phase 3 R71 (round144-146) vs Black's three levers (internal only)

Reference: R70 round143. Target bottom half, full frame + slope close (--hill cam).
R69/R70 gains kept (mid-green trees, MSAA crisp, path web, no specks, sat 0.93).

## Lever 1 — Snow on slope faces — 4.5/10 (partial, honestly weak)
In-material snow added to the terrain shader (not post): height smoothstep(2.8, 5.0)
x world-normal-Y smoothstep(0.30, 0.58) x patch noise sin(x*1.9)*sin(z*1.4), mixed
over the rock/grass albedo. It exists and fires on high flatter NE ground, but inside
the frame the camera-facing slope is steep (normal Y below window) and much of the
visible high ground is covered by terrace/ledge geometry, so snow still barely reads —
the visible white caps are mostly the pre-existing snow blobs. Two threshold
calibrations (rounds 144->146) moved it little. Diagnosis: the approach needs snow
keyed to the NE slope aspect/height band itself (or geometry snow patches on the face),
not wider thresholds. Not solved this round.

## Lever 2 — Terrace grounding — 6.5/10
New `_terrace()` helper: every terrace/ledge plank is now 4 stepped segments, each
seated at `_h` at its own centre, with a retaining skirt (stone-brown box) on the
downhill (+z) edge and both ends sized to the actual height drop. Applied at all 11
terrace sites (_hill_content, _hill_fields x2, _upper_fill, _fill_more x3 + farm,
_top_band worked terraces + wall-foot fields, cf4 row) and the protruding rock-ledge
boxes (ldi/ldi2/ldi3/sli/uli/rf slabs) that read as diving boards in the first slope
close. Crop rows, fence posts and field boulders re-seated per-x on `_h`. Slope close
(round146_slope) shows stepped, skirted terraces sitting on the slope; no floating
edges remain at full frame.

## Lever 3 — Mine colour — 5/10
Position from R70 kept (14.5,-11.5). Headframe now warm timber (7c4c22 posts, 8a5f30
beam, 5d3a1e X-braces), dark iron wheel/cart (2f2d2d, ex grey 4c4c50), wood cart body,
lit lantern (ffd98a) and a red mine pennant. Components contrast the rock, but at full
frame the mine is still visually swamped by the tall grey crest-rock pillars beside
it — the grey reads as "the mine area". Needs those rocks tinted warm or the mine
given a larger timber silhouette; flagged for next round.

**Overall honest self-score ~5.5/10 (R70 ~5.5). Not a Black PASS claim.**
Terrace lever landed; snow and mine-area contrast remain open.

## Perf
R71 round146: **222 draws / 290,641 prims / ~125,460 authored tris** (R70: 218 draws).
Budget <=290 met. Slope close: 114 draws.

Renders: evidence `phase3/round144.png`, `round145.png`, `round146.png` (final) +
`round144/145/146_slope.png` slope closes.
