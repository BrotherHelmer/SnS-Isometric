# Scorecard Phase 3 R42 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per track
- Soft irregular volumes: MIXED.
  * Bulged walls: noised_box() (BoxMesh verts displaced by
    position-noise, welded by position) now builds house main
    walls. At close the walls are subtly uneven; at full frame
    the bulge (0.05) is invisible — houses still read as boxes.
    Honest: displacement amplitude that survives construction
    (door/window alignment) is too small to change silhouette.
  * Castle towers uneven heights (3.05–3.75 by corner) — reads
    as slight roofline variety on the castle.
  * Canopy displacement + blended normals: TRIED, REVERTED.
    Round96 displaced canopy blobs with 55/45 flat/smooth
    normals read as pale crumpled foil — worse than R41, same
    failure family as R17's smooth canopy. Round97 reverts to
    R41 canopies (faceted, variance-painted). Documented again:
    in this scene, canopy softness cannot come from normals/
    displacement; faceted + colour variance remains best.
- Miniature crowd: IMPROVED. KayKit figures scaled 0.80 -> 0.72;
  +6 merged minis (market, fields, terraces, lower farm) and
  4 goods piles (sacks/barrels). Total figures now 32
  (15 animated KayKit + 17 minis). At full frame the crowd
  reads smaller/denser; minis remain static.
- Mountain integration: IMPROVED modestly. Terrain vertex colour
  now wears dirt toward mine/watchtower/summit (radius 3.2,
  45% lerp) and flat apron discs sit under those features, so
  structures sit IN worn ground instead of on green/rock.
  Subtle at frame scale but removes the "placed on" seam
  around the mine/tower clearings.
- Retained: real-form buildings (7/12 non-box), summit, top
  band, shingles, grade. No animals invented.

Perf round97: 285 draw calls (unchanged), 384,991 prims,
~123,724 authored tris.

Rounds: 96 (bulge + canopy experiment), 97 (canopy reverted).
Screenshots: phase3/round97.png, round97_close.png, round96.png;
scorecard SCORECARD_PHASE3_R42.png.
