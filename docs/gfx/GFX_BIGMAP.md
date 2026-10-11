# GFX-BIGMAP — Test #13 320×320 province

Stacked on first-screen clean (`cursor/first-screen-clean-a689`, PR #79).
The playable map is now **320×320 tiles**, 25× the old 64-tile island
(about 21× the 70-tile interim). Helmer's laptop **Shard** is the
budget: integrated AMD Radeon, ~1 GB shared VRAM, 1080p.

## Design

Presentation is chunked. Simulation is not.

| Layer | Size | Notes |
| --- | --- | --- |
| Authority grid | 320×320 | Pathfinding, roads, FOW, deposits, rivalry |
| Presentation chunk | 32×32 tiles | Terrain mesh, vegetation MultiMesh, water, LOD |
| Chunk grid | 10×10 | 100 chunks. Unexplored chunks are never built |
| Crater harvest R | 110 | 5× the #12 bowl. Pit and hall stay fractions of R |
| Rival seats | 3–4 | Spread on the 0.74–0.96 R annulus |

### Streaming

1. `setup()` builds only the chunks around the Town Hall (Chebyshev ≤ 1).
2. `_process` streams more chunks with a **7 ms** budget.
3. Near chunks are full terrain + trees + grass.
4. Far chunks (Chebyshev ≤ 3) use 2-tile terrain and tree impostors.
5. Unexplored tiles stay fog. They do not allocate meshes.
6. Occupation changes rebake **built** chunks only.

Pathfinding stays on one `AStarGrid2D` covering the whole map, so roads
and carriers cross chunk borders.

### Content scale

- Town Hall still sits on **0.70–0.85 R**, floor 0.65 R, 360° orbit.
- Pit excavation stays **0.30–0.45 R**.
- Forests, ridges, lakes and rivers are cluster-stamped across the
  province so the extra 21× area is not empty lawn.
- The founding creek, yard and nearby resources are unchanged #12 rules.

### Camera and minimap

- Opening zoom stays 32. Gameplay zoom stays 26.
- On maps ≥ 200 tiles, `zoom_cap` rises to `PROVINCE_ZOOM` 96.
- Strategic pan uses the full map AABB. Closer play still prefers
  revealed bounds.
- Fog of war covers the whole 320 grid. The province atlas
  (`minimap.overview_mode`) is only for the documentation shot.

## Empty first screen (261306 / −Z halls)

The screen shroud used to unproject NDC `z=0`. Under reverse-Z that is
the far plane. Walking 8000 m back to `y=0.04` threw west / −Z seats
off the 320 slab, so every pixel became unknown `#17272A`. The overlay
now rebuilds XZ from the live ortho camera plus scene depth. Opening
stream always builds the hall chunk and its 8-neighbors; the opening
camera stays on the hall (6 m toward the crater) and is not yanked
into a tight FOW box.

The 100-seed founding test now renders every seed and fails if near
chunks are missing, the hall is out of view, or the 3D area is under
60% land.

## Perf table

Filled by `tests/t_bigmap.gd` on lavapipe (proxy for Shard). See
`artifacts/bigmap/perf_table.md` after the run.

| metric | target | measured |
| --- | --- | --- |
| start_new_3d | ≤ 2 s | **796.0 ms** |
| first frame (warm) | ≤ 2 s | **704.0 ms** |
| pan avg / p95 / max | no hitch > 100 ms | **16.26 / 27.63 / 27.63 ms** |
| memory | logged | **102.2 MB** |
| chunks at opening | near-camera only, not 100 | **4 near + 8 far = 12 built** |

## Shots

1920×1080 in `artifacts/bigmap/`:

- `first_261403.png` N, `first_260918.png` NE, `first_262761.png` E
- `first_261500.png` S, `first_261015.png` SW, `first_261306.png` W
- `six_directions_composite.png`
- `overview.png` at province zoom
- `minimap.png` / `minimap_atlas.png` with crater, rivals, resources

## Gates

100-seed founding + variation + distance + rival/resource spread.
15-minute playtest. Save/load on the big map. 0 errors, Master 1.0.
