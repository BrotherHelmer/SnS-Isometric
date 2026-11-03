# SnS-Isometric — Full Visual Asset Inventory (Phase 1, 2026-10-18, beta/overnight @141682c r39-housefix)
Target: helmer_target_look_2026-10-18.jpg (bottom half). Bar: MATCHES TARGET, not close. Nothing shown to Helmer, nothing put in game in Phase 1.
Sources: production_asset_catalog.gd, one_shard_defs.gd, opening_style/model_manifest.json, docs/art/ASSET_LEDGER.md, tools/build_opening_style_models.gd (570 lines, procedural Godot generator).

## Summary counts
- Buildings (semantic types): 18 + Road + Construction Site = 20 rows; only ~11 distinct models (Sawmill=Lumber Camp, Farm=House, Outpost=Watchtower, Enemy Camp≈Castle, Wall=bridge model misuse)
- Characters: 16 roles mapped to 7 KayKit GLBs; Animation: 8 Rig_Medium libraries, 139 clips
- Nature/vegetation: 8 opening_style + 15 KayKit nature glTF (mostly unused at runtime)
- Terrain/water/path: 8 systems (all procedural/shader)
- Props/cargo/tools: 20 workyard + 7 cargo + 5 tools = 32
- UI drawn assets: 20 icons + 9 frames/buttons + 16 building thumbs + 2 fonts + title = 48 files
- Markers/FX: 8 systems
- TOTAL distinct inventory rows below: 118

## 1. Buildings (footprint from defs, size/tri from manifest where authored)
| Asset | Current source | Size/tri | Priority |
|---|---|---|---|
| TOWN_HALL | opening_style/town_hall.tscn procedural | 3.0x3.7x2.8m, 9644 tri | P0 castle-like, must become founding hall distinct from Castle |
| CASTLE | buildings/civic_keep.gltf (KayKit-ish) + opening castle.tscn | 3.0x3.7x2.8, 8988 | P0 target centrepiece: light stone, red conical towers |
| HOUSE | building_home_A_green.gltf / house.tscn | 0.79x0.93x0.85 unit-scaled, 5672 | P0 red steep roof, timber, chimney |
| LUMBER_CAMP | building_lumbermill_green.gltf / lumber_camp.tscn | 2796 | P0 |
| SAWMILL | reuses LUMBER_CAMP model (no distinct asset) | - | P0 needs distinct saw/wheel |
| QUARRY | opening_style/quarry.tscn | 720 tri (far too light) | P0 rocky pit, not placeholder |
| FARM | reuses HOUSE geometry, farm.tscn 5300 | - | P0 barn + crop rows distinct |
| BAKERY | opening bakery.tscn | 9860 | P1 |
| STOREHOUSE | opening storehouse.tscn | 2280 | P1 |
| WATCHTOWER | opening watchtower.tscn | 4872 | P0 target watchtower |
| BARRACKS | opening barracks.tscn | 8504 | P1 |
| WALL | buildings/building_bridge_A.gltf (bridge reused as wall!) + crenellation | - | P0 proper stone wall segment |
| LUMEN_PILLAR | opening, 372 tri | - | P2 fantasy, keep small |
| CLAIMANT_OUTPOST | reuses WATCHTOWER | - | P1 rival colours/flag distinct |
| WYRD_HARVESTER | opening wyrd_harvester.tscn procedural (no .res manifest entry) | - | P1 |
| WYRD_REFINER | opening wyrd_refiner.tscn procedural, r38 kiln fix | - | P1 was dark cube bug |
| ENEMY_CAMP | opening enemy_camp.tscn, 9644 (castle-sized reuse) | - | P1 |
| CONSTRUCTION_SITE | procedural scaffold/ghost in building_view, no catalog asset | - | P0 every building passes through it |
| ROAD (building type) | procedural RoadView + road_rut_decal.png + terrain road stamp | - | P0 dirt path tile target |
| MINE | building_mine_green.gltf EXISTS but orphaned, no MINE building type in defs/catalog | - | Note: do not invent; flag for design |

## 2. Units / carriers / animals
16 roles: settler, founder, carrier, woodcutter, miner, farmer, sawyer, baker, clearer, guard, ranger, enemy_raider, enemy_skitterer, enemy_brute, enemy_hexer, rival_worker -> 7 KayKit GLBs (Rogue, Rogue_Hooded, Farmer_A, Farmer_B, Barbarian, Knight, Ranger, Mage). P0: carrier (target: small, log on shoulder), settler, woodcutter, farmer. P1: guard/ranger/enemies. Animals: NONE exist in game (no wolf/deer/sheep/horse assets or sim entities) — flag, do not add without design GO. Animations: 8 Rig_Medium GLBs, 139 clips (Idle/Walk/Run/Chop/Hammer/Pickaxe/Holding_A verified); Phase 2 must re-time/loop for new proportions, keep name-based bone binding (23 joints).

## 3. Nature / terrain
Trees: fir, fir_tall, spruce, broadleaf, oak, birch + fir_lod, broadleaf_lod (896-1328 tri, opening procedural). Bush 112, grass 56, flowers 328, wheat 476. Rocks: opening rocks.tscn 392 + KayKit Rock_1/2 A/B. KayKit nature (Tree_1-4, Bush, Grass glTF) present in runtime/nature but largely superseded. Terrain: chunked procedural mesh (production_world_view_3d.gd 6704 lines), 4 CC0 splat textures (meadow/forest/dirt/rock 1024), height ridge/hill procedural, snow only via palette (no snow asset), water: settlement_water.gdshader + chunk water mesh, creek: procedural _creek_cut_at + DressCreek/DressBridge procedural bridge (building_bridge_A also exists), roads: shader stamp + rut decal. P0: grass ground colour/texture, broadleaf tree, dirt path, water/bridge. P1: hill/rock/snow.

## 4. Props / cargo / tools (32)
Workyard: wheat_crop, lantern, fence, cart, wood_stack, stump, plank_stack, stone_stack, barrel, crate, long_crate, pitchfork, dirt_plot, carrot, lettuce, wheelbarrow, work_axe, weaponrack, training_target + halo variants. Cargo carried: wood log, plank, stone chunks, wheat sack, bread crate, wyrd/stabilized (Iron_Bar reuse). Tools: axe, pickaxe, hammer, saw, shovel (KayKit RPG Tools CC0).

## 5. UI drawn assets (48)
20 icons (wood, planks, stone, wheat, bread, wyrd, house, pop, worker, soldier, hammer, road, quest, swords, shield, hunger, sun, moon, play/pause/fast, hourglass, menu), 9 frames/buttons (frame_panel/bar/capsule/console/toast/alert/slot, btn_normal/hover/pressed/disabled, tab_active), 16 building thumbnails 160x120 (tools/render_building_thumbnails.gd), fonts Cinzel+SourceSans3 (OFL), title_settlement_v1.png (AI, Steam survey note). P1: thumbs must be re-rendered from new models; icons P2 keep unless style clash.

## 6. Markers / FX (8)
Selection ring (torus), ownership banner/royal flag, building halo props (MultiMesh), placement ghost + hint, road preview, projectile view, Wyrd pressure meter, minimap (procedural Image), day/night + weather palette. P1.

## Pipeline decision (see PIPELINE.md in same folder)
RECOMMENDED: Keep Godot 3D isometric. Rebuild every model procedurally in tools/build_opening_style_models.gd style (extend it) / Blender-free: chunky low-poly (<1500 tri buildings, <800 trees, merged 1 mesh/material surfaces, MultiMesh nature) with warm saturated flat palette + painterly CC0 textures (existing Poly Haven/ambientCG) + soft toon-ish lighting already in palette system. NOT 2D sprites (would lose rotation, day/night, shadows, existing MultiMesh/perf code, 139-clip rig). Blender NOT installed on box (checked), Godot 4.7 at ~/godot/4.7, Python Pillow available, image-gen available for reference only. CC0 packs already owned: KayKit 9 packs (ledger, CC0, D: source, runtime allowlist 127 files), Kenney audio only on box (no Kenney 3D packs found), Poly Haven/ambientCG textures in gfx/. Buy nothing.
Perf guard (Shard iGPU): ~900 draw calls ceiling, no heavy shaders, keep water shader cheap, MultiMesh all foliage/props, LOD pair per tree, textures <=1024.

## Reference sheet harsh judgement
v1 (6 isolated assets row): FAIL — clean but stock-icon look, no terrain/light/shadow context, carrier scale off.
v2 (in-scene): FAIL harsh — castle too dark/large, grass lime, conifer-heavy, no snow.
v3 (in-scene, snow hill, broadleaf mix, smaller castle): PASS internal feasibility for silhouette/palette/composition/scale/light direction; still NOT literal MATCHES TARGET (target is softer painterly, less faceted, lighter yellow-green grass, softer shadows). Verdict: DO NOT show Helmer. Next: reproduce v3 language as real Godot procedural meshes, render in-engine at game camera, then re-judge. That in-engine render is the Helmer gate.
Files: REFERENCE_SHEET_v1.png (target crop + scorecard on box), generated refs at file:///home/box/agent-data/agents/2ce9fdc3-7ac3-439c-a064-ad84e5b88e54/assets/d1de7ed0c48b5b50ab40b594977c60db7366ad16d04a5ef231a7372c070effe8.jpg (v1), .../1c69442fd87b4cc36571658d3daab6f4da64ba8b236f56ec30928fe94ec71a4c.jpg (v2), .../344d4226005485355459bd41e854abb3130ceb43ab446aca77821edf56a434aa.jpg (v3, best)
