# Gate B retry — INVENTORY (checkout @ develop/3d, assets/settlement3d/runtime/buildings/)

| file | meshes | tris | bbox m (x×y×z, z=up) | materials | texture |
|---|---|---|---|---|---|
| barrel.gltf|1|240|0.20x0.20x0.21|hexagons_medieval|hexagons_medieval |
| building_barracks_green.gltf|1|4007|1.44x1.57x1.64|hexagons_medieval|hexagons_medieval |
| building_bridge_A.gltf|1|604|1.33x1.92x1.25|hexagons_medieval|hexagons_medieval |
| building_castle_green.gltf|1|5659|1.98x2.26x3.98|hexagons_medieval|hexagons_medieval |
| building_home_A_green.gltf|1|1011|0.79x0.85x0.93|hexagons_medieval|hexagons_medieval |
| building_lumbermill_green.gltf|3|3170|1.37x1.19x1.71|hexagons_medieval|hexagons_medieval |
| building_mine_green.gltf|1|1126|1.61x1.92x1.14|hexagons_medieval|hexagons_medieval |
| building_tower_A_green.gltf|2|2138|0.99x1.15x2.19|hexagons_medieval|hexagons_medieval |
| civic_castle.gltf|143|2568|8.24x7.13x12.53|Material_0,Material_1,Material_2,Material_3,Material_4,Material_5| |
| civic_keep.gltf|114|1788|8.24x6.88x12.53|Material_0,Material_1,Material_2,Material_3,Material_4,Material_5| |
| crate_A_small.gltf|1|132|0.14x0.14x0.14|hexagons_medieval|hexagons_medieval |
| crate_long_A.gltf|1|522|0.40x0.20x0.15|hexagons_medieval|hexagons_medieval |
| target.gltf|1|156|0.24x0.14x0.30|hexagons_medieval|hexagons_medieval |
| weaponrack.gltf|1|42|0.20x0.13x0.24|hexagons_medieval|hexagons_medieval |

Provenance: all `building_*`, props and `hexagons_medieval.png` atlas = KayKit Medieval Hexagon Pack 1.0 (CC0, ledger: docs/art/ASSET_LEDGER.md). 
**Finding:** `civic_keep.gltf` / `civic_castle.gltf` are NOT KayKit — project-authored by `tools/build_civic_keep.gd` (docs/ASSET_LICENSES.md): 114/143 primitive box pieces, only 1788/2568 tri (the "8988 tri" figure in ASSET_INVENTORY is wrong). They are the same procedural-primitive look that failed, so rejected as foundation.
Also available (not in checkout): full KayKit vendor zips on D:\SnS_Isometric\assets\Kaykit (Forest Nature, Hexagon EXTRA/SOURCE) — not used here.
