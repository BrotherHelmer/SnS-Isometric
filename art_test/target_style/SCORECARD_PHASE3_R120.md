# Phase 3 R120 - Scorecard

## Choice (stated)
Hillside slope surface zones - the slope's surface reading (grass-to-rock transition,
scree, worn patches, vegetation encroachment, snow approach), not its geometry.
R100-R103 rock texture/ledges, snow geometry, all positions frozen.

## Diagnosis (before R120)
- Terrain colour was assigned by local slope alone plus R77/R81 _ground_patch fans;
  there were no scree fans tied to the R102/R103 ledges, no fall-line exposure system,
  and grass stopped wherever slope/terraces happened to end. At full frame the slope
  read as a tan-green mosaic of content (terraces/trees/cliffs) over a smooth coloured
  heightfield, versus the target's worked brown rocky slope against lush grass.
- The mine had terrain dirt painted around it but no worn apron sheet tying it to the
  stone road; snow sat on the crest with no pale scree approach below it.

## What changed (merged into existing colour keys, zero new draws)
- Terrain root (in _build_terrain, slope-masked by x/z/height so valley/village are
  untouched): worn-brown exposure lerp on moderate slopes, olive vegetation held in
  seeded gully bands, pale scree wash below snow height on exposed patches.
- New _slope_fan helper: jagged four-ring fans elongated down the local _h fall line,
  every ring vertex seated on the displaced R101 heightfield. Two build faults were
  found and fixed during the round: single-ring fans chord-buried on convex ground,
  and the first winding was back-face culled (proven with a temporary red marker,
  since removed; final winding renders ~6x the marker area).
- Placed: scree fans (paler two-tone c9b18a over ledge greys) downhill of all 14
  R103 ledges; rock-textured exposure washes with dark cores between ledge clusters;
  grass tongues (7fae4a/4e7d26) climbing six gullies; pale scree approach fans below
  the crest snow; talus below the three cliff planes and on the camera-facing
  southwest face band; a worn two-tone mine apron downhill of the entrance/cart.
- round195 was the first (culled/buried) attempt and is superseded by round196.

## Verification
- Full frame: slope reads patchier and more worked - pale scree sheets under ledges,
  browner exposure zones, green tongues in gullies; mine sits in a worn apron and
  remains the sole crest focal point. Snow geometry, switchback, terraces, watchtower
  all reseat unchanged (fans sit at +0.06-0.11 over _h, under path/terrace tops).
- Hill close: fans follow the slope without floaters; fan edges are still faintly
  discernible as sheets at close range (same honest limit as the path fringe, R118).
- Breakage check: village, paths, castle, trees unchanged - measured change is
  confined to the slope region (1.6% of slope-area pixels vs 0.3% for the culled v1).

## Perf
- round196: draws=283 (cap 290, unchanged - existing keys only, incl. 8f7355|rock),
  prims=492885 (hill 173/453468, close 189/467701). Authored tris ~198k.

## Honest verdict
FAIL as an overall target match (still borderline ~6.5/10 expected). The slope surface
is genuinely more zoned and worked than R119, and scree now belongs to the ledges
instead of floating as unrelated patches. Remainder: at full frame the slope is still
busy with earlier terrace/tree/cliff content, so it reads as a worked modelled hillside
rather than the target's cleaner painted brown slope - that is a content-density limit
of the frozen layout, not something surface zoning alone can remove.
