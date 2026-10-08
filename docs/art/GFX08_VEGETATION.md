# GFX-08: vegetation MultiMesh kit

The forest edge is no longer one repeated cone.

- **6 authored silhouettes** (GFX-C): fir, fir_tall, spruce, broadleaf,
  oak, birch. Edge forest uses `fir_lod` / `broadleaf_lod`.
- KayKit `Tree_1–4` cones are no longer in the live kit.
- Shared `settlement_foliage.gdshader` — crown wind, trunk/canopy split,
  lifted Nordic greens
- Hue/scale variation through separate MultiMesh batches
- Darker forest-floor discs under every fourth canopy (one MultiMesh)

Stacked on GFX-07. No HUD, audio, gameplay or workflow changes.
