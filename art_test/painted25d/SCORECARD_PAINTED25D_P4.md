# SCORECARD — Painted 2.5D Prototype P4 (bounded, internal only)

Gate: >=7/10 style match before any full asset conversion.
**Verdict: FAIL — ~6/10 overall (P3 5.5, P2 5, P1 4). All four approved points landed,
gains are diminishing. R68 untouched. No global shaders/post; same camera/carrier.**

## Verdict on exactly the four approved points
1. **Castle stone contrast at distance — 5.5/10 (partial).** Stones enlarged (56-72px
   units, 8 courses), value range widened (106-216), dark mortar, top/bottom stone
   shading lines, string courses at 3 heights, thinner tower shading so stones show
   through. Judged on the full frame (castle ~280px tall), the main wall's stonework
   and string courses now read; tower sides are still smoother/lighter than the centre
   and would need stones painted per-tower-face to fully hold.
2. **Terrain richness + clutter/path network — 5.5/10.** Field edges broken (subdivided
   jittered polygons, wavy hedges); a painted path network now connects castle door ->
   junction -> every house cluster, west cottages, and the mountain foot, with edge
   stones; worn yards at all 12 buildings; 110 vegetated blotch/tuft patches; path wear.
   The field is no longer one flat layer, but the ploughed field's straight row striping
   still dominates the lower right and meadow texture between features stays thin.
3. **Density / variation — 6.5/10.** Settlement now 12 buildings reusing the 3-silhouette
   hero system with flips/tints (new: east tall house, west cottage, foreground house,
   castle-back tall house). Density approaches the target's spread without touching the
   carrier's walking spot — carrier still walks between houses, pine overlap intact
   (close render).
4. **Painted depth/atmosphere (in layers, no shaders/post) — 5.5/10.** Mountain gained
   a paler hazier far ridge behind the main mass and painted haze bands (strongest at
   peaks, fading down); terrain texture carries a painted value gradation (pale haze at
   the far/back, richer foreground). Mountain foot pasted band addressed: base alpha
   fades into the slope plus painted rocks/pines spilling below the base line — it now
   grounds noticeably better, though a soft horizontal seam remains visible on close
   inspection.

**First-glance kind: ~6/10.** Reads as a cohesive painted storybook settlement with
fields, path network and a hazy snow mountain. The remaining distance to the target is
not a single named defect: it is the target illustration's overall density of unique
detail, texture and atmosphere on every surface, which this procedural painting system
approaches slowly (4 -> 5 -> 5.5 -> 6 across P1-P4).

## Perf
P4 full frame: **52 draw calls, 31,406 primitives** (P3: 48/31,398; R68: 288/482,213).

Renders: evidence `painted25d/p4_full.png`, `painted25d/p4_close.png` (1280x800).
