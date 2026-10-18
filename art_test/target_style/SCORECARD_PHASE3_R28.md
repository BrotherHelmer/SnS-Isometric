# Scorecard Phase 3 R28 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Flowers as coloured blooms: DONE mechanically. Blooms are now
  merged flattened blobs in EXISTING colour keys (e2543e, ffd94a,
  ff9db0, f2f0e6 — no new draws), 10 clusters x 12, so colour is
  NOT multiplied away by terrain green. Round73 reduced white to
  1-in-6. In frame: small red/yellow/pink specks visible in meadow
  patches (lower centre) — colour survives, but at this camera
  they read as tiny coloured flecks, not lush flower meadows.
  Scale/readability trade-off, honestly noted.
- Tufts: IMPROVED slightly. Blades widened (0.24 x 0.52 cross-quads),
  colour variance darkened (24540f–4e8c2e after round72's pale
  cards), scale 0.6–1.0. They now read as dark grass speck texture
  rather than pale dots, especially mid-frame. Still instanced
  cards at heart — better, not painted.
- Slimmer buildings: IMPROVED. Houses narrowed (wf x0.84 total),
  castle body slimmed (5.4->4.7 wide, 2.4 tall), centre tower
  slimmer/taller (1.9 wide, 2.7), corner towers pulled in.
  Village proportions read slimmer; still chunkier than target.
- Draw calls: 243 (R27: 254) — back under ~250 WITHOUT removing
  life: carrier logs merged into the pre-commit world mesh
  (-8 MeshInstances), mini-figure colours reused existing merged
  keys (-2), blooms merged into existing keys (+0). Figures still
  19 total (13 KayKit + 6 minis).
- Retained: all prior (rotation, gardens, terraces, mine/tower,
  geology, snow, grade). No animals invented.

Perf round73: 243 draw calls, 188,001 prims, ~55,290 authored tris.
Rounds: 72 (blooms merged, slimming, log merge), 73 (tuft/bloom tune).
Screenshots: phase3/round73.png, phase3/round72.png;
scorecard SCORECARD_PHASE3_R28.png.
