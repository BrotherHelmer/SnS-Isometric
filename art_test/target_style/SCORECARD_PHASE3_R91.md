# SCORECARD — Phase 3 R91 (round166): blank large stone fix (internal only)

Reference: restored target, R90 round165. Full frame + roundhouse/castle close.

## Root changed: internal variation within very large stones (texture only)
The blank came from R88's large-cell tail (one huge pale cell on the roundhouse
drum). I chose the second preferred root — internal life in very large stones —
rather than capping the tail (varied areas are a validated gain) or resampling
roundhouse UVs (would only move the problem). The texture generation is
byte-identical to R89 (same seed 8813 layout, same warm colour sequence) plus
one independent pass (seed 9101): the 21 cells with area >65,000px each got
9 soft mineral mottling ellipses spread over the stone, 2 faint internal
joints (centre-to-edge, warm mortar colour at low alpha), and 3 extra cracks.
All other stones, mortar, palette, R90's per-face warmth shader and relief
are untouched — so castle large stones gain the same internal life (checked
in the close: castle tower stones show mottling/joints, no regression).
**Does any blank stone remain in close? Partly.** The roundhouse drum's large
pale stone is softer now — tonal mottling is visible across it and it no
longer reads as a flat slab next to the relief — but it is still identifiable
as one large pale area in close, because the mottling is deliberately subtle
(alpha 22-44) and the stone is genuinely big. The blank *slab* reading is
removed; the large *pale stone* reading is not, and would need either stronger
internal contrast or breaking that cell, both of which risk noisier faces.

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R91 round166: **275 draws / 312,749 prims / ~141,279 authored tris** — unchanged
(texture-only; .import/project.godot clone noise unstaged).

Renders: evidence `phase3/round166.png` + `phase3/round166_close.png` (1280x800).
