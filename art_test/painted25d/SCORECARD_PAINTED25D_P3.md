# SCORECARD — Painted 2.5D Prototype P3 (bounded, internal only)

Gate: >=7/10 style match before any full asset conversion.
**Verdict: FAIL — ~5.5/10 overall (P2 ~5/10, P1 ~4/10). Steady gains, still no full
conversion. R68 untouched (baseline panel). No global shader tweaks; post OFF; same
fixed iso camera/scale and KayKit carrier as P1/P2.**

Changes vs P2: hero-density castle + pine repaint; mountain facets broken with dense
small-facet/stroke/gully modelling; TWO new house silhouette variants (wide cottage with
woodpile lean-to; tall narrow house with dormer + round attic window) — settlement now
8 buildings / 3 silhouettes; terrain mid-detail (5 crop fields with row strokes + hedge
borders, post-and-rail fences, path wear/ruts); +4 pines, +1 boulder for density.

## Per-point honest verdict
- **Castle — 5.5/10.** Individual shaded stone courses, battlements, shingled tower cones,
  planked gate, vine. Still the weakest hero: tower sides read flat grey at full frame —
  stone contrast is lost at distance.
- **Pine — 6/10.** 1,500 needle strokes + cluster dabs per tree now read textured at close
  size; tiers still stylised/regimented at full frame.
- **House variants — 6.5/10.** Best point this round: three genuinely different
  silhouettes/masses/details distributed through the settlement; clone problem solved
  in principle (same hero painting system, ~1 asset-hour each to extend).
- **Mountain — 5/10.** Facets now broken by 90 small facet polygons + 800 strokes +
  gully lines; still reads as a pasted backdrop band on a flat field at its base.
- **Terrain mid-detail — 5/10.** Fields/fences/path-wear survive at full frame (mid scale
  as required) and fill the empty field; but field geometry is straight-edged/striped,
  fences read partly as shadow bands at close size, ground remains one flat slope.
- **Palette — 6/10.** Muted calibration holds across all new assets.
- **Sitting-in-landscape — 6/10.** Anchors/contact shadows hold for all new sprites.
- **Carrier / overlap — 7/10 (technical PASS).** Carrier walks between variant houses,
  foreground pine occludes correctly (close render).
- **First-glance kind — 5/10.** Now reads "painted storybook village diorama with fields
  and a mountain" — closer in kind, but target is denser, richer-textured, more
  atmospheric; ours is still clean and sparse by comparison.

Note: first P3 render had a real bug (field row layers composited as black bands);
fixed in the texture painter (alpha-intersect paste) and re-rendered — renders here are
the fixed version.

## Diagnosis
Cause remains **artwork richness + scene density**, not camera/integration/shaders.
Trajectory 4 -> 5 -> 5.5 across P1-P3 with per-asset hero-density work; the gap to 7/10
is now mostly: castle stone contrast at distance, terrain surface richness (meadow
texture, settlement clutter, path network), building count/variety, and depth/atmosphere
in the painted layers themselves. All are bounded per-asset painting work; the hybrid
2.5D pipeline remains proven and cheap.

## Perf
P3 full frame: **48 draw calls, 31,398 primitives** (P2: 42/31,386; R68: 288/482,213).

Renders: evidence `painted25d/p3_full.png`, `painted25d/p3_close.png` (1280x800).
