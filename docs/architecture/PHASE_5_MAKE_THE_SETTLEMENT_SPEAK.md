# Shards & Sovereign — Phase 5 Make the Settlement Speak

**Result: PASS — headless harness green; next step is a human screenshot pass on seed 260821**

Phase 4.2 remains the One Shard loop. This phase adds no buildings, chains, enemies, tech, or soundtrack. It makes the current game readable: named resources, a night that can hurt the yard, pads that show where to build, and a next bet the player does not have to hunt for.

Engine: Godot 4.7 stable (`D:\SnS_Isometric\.tools\godot-4.7\Godot_v4.7-stable_win64_console.exe`). Review seed **260821**. Production scene: `src/GodotClient3D/Scenes/production_3d.tscn`.

## 1. Why this phase

The independent review scored the build **YELLOW**. The sim is real; the first screenshot was not. Two-letter resource codes, SAVE/LOAD on the play strip, a `DEBUG` window title, an empty lawn, and a Lumen bubble that raiders could not enter all failed the “can I read this?” test.

Identity kept: Wyrd temptation, physical logistics, embodied jobs. Rival Binding stays DEPTH. No C# revival.

## 2. Read the screen

| Surface | Change |
| --- | --- |
| Resource chips | Full names: Wood, Planks, Stone, Wheat, Bread, Wyrd |
| Population | `Pop 2/5` |
| Play strip | BUILD / PAUSE / speed / MENU. SAVE and LOAD moved to the pause menu as RESUME + SAVE |
| Window title | `Shard & Sovereign` (clears the editor `(DEBUG)` suffix) |
| Objective | First incomplete step is the visible verb. Opening title is FEED THE SETTLEMENT |
| Pressure | Hidden until an Outpost exists or any Wyrd has been extracted |
| Default zoom | Orthographic 22 (close 18) |

## 3. Expand without trapping

`validate_placement` accepts a site within **two** empty tiles of the road network and reports that a short road will be extended. `request_build` plans those spur tiles before leveling the footprint.

Pad heatmap (`collect_build_pads` + `WorldView3D.show_build_pads`) marks legal grass pads green and tree pads amber while a building is selected.

Ghost: taller amber volume plus a billboard **CLEARING REQUIRED** when the site needs woodcutters first. Overflow / clear-on-full from 4.2 is unchanged.

## 4. Night that costs

Lumen (`is_tile_protected`) is lighting, claim, spawn skip, Hexer drain, and worker shelter. It is **not** a path block or melee skip.

- Night 1: two raiders, damage 2, retreat after 72 s.
- Night 2+: raiders can enter the yard and damage buildings.
- Raiders render if their tile **or a neighbor** is revealed, at ~1.12 scale, with a persistent hostile ring.

Rebuild smoke that required “powered bubbles stop raiders at their boundary” now requires yard damage while Lumen still claims the town.

## 5. Visible next bet

When the objective id becomes `reach`, the camera glances the Shard once. The step list stays in the loop bar until the player opens it; it no longer auto-covers the map. Outpost palette copy: *Pushes your realm toward the Shard. Harvests Wyrd and raises night pressure.*

## 6. Watch the loop

Wider packed-earth roads (`ROAD_WIDTH_SCALE` 1.18), woodland-navy unknown fog, larger cargo props, yard piles that scale with local stock, timber construction crossbeams, and green roof slabs on Town Hall civic wings.

## 7. Tests

Headless (Godot 4.7):

- `tests/phase5_settlement_speak.gd` — PASS (Night 2 reached tile 1 and dropped Town Hall 500 → 64 HP; Night 1 retreated after the tutorial window)
- `tests/godot_rebuild_smoke.gd` — PASS (raiders damage the yard; Lumen still claims)
- `tests/phase4_2_first_ten_minutes.gd` — PASS (Night 2 closest = 2 under one tower)
- `tests/phase4_2_human_playtest_rescue.gd` — PASS (Night 2 closest = 1, melee ticks observed)
- `tests/phase4_2_parse_smoke.gd` — PASS

## 8. Out of scope (still)

Tech tree, trade, extra production chains, hero unit, music pack, C# `src/Simulation` revival, reconnecting `_has_building_clearance` (still stubbed `return true`).
