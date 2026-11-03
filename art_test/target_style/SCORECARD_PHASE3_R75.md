# SCORECARD — Phase 3 R75 (round150), scene-wide richness (internal only)

Reference: R74 round149. Target bottom half, full frame. R69-R74 gains kept.

## 1) Building detail — 6.5/10
New `_detail_pass()` over all 13 building sites, cycling four detail types so no two
neighbours match: woodpiles (6 stacked logs), lean-tos (sloped roof on posts + barrel),
crate/sack/barrel clusters, roof dormers with lit window; plus a door lantern + step
stone at every home. Second market stall with red/white striped canopy and goods
blobs; three post-and-rail fence lines. At full frame the stall, fences and prop
clusters read and the settlement feels occupied rather than cloned; dormers are the
weakest (sub-face scale). All merged by colour - only +4 draw calls total.

## 2) Terrain detail — 6/10
Patch-scale only (as briefed; no reintroduced specks): 22 flat ground patches
(1.9-3.7u, meadow/worked-earth tones, y=+0.025 seated), 10 boulders each on a dark
contact disc, 5 fallen logs, 8 low bush canopies. Everything sits on the ground with
contact. Honest remainder: patches still read as soft ellipses ("lens" look) rather
than worked ground with internal variation - they vary tone across the meadow but
carry no texture of their own at frame scale.

## 3) Mine-area calm (secondary) — 6.5/10
Terrace rows within 4.5u of the mine skipped in the four slope field loops
(_upper_fill mf, _fill_more cf/cf2/cf3) - 4 plank rows removed around (14.5,-11.5).
The mine's timber frame + wheel now sits in visibly calmer ground and stays the
crest's sole high point; terraces elsewhere unchanged (grounding from R71 intact).

**Overall honest self-score ~6.5/10 (R74 6/10). Not a Black PASS claim.**
Richness is now scene-wide, but the target's advantage is per-surface hand-painted
detail density and atmosphere, which batch-merged low-poly detail approaches only
partly.

## Perf
R75 round150: **231 draws / 298,609 prims / ~127,396 authored tris** (R74: 227 draws).
Budget <=290 met.

Render: evidence `phase3/round150.png` (1280x800, full frame).
