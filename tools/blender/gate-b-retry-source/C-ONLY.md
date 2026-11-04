# C-only challenger (Godot, no mesh replacement) — for cloud agent
Target: existing live Town Hall mesh (civic_keep.gltf / opening_style town_hall) at same fixture/camera as GATE-B/baseline.
1. Material remap via `material_override`/surface overrides: stone albedo #b8b4a8 roughness 0.85; roof surfaces #c23b2a; timber #5a3a24; no new shaders.
2. Lighting: one warm directional (day ~5500K, 45° elev, soft shadows, shadow bias tuned), sky-colored ambient, SSAO on, mild fog for depth; dusk/night presets with lantern OmniLight at door.
3. Contact grounding: decal/AO blob under footprint; path tile to door.
4. Cost: ~1 h; zero assets. Expectation: limited — mesh stays primitive, so silhouette gain is ~0. It is the control.
