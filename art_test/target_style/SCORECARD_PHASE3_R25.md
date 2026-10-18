# Scorecard Phase 3 R25 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Orientation: SOLVED mechanically. Houses are now built in local
  coordinates under a per-house Transform3D (house_xf applied in
  box/cyl/blob/roof2, roof instances store full transforms), with
  yaw 0/90/180/270 by position hash. Village reads organic —
  houses face different directions (bottom-row houses side-on,
  lean-tos/dormers rotate with the house). Gardens/door-paths in
  _props2 are still placed for +z facing, so they don't always
  align to rotated doors — noted mismatch, minor at frame scale.
- Figures/life: IMPROVED. 8 walking carriers (was 6) + 5 statics
  (was 3): new mine worker (Tools_/Hammering at the mine, on-slope
  height) and market idle (Rogue_Hooded, General_/Idle_A). Log
  verifies all 5 statics playing clips (Chopping/Idle/Hammering).
  Total 13 figures. Cost is real: each KayKit GLB ≈ 9 draws —
  figures are the dominant draw-call driver (see perf).
- Scale/density: IMPROVED. Houses shrunk slightly (wf x0.92,
  wh x0.94), 2 extra houses in gaps (-5.5,10.8) and (13.5,4.5),
  terraces strengthened (5 crop rows, stronger green/soil contrast
  3f7020/96683c, brighter strip bases). Frame reads denser and
  less big-toy; still larger-scale and thinner than target's
  dense tiny-detail world.
- Terraces: stronger contrast/rows — visible as striped field
  strips on the lower slope below the mine at full frame.
- Retained: watchtower/mine/castle/roofs/canopies/grade/tufts.
  No animals invented.

Perf round68: 243 draw calls (aim was <=~240 — 3 over, reported
honestly; growth is 4 added KayKit figures at ~9 draws each, not
geometry), 165,057 prims, ~43,350 authored tris. Tufts still
900 instanced in 1 draw. Buildings <1500 tri each.

Rounds: 68 only (plus a fixed script error in roof-tint transform
access during the same round).
Screenshots: phase3/round68.png; scorecard SCORECARD_PHASE3_R25.png.
