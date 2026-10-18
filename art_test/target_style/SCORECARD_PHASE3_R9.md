# Phase3 R9 scorecard — for Black PASS/FAIL, NOT Helmer
Screenshots: round30_close.png (=round32_close, prism debug), round31_close.png (strips), round32.png full, round32_close.png; sheet SCORECARD_PHASE3_R9.png
Perf R32: 140 draws, ~75k prims (full), ~22,350 authored tris; buildings <1500.

UV DEBUG (root cause, concretely):
- Old SurfaceTool prism: replaced by standalone ArrayMesh (add_surface_from_arrays, explicit verts/normals/UVs/index-less tris). Print verified: prism surface_get_arrays UV count 12/12, uv (0,0)->(2,1).
- Merged mesh (after SurfaceTool.append_from into colour-merged mesh): print verified 369 verts / 369 UVs, sample (0.1,0.0). => append_from does NOT drop UVs. Black's suspected root cause is DISPROVEN.
- BaseMaterial3D.TEXTURE_REPEAT_ENABLED does not exist in Godot 4.7 (parse error, removed); repeat comes from import, UV 0-2 wraps on cones (their shingle pattern reads).
- Remaining cause: material/texture, not UV: same roofp material reads on castle cones (cylinder UV) but house prism slopes render smooth; neutral-tint test (0.78->0.88, no colour tint) changed nothing; flush geometry strips (4/slope, normal-offset) also barely read (coincident/thin at camera). Next debug should isolate one prism alone with a checker texture — not done this round, stated honestly.
- Floating old shingle strips: REMOVED (house builder loop deleted; the thin slabs seen at eaves now are the new flush strips at slope edges).

Other points: snow white (kept), vignette (kept), varied carriers (kept). Tree cores/light/density: no further closing this round by instruction (roofs first, still blocked).

VERDICT: NOT MATCHES, headline NOT solved for houses despite UV proof. Do not roll prism texture approach out; isolate single-prism checker test next.
