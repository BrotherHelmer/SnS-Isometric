# Shards & Sovereign — Phase 3 playtest guide

This is an internal production-3D playtest candidate. It uses the real economy, population, rivalry, raid, combat, and version-7 save systems. The older 2D client remains available as a safety rail.

## Launch

1. Double-click `Play SnS 3D.bat` in the repository root.
2. Leave the seed blank for a generated settlement, or enter `260821` for the known-good review seed.
3. Leave **Visual quality** on **Recommended** for the intended presentation. Use **Scalable Low** if the developed settlement feels slow.
4. Choose **New Settlement**. Choose **Load Settlement** to continue the most recent save.

No console command, fixture, or injected economy is required.

## Essential controls

| Action | Control |
| --- | --- |
| Select / place | Left mouse button |
| Cancel placement | Escape |
| Rotate placement | R |
| Pan camera | Arrow keys or middle-mouse drag |
| Zoom | Mouse wheel |
| Pause / resume | HUD button |
| Game speed | `1x` / `2x` / `4x` HUD button |

Workers and soldiers are autonomous. Roads, jobs, building placement, and defence decisions are how the player influences them. Wyrd harvesting and claiming are handled by connected Outposts and Lumen rather than a directly controlled hero.

## Suggested first 10 minutes

This is a useful route, not a required solution:

1. Select the Town Hall and inspect starting resources, population, and housing.
2. Extend the road from the existing network toward open, valid ground.
3. Build a House next to a connected road.
4. Build a Lumber Camp where it can reach trees and the road network.
5. Add a Quarry and Sawmill when Stone and Plank supply become the bottleneck.
6. Build a Farm, then a Bakery, and watch Wheat become Bread and carriers move it.
7. Add a Storehouse if storage or delivery distance becomes awkward.
8. Build a Watchtower on the connected network; add a Barracks and train a soldier to staff it.
9. Let the first dusk and night run. Watch workers travel to shelter and occupied houses light up.
10. Scout the rival side, inspect claims, and observe how the settlement responds when a raid arrives.

Placement feedback explains the relevant failure when a plan is invalid. Selecting a building shows staffing, inventories, current production state, access/construction problems, occupancy, and damage.

The review seed is `260821`. The first night begins at about seven minutes at 1x speed, but raid size is simulation-driven and the first night can be quiet. A more substantial rival or raid interaction should normally be visible by the second or third night (roughly 17–27 minutes at uninterrupted 1x); higher speed shortens the wait. Do not treat that range as a guaranteed scripted timestamp.

## Things to evaluate

- Is placement intuitive, and is invalid-placement feedback useful?
- Do roads visibly matter to access, workers, and logistics?
- Do you understand why a worker or building is active, idle, or blocked?
- Can you diagnose missing resources, storage pressure, or missing staff?
- Does the real settlement feel alive during work, meals, shelter, and morning return?
- Is food and housing pressure understandable rather than surprising?
- Are Farm, Bakery, Storehouse, House, and military structures recognizable at normal zoom?
- Is the camera comfortable at close, normal, and strategic zoom?
- Can you distinguish civilians, friendly military, rivals, and raiders?
- Do tower fire, projectiles, melee, damage, death, and retreat explain the battle?
- Are raids readable and fair enough to plan around?
- Is any part of the 20–30 minute loop boring, confusing, or frustrating?
- After Save, quit and relaunch: does Load restore what you expected?

## Saving useful feedback

Use **Copy Debug Info** in the HUD before reporting a problem, then paste the result with:

- what you expected;
- what happened;
- what you were doing immediately beforehand;
- a screenshot if the problem is visual;
- whether saving and loading reproduces it.

The copied block includes the build, seed, day/time, population, hungry count, entity counts, presentation metrics, and save schema.

On Windows, playtest evidence is under:

`%APPDATA%\Godot\app_userdata\Shard & Sovereign\`

Useful files are:

- `one_shard_save.json` — the current version-7 save;
- `one_shard_run_journal.jsonl` — timestamped-by-tick/day diagnostic events from a diagnostics-enabled run;
- `one_shard_last_run.json` — the last diagnostic state and recent journal;
- `logs\godot.log` — the engine log when file logging is available.

Copy these files before starting another reproduction if they need to be preserved. A new run may replace the current journal or save.

## Known issues

- Fog authority currently distinguishes revealed territory from unknown territory. It does not provide a separate “explored but not currently visible” state, so the 3D client does not invent one.
- At the deliberate 200-active-entity mixed combat stress load, the RTX 4070 averaged about 69 FPS on Recommended, but p95 frames were about 43 ms. Ordinary 100-civilian play is materially smoother.
- Scalable Low reduces shadows, foliage, water detail, and VFX, but at extreme live-agent scale the simulation is the larger cost, so the gain can be modest.
- The functional 1080p HUD is intentionally dense and is not final release artwork.
- Night is kept readable for strategy play and may feel brighter than a cinematic night scene.
- Dead units play a short death presentation and are removed; persistent corpses are not saved.
- World audio has semantic ambience, work, construction, warning, and combat cues, but is not a final positional-audio mix.
- The separate legacy 2D synthetic mouse harness still has its three documented synthetic-click failures. New production-3D interaction coverage passes, and the issue is not a blocker for this playtest path.
