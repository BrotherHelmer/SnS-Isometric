# Shard & Sovereign — Gameplay Plan on the Approved Nordic Diorama Base

Status: INVESTIGATION + PLAN ONLY (written 19 Oct 2026). No game code was
changed for this document. Base approved by Helmer: diorama v2, branch
`showcase/nordic-diorama` commit `1bf528e`, scene `art_test/nordic_diorama/`.
The visual line is closed; the look matures only inside normal development.

## 1. Current-state inventory (read from code, run where stated)

### The game that exists today
- Entry: `project.godot` -> `src/GodotClient3D/Scenes/production_3d.tscn`
  (nodes: GameRoot, SimulationHost, PresentationAdapter, WorldView3D,
  IsometricCameraRig, LightingRig, AudioRoot, UI CanvasLayer).
- VERIFIED RUNNING: `production_3d.tscn` booted on this box for 90 s with
  0 SCRIPT ERRORs; menu state, day cycle and audio stems all alive.
- Simulation (the real game logic, GDScript):
  `src/GodotClient/Scripts/one_shard_simulation.gd` — 11,381 lines — plus
  helpers: `one_shard_defs.gd` (16 building types: TOWN_HALL, HOUSE,
  LUMBER_CAMP, QUARRY, SAWMILL, FARM, BAKERY, STOREHOUSE, WALL, WATCHTOWER,
  BARRACKS, LUMEN_PILLAR, CLAIMANT_OUTPOST, WYRD_HARVESTER/REFINER, roads;
  resources: wood, planks, stone, wheat, bread, wyrd, stabilized_wyrd),
  `one_shard_economy.gd`, `one_shard_placement.gd`, `one_shard_save_store.gd`,
  `one_shard_raid_intents.gd`, `one_shard_rivalry.gd` (2,145 lines),
  `one_shard_crater_war.gd`, `one_shard_wyrdfall.gd`, scout/discoveries/
  intentions modules.
- The sim is tile-based: default map 320x320 tiles (2.5 m cells -> ~800 m
  world, elevation step 0.45 m, per `production_scale_profile.gd`). It owns a
  `height_map`, slope rules (building footprints allow height range <= 1,
  roads climb <= 2 steps), founding flow (game starts with the Town Hall
  founding choice), `validate_placement` / `request_build`, worker/carrier
  simulation with pathfinding, save/load (`save_to_file`, `load_from_path`,
  `continue_save_path`).
- 3D client: `production_simulation_host.gd` ticks the sim (max 4 ticks per
  render frame, 120 s autosave), `production_3d_game_root.gd` (7,291 lines:
  input, mouse placement -> validate/request_build, HUD, objectives),
  `production_world_view_3d.gd` (6,704 lines: current presentation —
  32-tile ground chunks, fog-of-war shaders, water/coast, roads, building/
  character/road views from `assets/settlement3d/runtime/*` scenes via
  `production_asset_catalog.gd`), isometric camera rig, minimap, audio
  director, `production_gate_autoplay.gd` (bot harness,
  `-- --gate-autoplay=<dir>`, emits probe RESULT PASS/FAIL lines).
- 2D client: `src/GodotClient/Scenes/main.tscn` shares the same sim with a
  2D presentation; several tests target it.
- C# `src/Simulation/*` + `tests/SimulationTests` is a PARALLEL reference
  implementation. It is NOT the runtime (the GDScript host never loads it),
  and dotnet is not installed on this box, so its tests cannot run here.
- Tests: `tests/*.gd` SceneTree scripts run by `tools/linux_ci.sh` as
  `godot --headless --path . --script res://tests/<name>.gd`, plus the full
  release pipeline (import, parse checks, 22 release tests, Xvfb gfx gates,
  Linux/Windows exports).
- KNOWN PRE-EXISTING FAILURE (flagged, not caused by diorama work — the
  gameplay code is byte-identical on `beta/overnight` and
  `showcase/nordic-diorama`): `tests/godot_construction_smoke.gd` currently
  ends `CONSTRUCTION_SMOKE FAIL` on one check, "night raiders do not reveal
  the hidden Shard" (enemy-visibility/fog logic in the 2D client helpers).
  Everything else in that suite passes. This must be fixed or consciously
  waived before milestone sign-off; it is unrelated to the diorama.

### What the diorama provides (reusable)
- Analytic heightfield pattern with plateau blending at building plots and
  carved, height-following path ribbons (`diorama.gd`: `_base_h`, `_h`,
  `_normal`, path carve) — directly mirrors what the sim's `height_map` +
  slope rules need from a presentation.
- Sculpted smooth-shaded builders: castle, three cottage variants, smooth
  rock-face mountain + mine, conifer/broadleaf tree family, scree, bushes,
  in one material factory (`_mat`) with the painted texture set
  (`assets/tex_stone.jpg`, `tex_thatch.jpg`, `tex_grass.jpg` originals +
  muted seamless `*_rich.png` derivatives).
- Light/camera rig PROVEN on this stack: orthographic isometric camera +
  one DirectionalLight3D with `SHADOW_ORTHOGONAL` (PSSM gives no occlusion
  for ortho cameras under this box's Compatibility/llvmpipe renderer;
  ORTHOGONAL is also valid on Forward+ hardware).
- Villager route-walkers (path sampling, terrain following, bob/lean).
- Proven numbers for a static vista: 618 draws / 333k prims with shadows.

### The gap showcase -> game
- Scale: diorama is one 136x100-unit vista; the game world is 320x320 tiles
  (~800 m). Terrain and scatter must be chunked/streamed, not one mesh.
- Interactivity: the diorama has no input, HUD, placement, save/load, fog,
  combat — all of that exists in the current 3D client and must be kept.
- Performance shape: diorama builders spawn ~15-25 MeshInstances per
  building and one material set per scene; at map scale that draw-call
  shape will not hold. Merging per building type / MultiMesh scatter is
  required eventually (Section 5) — explicitly not in Milestone 1.
- Data seam: presentation height must be derived from the sim's
  `height_map` and footprint data (plateau exactly where the sim permits
  building), not from a free-standing art height function.

## 2. Integration approach

RECOMMENDED — presentation-layer swap inside the existing game.
Keep the sim, simulation host, game root (input/placement/HUD/objectives),
camera rig, save/load, audio and the gate harness untouched. Replace what
`production_world_view_3d.gd` draws, in stages, with the diorama technique:
(1) smooth heightfield terrain built from the sim's `height_map`, chunked
like the current ground (32-tile chunks), grass_rich texture + height tint,
plateau blend at building footprints; (2) diorama builders registered as
the views for the building types they cover (castle->TOWN_HALL, cottages->
HOUSE, mine->QUARRY, lumber camp, storehouse), inside the existing
BuildingView/catalog lifecycle so construction states and halos keep
working; (3) the diorama sun rig (single directional light,
SHADOW_ORTHOGONAL) in the existing LightingRig; (4) existing character
view keeps sim pathing; figure restyle comes later. Work on a new branch
off `showcase/nordic-diorama` (suggested `gameplay/diorama-world`);
`beta/overnight` stays untouched until a milestone passes.

MAIN ALTERNATIVE CONSIDERED — fresh game scene grown from
`diorama.tscn`, sim ported in. Rejected: it duplicates ~23k lines of
working client (HUD, camera, placement, save, audio, gates) to re-derive
what already runs, discards the gate-autoplay harness, and puts the
schedule risk on re-plumbing instead of on the look. Also considered and
rejected: keep the current world view and only reskin it — that is the
look generation Helmer has just replaced; it keeps faked contact shading
where the approved base has real cast shadows.

## 3. FIRST PLAYABLE MILESTONE — "Founding Loop on Diorama Ground"

Branch: `gameplay/diorama-world` off `showcase/nordic-diorama`.
Scene: `src/GodotClient3D/Scenes/production_3d.tscn` (the real game).

The player can: boot to the menu, start a New Game, make the founding
Town Hall placement, then place a House, a Lumber Camp and connecting
Roads with the existing mouse placement; workers spawn, walk the sim's
paths, chop and carry wood, and the wood stockpile visibly grows in the
existing HUD; save, quit to menu, Continue, and get the same world back.
Everything renders with the diorama technique: heightfield terrain from
the sim's height_map, castle/cottage/lumber views from the diorama
builders, one unified orthogonal-shadow sun.

IN: sim founding/placement/economy for TOWN_HALL, HOUSE, LUMBER_CAMP,
ROAD (plus STOREHOUSE if the loop needs it as the wood sink — the sim
already decides); existing HUD counters/objectives and placement UI;
existing camera rig; save/load; diorama terrain + the four building
views above; shadow rig.
OUT (deferred, not cut): diorama views for the other 12 building types
(they keep their current views for this one milestone — a temporarily
mixed look is accepted and stated); fog-of-war rework (existing fog
behaviour is kept as-is; if the terrain swap forces a choice, fog ships
in revealed-explore mode rather than being re-engineered); raids/rival/
wyrd presentation changes; roads as height-following ribbons (current
road view stays); minimap/audio changes; any performance optimisation
beyond reporting draws/prims; the C# sim; the 2D client.

Acceptance checks (all verifiable, none by eye alone):
1. Existing suite: `godot --headless --path . --script
   res://tests/godot_construction_smoke.gd` shows no failures beyond the
   one known pre-existing FAIL (night-raider shard reveal), and a 120 s
   windowed `production_3d.tscn` run including New Game entry logs
   0 SCRIPT ERRORs.
2. New headless milestone test (SceneTree script in tests/, written with
   the milestone): drives the sim API — found Town Hall, place House +
   Lumber Camp + Road at valid tiles, advance 600 ticks — and asserts
   the wood stockpile increased and at least one worker completed a
   carry cycle. Prints MILESTONE PASS and exits 0.
3. Save/load round-trip in the same test: save to a temp path, fresh sim,
   load, assert identical building set and inventory.
4. Gate autoplay (`-- --gate-autoplay=<dir>`) on `production_3d.tscn`
   completes its founding probes with RESULT PASS lines and
   0 SCRIPT ERRORs in the log.
5. Unmodified 1280x720 engine capture of a founded New Game showing the
   diorama terrain, castle Town Hall, cottage, lumber camp and cast
   shadow pools; draws/prims printed with the capture and reported
   (reported, not gated, this milestone).
6. Shadow A/B on the game scene: a `--dio-noshadow`-equivalent capture
   (shadows toggled off) proves the occlusion in check 5 is engine-cast,
   with the orthogonal shadow mode engaged.

## 4. Milestone sequence after that (ordered, no dates)

- M2 — Full building family: diorama views for SAWMILL, FARM, BAKERY,
  STOREHOUSE, QUARRY polish, WALL/WATCHTOWER/BARRACKS; roads rebuilt as
  height-following carved ribbons (diorama path technique); tree/rock
  scatter driven by sim map data (forest tiles) instead of decoration.
- M3 — World systems presentation: fog-of-war and minimap reconciled
  with the heightfield; night/raid presentation (enemy camp, combat
  views); performance pass — merge geometry per building type, shared
  materials, MultiMesh trees/rocks, per-chunk draw budget measured
  against the current view's profiler numbers.
- M4 — Sovereign/wyrd/rival presentation on the new base, objectives
  polish, release pipeline green end-to-end (`tools/linux_ci.sh`
  incl. exports), first Helmer milestone showing.

## 5. Risks / blockers and handling

- Perf at map scale (618 draws for one vista today): handled by the
  existing 32-tile chunking for terrain and, in M3, mesh merging per
  building type + MultiMesh scatter. Milestone 1 caps scope to the
  founding area and only reports draws/prims (check 5). Do not optimise
  earlier; do measure from the start.
- Renderer/shadow mode: SHADOW_ORTHOGONAL is required for the ortho
  camera on this box's Compatibility/llvmpipe stack (proven in the
  diorama rounds) and is valid on Forward+; keep
  `directional_shadow_max_distance` modest. Final GPU perf cannot be
  judged on llvmpipe — validate on real hardware in M3.
- Sim/presentation height seam: if the presentation plateau does not
  exactly match the sim's per-footprint height rules, buildings float
  or sink on slopes. Mitigation: presentation reads `height_map` +
  footprint data from the sim and reuses the diorama's plateau blend;
  placement validity already lives in the sim, so the view never
  invents flatness the sim did not grant.
- Fog coupling: current fog lives in the ground-chunk shaders of the
  old world view. Milestone 1 keeps fog behaviour unchanged; the
  reconciliation is M3. Flagged here so nobody discovers it mid-build.
- Pre-existing test failure (Section 1): construction smoke's
  night-raider shard-reveal check FAILs at HEAD on both branches.
  Fix or formally waive before Milestone 1 sign-off; not a diorama
  regression and not a reason to stop, but not to be silently carried.
- Two clients, one sim: presentation work is 3D-only; keep the sim API
  stable so the 2D client and its tests keep running as a logic
  reference.
- C# simulation: reference only. No dotnet on this box; do not plan
  work that requires it. If a future decision revives the C# sim, that
  is a separate project decision, not part of this line.

## 6. Deliberately NOT being done

- No new visual/style rounds, no asset hunts, no style experiments;
  the diorama look matures only as part of the milestones above.
- `art_test/target_style/` stays frozen; the billboard/painted-master
  (ART-03) line stays closed. The old illustrated target is not a
  reference for anything.
- No port to the C# simulation; no 2D-client reskin; no rewrite of
  HUD/input/audio; no performance optimisation inside Milestone 1.
