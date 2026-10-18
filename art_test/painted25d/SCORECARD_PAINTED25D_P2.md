# SCORECARD — Painted 2.5D Prototype P2 (bounded, internal only)

Gate: >=7/10 style match before any full asset conversion.
**Verdict: FAIL — ~5/10 overall (P1 was ~4/10). Improved, still no full conversion.
R68 low-poly scene untouched (baseline panel). No global shader tweaks; post OFF;
same fixed iso camera/scale and same KayKit carrier integration as P1.**

Changes vs P1: ONE hero house repaint (all house instances use it), ONE painted mountain
backdrop sprite behind/right of settlement, palette calibrated DOWN in texture values
(terrain brightness x0.76 / saturation x0.68 after painting, castle x0.86, pine x0.82;
hero house and mountain painted muted directly).

## Per-point honest verdict
- **Hero house — 6/10.** Markedly denser: scalloped shingle rows + 420 clipped roof strokes,
  lit/shadow wall value modelling, plaster patches/cracks, individual shaded foundation
  stones, planked door, shutters/flower boxes, vine + base grass. At close size it reads
  painted, not clip-art. Held back: still clean/geometric at full frame, and every house
  is the same hero clone (flips/tints only) — target has unique buildings.
- **Mountain / landform — 4.5/10.** New: layered facet value modelling, snow caps, scree,
  foothill pines; sits behind/right in the right third like the target and finally gives
  the frame a landform. Held back: facets are still large flat polygons, snow is blobby,
  and its foothill strip reads as a pasted band on the flat field.
- **Palette — 6/10.** Neon is gone; field/houses/mountain now land muted and close to the
  target's value range. Terrain path is now slightly too faint, field a bit uniform.
- **Sitting-in-landscape — 6/10.** Unchanged strength: contact shadows/anchors hold,
  mountain base sits on the slope without floating.
- **Carrier / overlap — 7/10 (technical PASS, unchanged).** 3D carrier walks between hero
  houses; foreground pine still occludes him correctly (close render).
- **First-glance kind — 4.5/10.** Layout now echoes target (castle centre, village,
  snow mountain right), but first glance still says "flat painted-storybook diorama on
  an empty field", not the target's dense, textured painted landscape. Castle and pines
  are still P1-flat and are now the weakest assets in frame; terrain has no mid-scale
  texture or settlement density (fields, fences, more varied buildings).

## Diagnosis
Cause remains **artwork density + composition**, not camera/integration. P2 proves the
two approved levers work (hero-density painting +6->house, painted landform backdrop,
texture-level palette calibration). Remaining gap is per-asset density for castle/pines,
building variety, and terrain mid-detail — all artwork, all bounded per-asset work.
Suggested next bounded step (only if approved): hero-density castle section + pine, and
2-3 house silhouette variants from the hero painting system; retest same gate.

## Perf
P2 full frame: **42 draw calls, 31,386 primitives** (P1: 41 / 31,384; R68: 288 / 482,213).
Mountain backdrop = 1 draw call.

Renders: evidence `painted25d/p2_full.png`, `painted25d/p2_close.png` (1280x800).
