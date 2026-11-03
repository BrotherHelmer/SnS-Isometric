# Scorecard Phase 3 R57 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Steep form: east lobe profile changed from smooth
  ease (gain over 6 units) to a cliff profile — run
  compressed to 3.5 units east of x17, pow(e,2.2) so most
  of the +9 height gains near the crest; NE mass likewise
  pow-steepened (2.4/2.0, +11). The right side is now a
  near-vertical rock wall in the full frame (round128
  right), not a broad slope. Watch: the wall is pale
  grey-tan — browner would be closer to target.
- Meadow/face detail separated: terrain now uses a custom
  spatial shader (slope-blended by world normal Y):
  meadow samples the REPAINTED clean detail texture
  (soft mottling/tuft strokes only — the R56 strata/crack
  overlay is gone from grass, contour bands eliminated,
  verified in round128 foreground), steep faces sample
  rock_painted at world (x, height) coords. First shader
  exposure (round127, grass x1.9) blew out the frame;
  corrected to grass x1.02 / rock (0.26+0.48*v) in 128.
  Hill close: drawn cracks + strata on the wall from the
  rock texture itself, no vertex-facet dependence.
- Features on new _h: east terraces moved downslope to
  the cliff base (x15.5-19, they were at x17.5-23 on the
  old profile and would have floated/buried), ledges
  likewise (x18.5-20.5); mine/watchtower/summit sit west
  of x17 and are unaffected by the lobe profile; paths
  use _h per disc and follow. Terraces now read as a
  worked band at the wall foot.
- Strip/fog: unchanged from R56 (fog colour, accepted).
  Village left/centre readable. No animals invented.

Perf round128: 283 draw calls, 462,589 prims, ~152,044
authored tris.

Rounds: 127 (cliff+shader, exposure reject), 128 (kept;
full + hill close).
Screenshots: phase3/round127.png (reject evidence),
round128.png, round128_hill.png;
scorecard SCORECARD_PHASE3_R57.png.
