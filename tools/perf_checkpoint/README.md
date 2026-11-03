# Perf checkpoint harness (prepared in hotfix 7, not applied)
Measures, without changing shipped settings:
1. lower FPS target: `--gate-fps-cap=30` (Engine.max_fps)
2. 3D scale 85-90 % with native UI: `--gate-render-scale=0.85|0.88` (viewport scaling_3d_scale only; 2D UI stays native)
3. cheaper ground: `--gate-diag-cheap-ground` (ground shader `lod_cheap`=1 on chunk terrain, the existing night path)
4. cheaper vegetation: `--gate-diag-cheap-foliage` (chunk foliage MultiMeshes get a per-vertex StandardMaterial3D with the same albedo)
Run: `powershell -File checkpoint.ps1` on Shard (7 runs x 300 s, ~45 min). Analyse each dir with
`python3 /workspace/h6/an.py <dir>` (fps, 1 % low, GPU median/p99, draw calls) and `tools/gate_placement_metric.py <dir>`
(needs stdout.txt in the dir). Screenshots in each dir show the visual cost of each option.
