# Shards & Sovereign — Phase 4 Wyrdfall One Shard Playable Core

**Result: PASS — ready for direct gameplay/fun playtest**

Phase 4 turns the existing GDScript simulation and production 3D presentation into one complete One Shard match: opening, expansion temptation, dusk warning, night consequence, Shard race, Binding commitment, Reckoning, and a result screen that returns to a new seed.

No Phase 3.2 architecture was reopened. Authority remains GDScript. Physical logistics, autonomous workers, physical roads, production 3D, established scale, day/night, depletion, work sockets, and the removed player Sovereign are preserved. Saves moved from schema 7 to schema 8 with an explicit migration.

Engine used: Godot 4.7 stable (`D:\SnS_Isometric\.tools\godot-4.7\Godot_v4.7-stable_win64_console.exe`). Isolated capture user data: `artifacts/phase4/isolated_user`. One-click playtest launch (`Play SnS 3D.bat`) uses Forward+. `project.godot` still defaults the editor/main scene to Compatibility.

Review seed: **260821**. Additional harness seeds: **424242**, **717171**.

## 1. Product-loop implementation

The loop is now a match, not a sandbox:

1. Title screen with short lore.
2. New Realm (random seed by default).
3. Founded settlement under **SURVIVE**.
4. Daytime physical economy and expansion toward the visible Shard beacon.
5. Dusk night-threat forecast from Wyrd Pressure.
6. Night raid from fog, scaled by pressure rather than a day counter.
7. Dawn aftermath toast.
8. Outposts, Wyrd extraction, and rising Pressure.
9. Rival roads/Outposts/Binding race for the same Shard.
10. Explicit **Begin Shard Binding** confirmation.
11. The Reckoning (CRITICAL pressure, existing raid systems).
12. Victory (**SHARD BOUND / REALM SECURED**) or defeat with cause, then **NEW REALM / MAIN MENU** (and **TRY AGAIN** on defeat).

Core module: `src/GodotClient/Scripts/one_shard_wyrdfall.gd`. Wired through `one_shard_simulation.gd`, `one_shard_rivalry.gd`, production HUD, and the 3D world view.

## 2. Wyrd Pressure formula

Centralized, deterministic, 0–100:

```
extraction = min(32, cumulative_wyrd_extracted * 1.75)
outposts   = active_wyrd_outposts * 12
shard      = shard_control * 20          # 0–1, player claim proximity/control
binding    = 42 + progress * 8           # player Binding only; forces CRITICAL
time       = min(10, (day_count - 1) * 1.6)
value      = clamp(sum, 0, 100)
```

Bands (HUD shows the name, not the math):

| Band | Threshold |
| --- | --- |
| QUIET | 0 |
| STIRRING | 20 |
| DANGEROUS | 40 |
| SEVERE | 60 |
| CRITICAL | 80 |

Tooltip lists contributor totals. Population is not an input.

`tests/phase4_wyrdfall_smoke.gd`: unexpanded Day 1 is QUIET; Day 8 with no exploitation stays ≤ 12; extraction + Outposts + Shard control dominate time; Binding reads CRITICAL.

## 3. Pressure sources and feedback

Sources the player can understand:

- cumulative Wyrd extracted from Outposts;
- number of active Wyrd-producing Outposts;
- Shard-region control;
- player Binding / Reckoning;
- a mild day baseline.

Feedback fires on band rises only, with a 22-second cooldown (`PRESSURE_FEEDBACK_SECONDS`), e.g. extraction disturbing the wilds / a new Outpost stirring the Wyrd. Small ticks are aggregated into band changes rather than per-unit spam.

## 4. Lumen role

Lumen remains the existing claim/territory authority. Town Hall and connected Lumen Pillars / Outposts create pockets of realm safety. There is no second territory simulation.

Presentation: claim/Lumen overlay only while placing or selecting Lumen Pillars and Outposts (no permanent giant circles). Night keeps warm occupied settlement lights against cold wilderness.

## 5. Outpost role

Claimant Outposts stay recognizable:

- extend connected roads and Lumen;
- harvest nearby Wyrd when operational;
- push infrastructure toward the Shard;
- are required to Bind.

They are not all-purpose magic buildings. Destroying the Shard Outpost interrupts Binding with a specific message.

## 6. Shard map generation

Every One Shard map still has exactly one `TILE_SHARD`. The focal site is now jittered ±4 tiles around map centre (`one_shard_simulation.gd` `_generate_map`) so seeds are not identical, then given claim pads and cleared corridors from both Town Halls.

World gradient (not a scripted tour):

- near home: starter wood/stone clusters, safer vegetation chance;
- mid wilderness: richer forest, stone ridge, ruined cache, enemy camps;
- impact region: crater, rock fragments, Wyrd sites, rival approach.

## 7. Impact-zone presentation

Built from existing terrain vocabulary, not a cinematic crater asset:

- `_shape_impact_crater()` depresses the floor and raises a rim;
- rock fragments and cleared vegetation in the inner ring;
- 3D Shard beacon: crystal, vertical column, omni light, mist particles, debris;
- `impact_factor(tile)` tints nearby terrain and bends/shrinks trees;
- beacon remains visible above FOW as an objective, without leaking roads, camps, or resources.

Visual review: `09_shard_promise.png`, `16_shard_impact_zone.png`, `19_reckoning.png`.

## 8. Discovery opportunities

`world_features` (save v8) registers:

- central Shard;
- rival realm;
- rich forest;
- stone region;
- ruined cache;
- enemy camps;
- Wyrd springs (from rivalry sites).

Reveal announces a short line once. No generic loot chests.

## 9. Night threat scaling

Dusk copies an authoritative forecast: threat band + likely activity (Light / Moderate / Heavy / Severe / Extreme). First night is forced teachable: **2 Raiders**, Quiet activity, even if pressure has already ticked.

Later nights use `Wyrdfall.wave_plan`: size and roster follow pressure band, with a small HP/damage bump from day count. High-pressure raids are measurably larger than night 1 (`phase4_wyrdfall_smoke`, `phase4_full_run_harness`, rebuild smoke). Spawns skip protected/town tiles and come from fog-adjacent grass.

## 10. Enemy-role changes

Three archetypes on existing characters/equipment (no counter matrix):

| Role | Sim type | Behaviour |
| --- | --- | --- |
| Raider | `raider` | Balanced default attacker |
| Marauder | `skitterer` | Lower HP/damage, **shorter** step interval (faster), prefers exposed workers |
| Brute | `brute` | Higher HP/damage, longer step interval, prefers towers/walls/Outposts/Barracks |

Presentation scales Brutes up. Combat stays autonomous.

## 11. Rival Shard-race behavior

The rival still uses `one_shard_rivalry.gd`. Macro intent is roads, Lumen, Outpost, then Binding — not a raid generator.

`AI_CLAIM_UNLOCK_SECONDS = 2280` (38 minutes) so the rival cannot finish Binding before the 40–50 minute window (`2280 + 120s Binding`). Binding also requires **12 Wyrd**. The AI now gathers that Wyrd after a qualifying Shard-ring Outpost exists, and will not plant the Outpost outside `SHARD_BUILD_RADIUS`.

Player-facing rival line examples: “Another realm seeks the Shard”, “Rival roads pushing toward the Shard”, “Rival Outpost at the Shard”, “Rival Binding N%”. No AI debug planning in the HUD.

`godot_rivalry_smoke.gd`: **PASS**, including the 40–50 minute rival-win window.

## 12. Binding requirements

Centralized in `claim_requirements()`:

- operational Claimant Outpost beside the Shard;
- connected owned road;
- connected active Lumen;
- 12 accumulated Wyrd;
- not contested by an opposing Outpost;
- rival still needs its internal Sovereign in the claim ring (player does not).

Player Binding never auto-starts. HUD shows **BIND THE SHARD** when ready. Inspector/objective copy explains what remains.

## 13. Reckoning implementation

`request_begin_binding()` requires confirmation copy: **Begin Shard Binding / The Wyrd will react violently.**

On player start:

- claim becomes active;
- `reckoning_active`;
- pressure Binding term forces CRITICAL;
- existing `_spawn_wave()` fires immediately, with a second wave at 50% Binding;
- HUD shows `SHARD BINDING — N%`;
- Shard beacon pulses; night ambience drops.

Numbers stay inside the existing raid cap (Reckoning floor 8, roster includes a Brute). No spectacle spawn dump.

## 14. Victory conditions

Binding completes when `binding_progress >= 120s` while requirements still hold (day or night). That is now the rivalry victory, not “hold until dawn”.

Result overlay:

**SHARD BOUND**  
**REALM SECURED**

Stats: days survived, completion time, population / peak, buildings constructed, Wood/Stone/Wheat/Bread produced, Wyrd extracted, highest Pressure band, enemies defeated, settlers lost, territory revealed.

Buttons: **NEW REALM**, **MAIN MENU**. No post-victory sandbox.

## 15. Defeat conditions

- Town Hall / founding core destroyed (existing);
- population reaches 0 after founding;
- rival completes Binding first (“The rival bound the Shard first.”).

Result overlay: **THE REALM HAS FALLEN** plus primary cause. Buttons: **TRY AGAIN**, **NEW REALM**, **MAIN MENU**.

## 16. Run-length measurements

This phase did **not** time a human 35–55 minute playthrough. The clock is designed to land there:

- Day 420s + Night 180s ≈ 10 minutes per cycle;
- first night is reachable inside the first day after founding;
- rival unlock 2280s + 120s Binding = 40 minutes earliest rival win;
- `godot_rivalry_smoke.gd` rival win fell inside 2400–3000 simulated seconds.

A cautious player who never approaches the Shard can still lose the race. A player who Binds earlier can finish sooner. That is the intended range, not a forced timer.

## 17. First-15-minute timeline

Designed sequence, mapped onto current clocks (not a filmed 15-minute human session):

| Window | What the build does |
| --- | --- |
| 0–30s | Title lore + in-engine world. Founded settlement, Shard beacon exists on the map. |
| 0–3 min | First road/production. Workers and carriers are the same sim as always. |
| 3–6 min | FOW edge, starter resource clusters, wilderness features toward the Shard. |
| ~7–10 min | End of Day 1 (420s) → dusk forecast → first night (2 Raiders). |
| ~10–12 min | Dawn toast after the raid. |
| By ~15 min | Objective has moved off pure founding; Wyrd, Pressure, Shard, and rival promise are in the HUD/world. |

If a player spends the whole first day inside the build menu, the loop still ticks; the failure mode is player delay, not missing systems.

## 18. New-player onboarding

Title lore is four dismissible lines. In-match hints are short, once, stored in `user://one_shard_onboarding.json`:

- road / production / Outpost when first relevant;
- dusk / Pressure at first night warning;
- Shard on contact;
- Binding when ready.

HUD shows them as toasts. Build palette starts on **ESSENTIALS** (Road, House, Lumber Camp, Farm, Watchtower, Outpost). Other categories remain available; nothing is quest-gated.

## 19. Economy relevance audit

| Resource / building | Why it exists in the One Shard loop |
| --- | --- |
| Wood / Lumber Camp | Roads, houses, industry, Outpost wood cost. Ignore it and construction stalls. |
| Planks / Sawmill | Towers and higher construction. Optional early, required for serious defence. |
| Stone / Quarry | Towers, walls. Ignore it and you cannot fortify expansion. |
| Wheat / Farm | Food chain input. |
| Bread / Bakery / Town Hall food | Population growth, barracks, night survival. Ignore food and the settlement starves. |
| Wyrd / Outpost harvest / sites | Lumen upkeep and Binding. The power/progress/danger resource. |
| Housing | Population cap and night shelter. |
| Storehouse | Physical storage cap. Full storage is real feedback, not flavour. |
| Watchtower / Wall / Barracks / guards | Autonomous defence of what you built. |
| Lumen Pillar | Claim network toward the Shard. |
| Outpost | Expansion, Wyrd, Binding. |
| Wheat at 0 in opening HUD | Correct starting state, not a dead resource. |

Nothing new was added to create busywork. Planks remain the least urgent opening resource; they matter once towers come online.

## 20. Dominant-build-order findings

Across seeds 260821 / 424242 / 717171 the **same opening verbs** still win the first ten minutes: road out of the Town Hall, lumber, house, food. That is acceptable for a survival economy.

Geography still changes:

- road heading (Shard jitter ±4, resource clusters, camps);
- whether the tempting first Outpost is a Wyrd spring or a safer wood/stone push;
- where towers want to sit on the expansion road;
- when Binding is affordable versus the rival’s 38-minute unlock.

High-impact fix this phase: rival AI no longer plants a non-qualifying Outpost or starves Binding of Wyrd. No further opening-nerf was applied; a perfect unique-every-seed meta is out of scope.

## 21. Multiple-seed findings

`phase4_full_run_harness.gd` **PASS** on 260821, 424242, 717171:

- one Shard each;
- physical road construction (wood is not teleported);
- first night produces a real threat;
- later pressure produces a larger raid;
- player can satisfy Binding and win;
- rival can win;
- save/load keeps seed + `cumulative_wyrd_extracted`.

## 22. Full-run deterministic proof

| Harness | Result |
| --- | --- |
| `tests/phase4_wyrdfall_smoke.gd` | PASS — formula, first vs high-pressure night, Binding, rival win, population defeat, save v8 |
| `tests/phase4_full_run_harness.gd` | PASS — three seeds, economy + nights + Binding + rival + save |
| `tests/godot_rivalry_smoke.gd` | PASS — Binding victory, 40–50 min rival window |
| `tests/godot_rebuild_smoke.gd` | PASS — Phase 3 logistics/combat regressions held |
| `tests/phase4_capture_suite.gd` | PASS count=21 |
| `tests/phase4_performance_sample.gd` | PASS — see §24 |

No fixture economy. Binding success uses the real claim/tick path.

## 23. Save/load proof

`SAVE_VERSION := 8`. New authoritative fields include world features, cumulative Wyrd extracted, peak pressure, reckoning, dusk forecast, dawn summary, night casualty counters, shard contact, and rivalry Binding progress.

v7 saves migrate: rebuild empty `world_features`, keep rivalry/settlement state. Round-trip asserted in the full-run harness and rivalry smoke. Onboarding completion lives in `user://one_shard_onboarding.json` (player profile, not match state).

## 24. Performance

Authority sample, review seed 260821, 80 ticks per phase (`tests/phase4_performance_sample.gd`):

| Phase | avg ms/tick | p95 | max | enemies |
| --- | --- | --- | --- | --- |
| Day | 0.409 | 0.338 | 17.151 | 0 |
| Night (pressure wave) | 0.497 | 0.453 | 17.546 | 4 |
| Reckoning | 2.323 | 2.781 | 20.088 | 10 |

Average ticks stay far under 16 ms. Max spikes are first-tick/path noise, same class as Phase 3. No speculative optimization pass. Captures used Forward+ to match `Play SnS 3D.bat`; this report does not invent a Binding-scene FPS number.

## 25. Screenshot paths

All 1920×1080, production scene, Forward+, isolated user dir.

**First 15 minutes**

- `artifacts/phase4/screenshots/01_title_screen.png`
- `artifacts/phase4/screenshots/02_initial_settlement.png`
- `artifacts/phase4/screenshots/03_first_workers.png`
- `artifacts/phase4/screenshots/04_first_fow_reveal.png`
- `artifacts/phase4/screenshots/05_wyrd_opportunity.png`
- `artifacts/phase4/screenshots/06_dusk.png`
- `artifacts/phase4/screenshots/07_first_night.png`
- `artifacts/phase4/screenshots/08_dawn.png`
- `artifacts/phase4/screenshots/09_shard_promise.png`

**Full run**

- `artifacts/phase4/screenshots/10_opening_settlement.png`
- `artifacts/phase4/screenshots/11_productive_day.png`
- `artifacts/phase4/screenshots/12_outpost_expansion.png`
- `artifacts/phase4/screenshots/13_dangerous_night.png`
- `artifacts/phase4/screenshots/14_dawn_aftermath.png`
- `artifacts/phase4/screenshots/15_rival_realm.png`
- `artifacts/phase4/screenshots/16_shard_impact_zone.png`
- `artifacts/phase4/screenshots/17_contested_shard.png`
- `artifacts/phase4/screenshots/18_binding_start.png`
- `artifacts/phase4/screenshots/19_reckoning.png`
- `artifacts/phase4/screenshots/20_victory_screen.png`
- `artifacts/phase4/screenshots/21_defeat_screen.png`

Log: `artifacts/phase4/logs/phase4_capture_suite.log`.

Visual review (images, not file existence):

- Title is a game menu (lore + NEW REALM / CONTINUE / SETTINGS / QUIT) over the live 3D world; play HUD is hidden.
- Opening settlement reads as a Town Hall in a clearing with SURVIVE + Pressure QUIET.
- FOW is a deep unknown, not tinted readable terrain.
- Dusk HUD shows `NIGHTFALL Threat` + `Likely activity`.
- Night 1: dark wilderness, warm doorway light, `RAID ACTIVE · 2 hostiles`.
- Dawn toast: `DAWN · Night survived · 3 defeated · 1 lost · 1 damaged`.
- Shard promise/impact: crater, cyan crystal, vertical beacon, objective **SECURE THE SHARD**.
- Later night: Night 4, Pressure STIRRING, 4 hostiles (larger than night 1).
- Binding/Reckoning: **SHARD BINDING — 0%**, Pressure SEVERE, 8 hostiles, pulsing beacon.
- Victory: SHARD BOUND / REALM SECURED + stats + NEW REALM / MAIN MENU (no TRY AGAIN).
- Defeat: THE REALM HAS FALLEN, “The rival bound the Shard first.”, TRY AGAIN / NEW REALM / MAIN MENU.

Several captures **pose** a paused Day 1 settlement and jump the camera (same method as Phase 3.2). Instant victory/defeat stats are zeros because `_finish_run` was invoked on a fresh realm. Economy, rival win window, and Binding success are proven by the harnesses, not by those two result shots.

## 26. Known weaknesses

- **Productive-day capture** is still the opening clearing, not a developed sawmill/bakery yard. Watching the settlement work is true in the live sim; that screenshot does not prove it.
- **Wyrd-opportunity capture** is a small revealed patch; the spring does not always read as cyan-violet Wyrd at a glance. The Shard beacon carries the fantasy harder than the springs.
- **Rival capture** uses the same Town Hall kit. It is easy to misread as the player home. Rival pressure is clearer from HUD lines, roads in play, and the defeat reason.
- **Raid silhouettes** are often at the FOW edge; the toast is the reliable tell in captures.
- **Title background** is the live map, often forest-forward, not a composed Shard hero shot.
- **Wheat starts at 0**; newcomers may not see why Farms exist until the first hunger beat.
- **Opening build order** is still obviously lumber/roads/food. Seeds change *where*, not *whether*.
- **No human 35–55 minute timing** this phase. Clock design and the rival-window test stand in.
- **Play SnS 3D.bat uses Forward+**; editor default remains Compatibility. Visuals can differ slightly between those paths.
- Godot `--script` teardown still leaks a few objects. Known harness noise.
- Debug/review controls (hidden NewReviewSeed, Legacy 2D, F3) remain for tests. Default play does not show them.

## 27. Engagement heuristic review

| Heuristic | Verdict |
| --- | --- |
| Autonomy | Yes. Expand/extract versus turtle is a real choice because Pressure and the rival race punish both extremes. |
| Competence | Mostly. Dawn toasts, stall messages, Binding interrupt copy, and defeat reasons explain failure. Some logistics stalls still need the inspector. |
| Clear goals | Yes. Compact objective: SURVIVE → REACH → SECURE → BIND. |
| Feedback | Yes for roads, harvest, night, Binding, Pressure bands. Weaker for Wyrd springs and rival identity. |
| Challenge | Yes. First night teaches; later nights scale with exploitation; rival can win; population 0 and Town Hall loss remain. Not an arbitrary day-counter wall. |
| Curiosity | Yes at the Shard beacon and wilderness features. FOW click-for-loot is absent. |
| Immersion | Lumen/Wyrd/Shard fiction matches the systems. HUD is compact, not a debug panel. |
| Completion | Yes. Binding or rival Binding or collapse ends the run and offers another seed. |

Weakest heuristic in captures: **watching a busy mid-game settlement**. The sim has the activity; the screenshot set under-represents it.

## 28. Exact launch instructions

**Playtest (no PowerShell knowledge required)**

1. Double-click `Play SnS 3D.bat` at the repo root.
2. Title: **NEW REALM**.
3. Leave Seed blank for random, or type `260821` for the review seed.
4. **BEGIN**.
5. Play until SHARD BOUND or THE REALM HAS FALLEN.
6. **NEW REALM** or **MAIN MENU**. Defeat also offers **TRY AGAIN**.

Continue uses the normal save if one exists. Settings expose visual quality only.

Developer equivalent:

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\launch_client.ps1 -Presentation 3d -Quality recommended
```

Headless proof (not the playtest path):

```
.tools\godot-4.7\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/phase4_wyrdfall_smoke.gd
.tools\godot-4.7\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/phase4_full_run_harness.gd
.tools\godot-4.7\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/godot_rivalry_smoke.gd
```

Default play has no fixture, no console, no debug HUD.

## Final acceptance questions

| Question | Answer |
| --- | --- |
| Premise | **Yes.** Title lore + Shard beacon + SURVIVE/REACH/SECURE/BIND. |
| Activity | **Yes** in the live sim. Capture set is weaker on mid-game bustle. |
| Purpose | **Yes.** Macro objective is always on the loop bar. |
| Autonomy | **Yes.** Wyrd/Outposts/Shard push versus conservative play. |
| Consequence | **Yes.** Pressure, not the day counter, dominates later nights. |
| Curiosity | **Yes**, led by the beacon and named wilderness features. |
| Rhythm | **Yes.** Dusk forecast, night lighting/raid, dawn toast. |
| Strategy | **Yes.** Roads, Lumen, towers, and Outpost placement still feed the same physical sim. |
| Rivalry | **Yes.** Race for Binding, not unit micro. Player has no Sovereign. |
| Climax | **Yes.** Confirmed Binding, Reckoning wave, progress percent. |
| Completion | **Yes.** Win and lose screens with cause and replay. |
| Replay | **Yes.** New seed, jittered Shard, different routes. Not a massive event table. |
| First impression | **Yes enough.** It reads as Shards & Sovereign, not an engineering boot screen. Remaining prototype tells: low-poly kit, some HUD chrome, Forward+/Compatibility split. |

## Final result

**PASS — ready for direct gameplay/fun playtest**
