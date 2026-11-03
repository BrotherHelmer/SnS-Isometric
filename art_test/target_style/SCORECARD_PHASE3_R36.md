# Scorecard Phase 3 R36 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point (MATCHES / NOT)
- Summit central: PARTIAL, still NOT clearly visible. Stones,
  shoulder knoll (in _h) and clearing all moved to (12,-12.5),
  path rerouted from the watchtower, nearby trees shifted.
  In round85 full frame the clearing patch is visible top-centre
  behind the castle tree line, but the stones themselves do not
  silhouette distinctly — grey-on-rock at 25-unit frame, partly
  screened by the (12,-15) backdrop trees. Position is now
  central; readability is the remaining problem (contrast/size),
  not placement.
- Houses beyond boxes: PARTIAL. Per-variant massing added:
  vi0 rear extension with shed roof, vi1 raised wing block,
  vi2 full-height side wing with its own cone cap. Silhouettes
  now differ between houses (top-left complex vs plain cottages);
  at full frame the difference reads as roofline variety more
  than distinct L/tower forms. Bodies remain box-built.
- Upper face density: IMPROVED. Contiguous band added (3 more
  5.8-wide field strips with rows across z~-10) on top of R35
  fill; upper third now has fields/trees/paths across its width
  with fewer bare gaps, still thinner than village density.
- Draw calls: 291 (goal <=290, 1 over — reported). Method that
  worked: house roofs merged by tint group (9 roof MeshInstances
  -> 3 SurfaceTool-merged meshes, prisms first in fresh tools;
  shingle UVs verified intact in round85 — the R10 merge lesson
  applied correctly). That saved ~7 draws, absorbed by new
  content (+massing/hill instances). No life/content removed.
- Retained: shingles kept, castle, canopies, 19 figures,
  geology/snow, grade. No animals invented.

Perf round85: 291 draw calls, 360,265 prims, ~114,294 authored
tris (flat vs R35 despite massing — roof merge offset tris too).

Rounds: 84 (summit central, massing, roof merge attempt failed
on string match — caught), 85 (merge applied line-based, -7).
Screenshots: phase3/round85.png, phase3/round84.png;
scorecard SCORECARD_PHASE3_R36.png.
