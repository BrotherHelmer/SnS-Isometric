# Scorecard Phase 3 R16 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per criterion
- Sunlit broken rock + scree: IMPROVED. Rock palette warmed to sunlit
  grey-brown (base 8d8172, deep 6b5f50, light mottle c9bda6), hill
  steepness modulated by shelf bands (0.80–1.20 sin bands) so the face
  mixes steeper faces with gentler shelves. Face stones enlarged and,
  after round47 showed textured stones rendering near-black, switched
  to untextured warm colours (7a6f5e / c9bda6) — they now silhouette
  distinctly on the face. A 13-boulder talus field at the face base
  (untextured 8d8172 / c4b9a4) reads as a scree slope toe; older
  scattered boulders likewise untextured/lightened. Still NOT: face is
  still more uniformly grey-faceted than target's loose, stony, warm
  slope texture, and talus boulders read a bit large/clean.
- Snow breadth: IMPROVED. Patch noise lowered in frequency
  (x*1.9 / z*1.4), threshold softened (0.34, x4 edge), h>2.7 — white
  areas on the upper face are broader and softer-edged, closer to
  target's caps, though still patchier than target.
- Softness: PARTIAL, small push — ambient 0.42->0.50, sun 0.95->0.88,
  shadow opacity 0.45->0.40, contrast 1.05->1.02. Frame slightly
  gentler; buildings/terrain still sharp low-poly vs painterly target.
  This remains the standing overall gap.
- Retained: composition, bright canopies, shingled roofs, density/life.
  No animals invented.

Rounds: 47 (warm rock, shelves, talus — stones too dark), 48
(untextured light stones, smaller talus).
Perf round48: 167 draw calls, 104,757 prims, ~25,822 authored tris.
Screenshot: phase3/round48.png; scorecard SCORECARD_PHASE3_R16.png.
