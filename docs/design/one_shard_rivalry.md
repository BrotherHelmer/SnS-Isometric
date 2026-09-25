# One Shard Rivalry Milestone

## Match Objective

One Shard is now a two-realm skirmish built on the current settlement simulator. The player uses the visible settlement population and workplace economy; the deterministic rival uses one abstract gathering worker on the opposite side of the central Shard. Both sides share Sovereign statistics, Lumen rules, and claim conditions.

The match loop is:

1. Grow the settlement and assign visible workers to gather and process resources.
2. Move the Sovereign into the central region and extract Wyrd.
3. Plan free roads from the Town Hall door and let a free peasant construct them.
4. Build road-connected Lumen Pillars and pay their nightly Wyrd upkeep.
5. Build one Claimant Outpost inside the Shard perimeter.
6. Move the Sovereign into the claim ring and begin the claim.
7. Keep the Outpost, owned road, active connected Lumen, and Sovereign in place without an enemy Sovereign contesting the ring.
8. Hold every condition through one complete night to win at dawn.

The rival uses the same structure placement, Wyrd extraction, combat, incapacitation, and claim commands. It does not receive free buildings or hidden resource income, and an opening truce prevents a rival claim before the player has had time to establish a settlement.

## Controls

- `WASD`: directly move the player Sovereign.
- Left-click empty ground in Select mode: move the Sovereign to that tile.
- Arrow keys or the on-screen direction pad: move the camera.
- Hold right or middle mouse button and drag: pan the camera.
- Mouse wheel, `+`, `-`: zoom.
- `Home`: center the camera on the Town Hall.
- `F`: center the camera on the player Sovereign.
- `E`: extract from a nearby blue Wyrd spring or recover dropped Wyrd.
- `Q`: attack the nearest enemy Sovereign, Lumen Pillar, or Claimant Outpost in range.
- `C` or the `Claim` button: begin a valid Shard claim.
- Build toolbar: select Road, Lumen, Claim Post, or the existing settlement buildings.
- `R`: rotate a supported building before placement.
- `Escape`: cancel the current build action.
- `Space`: pause.
- `L`: open the Realm Chronicle.
- `F3`: toggle rivalry diagnostics.

## Architecture

- `one_shard_simulation.gd` remains the settlement simulation authority for the province, terrain, existing economy, workers, buildings, day/night, raiders, damage, and run flow.
- `one_shard_rivalry.gd` owns explicit player and rival realm state, realm resource interfaces, owned roads, rivalry structures, Sovereigns, Wyrd sites, combat, AI knowledge/planning, Lumen connectivity, and the shared claim state machine.
- `one_shard_rivalry_tuning.gd` centralises rivalry costs, movement, combat, upkeep, AI cadence, vision, respawn, and claim values.
- `one_shard_defs.gd` exposes Wyrd, Lumen Pillar, and Claimant Outpost to the existing data-driven building toolbar.
- `main.gd` is presentation and input only. It renders owned territory, structures, Sovereigns, claim feedback, visual modes, and the focused HUD while requesting mutations from the simulation.

The current central settlement inventory is the player realm ledger. The rival owns a separate ledger. The rivalry API deliberately exposes `can_spend`, `spend`, `request_road`, `request_structure`, `request_extract_wyrd`, `request_attack`, and `request_begin_claim` so later local inventories and physical hauling can replace ledger storage without rewriting AI or UI commands.

## Rival Decision Model

The rival has a compact deterministic utility planner. Every planning interval it scores:

- heal or retreat;
- contest an active player claim;
- obtain Wyrd;
- extend its real owned road;
- extend or restore Lumen;
- defend recent hostile activity;
- save Wood;
- build its Claimant Outpost and claim.

Its knowledge records observed player Sovereign position and age, observed player roads, observed player structures, active Lumen information in sight, and recent hostile activity. Static geography and natural resource sites are known. The player Sovereign is not treated as currently known after the observation memory expires.

If dense road placement leaves no grass for a required Pillar, the rival can demolish one redundant owned road tile and then use the same paid structure-placement command. Navigation failures are bounded and reported through the F3 panel.

Once its Outpost exists, the rival also reserves enough self-extracted Wyrd to restore inactive Pillars and pay the connected network's next nightly upkeep. During a valid night hold it prioritises remaining inside the claim ring instead of leaving to gather for a later night.

## Important Tuning

- Road: free to plan; one free peasant must physically construct each player segment while time is running.
- Lumen Pillar: `8 Wood`, `3 Wyrd`, `1 Wyrd` upkeep each night.
- Claimant Outpost: `18 Wood`, `8 Wyrd`.
- Home Lumen radius: `10` tiles.
- Pillar Lumen radius: `10` tiles.
- Lumen link distance: `17` tiles.
- Sovereign: `100 HP`, `18` damage, `1.8` tile range, `0.9s` cooldown.
- Incapacitation: `14s`, then full-health Town Hall respawn.
- Wyrd extraction: `2.8s`, yields `5 Wyrd`.
- Rival planning interval: `1s`.
- Rival current-position memory: `15s`.
- Claim: one complete `180s` night with all requirements continuously valid.
- Existing settlement day/night: `420s` day, `180s` night.
- The rival cannot begin a claim during the first `2100s` (35 minutes). Its
  deterministic uncontested victory window is therefore roughly 40-50 minutes,
  giving the player time to establish troops, scout, and understand the Shard.

## Debugging

`F3` shows:

- match state;
- current rival goal and destination;
- last known player Sovereign position and observation age;
- owned road counts and rival road frontier;
- connected Lumen source counts;
- claim requirements for both realms;
- isolated realm resources;
- phase timer;
- the latest bounded navigation failure.

The panel is disabled by default and does not change simulation rules.

## Explicitly Deferred

- The rival does not yet run the full plank/stone/food/housing production economy.
- The existing player settlement logistics remain playable, but rival expansion currently uses the milestone Wood/Wyrd economy and visible autonomous gatherers.
- Rivalry state is not yet included in the existing settlement save/load payload.
- Military squads, Rangers, Militia, siege, technology, diplomacy, campaign generation, multiplayer, final art, and final sound design remain later work.

## Validation

`tests/godot_rivalry_smoke.gd` validates isolated resources, paid valid/invalid roads, road and Lumen connectivity, upkeep/deactivation/reactivation, structure ownership, shared AI placement commands, Sovereign incapacitation/respawn, claim rejection/pause/reset, player victory, and an unattended deterministic rival victory.

The existing settlement reconstruction and view smoke suites remain in place and must continue passing.
