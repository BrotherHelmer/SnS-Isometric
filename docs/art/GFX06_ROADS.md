# GFX-06: roads as terrain

Lanes sit in the soil instead of reading as raised board-game pieces.

- Width **18% narrower** (`ROAD_WIDTH_SCALE` 1.18 → 0.97)
- Compacted clay centre `#A88962`, darker dirt edges `#806347`
- Noisy `smoothstep` blend; `shoulder_lift` 0 — no pale graphic border
- **2 batched MultiMesh stamps** for the whole map: wheel tracks and
  junction mud. No per-tile `Decal` nodes or BoxMesh ruts
- Night/reckoning: one-octave terrain noise, stamps hidden, SSAO off
  so lavapipe night stays ≤ +15% vs GFX-1. Day keeps Low/half-res SSAO.

Stacked on GFX-05. No HUD, audio, gameplay or workflow changes.
