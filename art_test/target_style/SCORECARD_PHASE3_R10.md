# Phase3 R10 scorecard — for Black PASS/FAIL, NOT Helmer
Screenshots: prism_test_a..e.png (isolated matrix), prism_mainchecker_close.png (checker in main scene), round33_close.png (PROOF), round33.png full; sheet SCORECARD_PHASE3_R10.png
Perf R33 full: ~131-140 draws, ~68-75k prims, ~21,678 authored tris (prisms now own instances, +7 draws).

CHECKER MATRIX FINDINGS (art_test/prism_test/):
(a) merged-only-prism via SurfaceTool.append_from: checker READS. (b) direct MeshInstance+material_override: READS. (c) unshaded: reads (not lighting). (d) mesh surface material: reads. (e) uv1_scale 2: reads, denser.
=> UV construction, merge-alone, material, filter, lighting all ELIMINATED in isolation.
Main-scene checker swap: checker READS on castle cones (same merged mesh+material as house prisms) but NOT on house prism faces => fault is prism vertices specifically after merging INTO the multi-primitive merged mesh.
Fix that worked: prism NOT merged — own MeshInstance per house with direct StandardMaterial (mode b). round33_close: shingle rows+columns now read clearly ON house faces. Workaround strips REMOVED.
Probable mechanism (stated as probable, not proven): ArrayMesh-with-COLOR-array appended into a SurfaceTool already holding primitive-mesh vertices corrupts/loses its UV channel in the combined surface; cones (primitive, no colour array) unaffected. Isolated merge had no prior primitives, so it worked.
Texture change: roof_painted v4 — 5 rows x ~5 cols, 30px outlines (v3's 10x~17 features mip-averaged away even where sampling worked; checker proved feature size matters too).

Other points unchanged from R8/R9: snow white, vignette, varied carriers; trees/light/density not pushed this round (headline first, now unblocked).
VERDICT: Roofs SOLVED (close proof), overall NOT MATCHES — first glance vs target still distinguishes (geology, painterly richness, density, light).
