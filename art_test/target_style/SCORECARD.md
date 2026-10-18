# Phase2 in-engine scorecard — INTERNAL, Helmer sees nothing
Scene: art_test/target_style/target_style.tscn + .gd (beta/overnight, NOT gameplay). Godot 4.7 xvfb, ortho iso camera (11,11,11 -> origin, size 14-15), merged-by-colour meshes.
Perf final: 32 draw calls, 10,088 primitives in frame, ~4,504 authored tris whole vignette (castle/house/hut each <1500). Well under Shard budget; no shaders beyond StandardMaterial.

Rounds:
- R1 FAIL: filmic bleach, lime-yellow grass (dominant 228,254,124 vs target 87,114,34), smooth lollipop trees, white castle, path=disconnected discs, hut hidden.
- R2 FAIL: linear tonemap + connected path + crenellations improved; still neon grass (172,254,93), flat untextured, trees smooth.
- R3 FAIL: flat_mesh() broke sphere crowns (trunks only) — reverted; log fixed horizontal.
- R4 FAIL: target-sampled dark olive grass hue correct, but box-cube trees = Minecraft, rejected.
- R5 (final) NOT MATCHES: composition PASS-ish (castle centre, houses front, hut, carriers on path, trees framing), colour IMPROVED (grass hue family now target olive-green, red roofs, stone warm grey), scale FAIL (buildings too large/sparse vs target dense settlement), light/shadow FAIL (hard dark shadows, flat ambient, no warm painterly glow), terrain FAIL (visible square grass patches, no texture grain — needs CC0 meadow texture + noise, not flat boxes), detail FAIL (no stone courses, roof tiles, thatch strands, window frames; carrier is block figure not KayKit-proportioned), trees FAIL-PASS borderline (rounded canopies right silhouette, but smooth untextured).

Verdict: NOT MATCHES TARGET. Do not show Helmer, do not integrate.
Why still useful: proves pipeline perf + camera + palette sampling method (quantized target colours). Next iteration needs: (1) painterly CC0 meadow/dirt/stone textures on merged meshes, (2) geometry detail pass (stone courses, roof shingle rows, thatch ridges, beams), (3) smaller buildings / denser vignette, (4) soft shadow + warm ambient occlusion/contact AO already in game shaders, (5) real KayKit carrier re-coloured instead of block figure, (6) grass texture noise not square patches.
