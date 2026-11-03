# Scorecard Phase 3 R48 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Hill shading triangles: terrain grid 104 -> 144 steps
  (cells 0.62 -> 0.44 units) and rock texture-space detail
  up (steep-slope UV 0.09 -> 0.15 into detail_noise). Hill
  close (round105_hill): shading triangles are smaller and
  the face reads more continuous; honest: still smooth-
  shaded low-poly triangles on close inspection, and some
  dark "boulder" forms in the close are flat-sphere rocks,
  not terrain. Frame read improved, not painted rock.
- Aprons: main patch darkened c9ab72 -> 8a6c42/a8895a, plus
  per-feature detail inside the patch: 6 small stones and 4
  dark dirt-stroke boxes (merged, existing colours). Summit
  patch now reads as worked/stony ground in the hill close
  rather than a clean pale oval; the oval outline itself is
  still discernible under the stones feature.
- Canopy interior: foliage texture gained deep shadow
  clusters + light tips (repaint), and per-face colour now
  adds painted cluster patches (dark cluster / light cluster
  by face hash) plus down-face darkening in add_canopy.
  Full frame: canopies read deeper and more mottled, interior
  facet planes less uniform; close still shows triangles.
- Retained: smooth terrain, miniature figures, centre
  forms, roofs, castle, houses, summit. No animals invented.

Perf round105: 287 draw calls (unchanged), 395,771 prims
(rise is the finer terrain grid), ~152,408 authored tris.

Rounds: 105 (full + hill close).
Screenshots: phase3/round105.png, phase3/round105_hill.png;
scorecard SCORECARD_PHASE3_R48.png.
