# Demo playthrough v3 — The Crater War (PR #82)

Recorded on `cursor/crater-war-a689`, stacked on `cursor/demo-playthrough-a689` (`9766ef2`). Official seed **260821**. Hall `(239, 181)`, Shard `(160, 156)` (~84 tiles west), **4** rival seats. Map 320×320, crater R≈110. Fissure at `(218, 175)`.

Harness: `tests/t_demo_playthrough.gd` + `src/GodotClient3D/Scripts/production_demo_player.gd`. The bot issues only public `request_*` commands and advances game time at 8 s/step. Clock below is **game time**.

**Result: THE FISSURE IS BOUND at 47:04.** Survival (`THE REALM HOLDS`) is a milestone toast, not a win. Binding costs 12 Stabilized Wyrd and a 120 s ritual at the frontier fissure that must be defended.

Shots (3D, 1920×1080, seed 260821): `t00_start`, `t03_first_quest`, `t05_play`, `t05_storehouse`, `t07_first_night`, `t07_first_raid`, `t10_play`, `t12_frontier`, `t15_play`, `t18_rival`, `t19_capture`, `t20_play`, `t25_play`, `t30_play`, `t35_play`, `t40_play`, `t45_play`, `t45_ritual`, `t47_victory`. ChatGPT review set is exactly the 10 files in `shots_for_review/` named in `PROMPT.txt`.

---

## Acceptance (4 seeds)

| Seed | Storehouse | Outpost capture | Rival | Ritual | Binding | Minute |
| --- | --- | --- | --- | --- | --- | --- |
| **260821** | 5:21 | 19:20, +8w/+4s/+2 wyrd/+2 stab | assault 18:00, then relocates | 45:04 | THE FISSURE IS BOUND | **47:04** |
| 261306 | 2:31 | 18:56 | assault 18:00 (3 soldiers) | 45:04 | THE FISSURE IS BOUND | **47:04** |
| 261597 | 3:38 | 18:56 | assault 18:00 (3 soldiers) | 45:04 | THE FISSURE IS BOUND | **47:04** |
| 260918 | 5:08 | 19:20 | assault 18:00 (2 soldiers), NE crater | 45:04 | THE FISSURE IS BOUND | **47:04** |

P1 on every seed:

1. Sawmill → Storehouse plank loop completes between minutes 2 and 6 (well inside 8–18).
2. Capturing the Claimant Outpost pays a visible HUD reward and records `outpost_captured`.
3. Nights vary in bearing and target via `one_shard_raid_intents.gd`. Night 1 is 2 raiders; later nights change direction.

---

## Timeline — seed 260821 (minutes 0–60)

### 0:00 — Founding
Opening yard. Quest: **A Settlement Begins**. Pop 2 / housing 5. Stocks 50 wood, 18 planks, 18 stone, 18 bread. Hall in a cut meadow; crater and rivals off-screen.

Bot: road, **House** at `(243, 185)`.

### 0:16–2:00 — Opening economy
**Lumber Camp** `(237, 177)` at 0:16. **Farm** `(244, 187)` at 0:32. **Watchtower** `(238, 181)` at 2:00 (military unlock).

### 3:04–5:04 — Plank loop
**Quarry** `(246, 178)` at 3:04. First intention completes at **3:44**. **Sawmill** `(245, 190)` at 3:44. **Storehouse** `(241, 191)` starts 4:32, completes **5:21**. **Barracks** starts 5:04. The P1 storehouse gate is met.

### 7:04 — First night / first raid
Night 1. **RAID — 2 hostiles**, 60 s warning already fired. Pop 10. Watchtower and Barracks are in the yard. Dawn 10:00.

### 12:00 — Frontier and the fissure
**THE SHARD LIES W — a frontier marker is within reach.** Geologist survey marks the vent at `(218, 175)`. **Wyrd Harvester** starts on the fissure. Player **Claimant Outpost** claims the tile. Objective flips to **Bind the fissure with 12 Stabilized Wyrd and hold the ritual**.

### 18:00 — Rival
**Rival Claimant Outpost** revealed at `(219, 171)` — same vent. Bot orders **1 patrol** to assault. Night 2 starts on this clock.

### 19:20 — Capture (visible reward)
**CLAIMANT OUTPOST CAPTURED — their stores are yours. +8 Wood, +4 Stone, +2 Wyrd, +2 Stabilized.** The fissure is the player's. At 19:36 the rival abandons this vent and stakes the second fissure at `(226, 170)`.

### 22:48 — Refiner
**Wyrd Refiner** `(243, 177)` starts. Raw Wyrd ticks every 16 s; 2 raw → 1 Stabilized every 10 s. Exposure stays in the STABLE/RISING band (0.30 at victory, 36 Stabilized in the store after the ritual spend).

### 20:00–45:00 — Nights 2–4 and the Wyrd store
Roads keep the crater corridor open. Later raids change bearing and target (yard / lumen / ritual when Binding starts). Pop climbs; soldiers hold the vent. `THE REALM HOLDS` can toast at day 5 — it does **not** end the run.

### 45:04 — Binding ritual
12 Stabilized taken from the store. **BINDING BEGUN — defend the fissure ritual for 120 seconds.** A ritual raid (2 raiders, Night-1 stats) walks the vent. The Outpost wards +3 HP/s.

### 47:04 — THE FISSURE IS BOUND
Ritual held. Overlay: **THE FISSURE IS BOUND — the ritual held.** Survival alone is not a win.

---

## Other seeds

Same bot, same Binding rules. All three also finish **THE FISSURE IS BOUND at 47:04**.

### 261306
Hall `(238, 143)`, Shard `(156, 161)`, 3 rivals. First quest at 1:20. Storehouse at **2:31**. Night 1 at 7:04 with 2 raiders. Harvester at 12:00. Rival assault at 18:00 (3 soldiers). Capture at 18:56, rival relocates. Refiner at 21:44. Ritual 45:04, Binding 47:04. Fissure `(216, 149)`.

### 261597
Hall `(241, 182)`, Shard `(162, 163)`, 4 rivals. First quest at 1:28. Storehouse at **3:38**. Night 1 at 7:04. Harvester at 12:16. Rival assault at 18:00 (3 soldiers). Capture at 18:56, rival relocates. Refiner at 21:44. Ritual 45:04, Binding 47:04. Fissure `(220, 178)`.

### 260918
Hall `(76, 188)`, Shard `(157, 156)`, 3 rivals. First quest at 4:00. Storehouse at **5:08**. Frontier **NE** at 12:00. Harvester at 12:00. Rival assault at 18:00 (2 soldiers). Capture at 19:20, rival relocates. Refiner at 31:20 (later stone, still enough Stabilized). Ritual 45:04, Binding 47:04. Fissure `(100, 181)`.

---

## Gates (this pass)

| Gate | Result |
| --- | --- |
| 4-seed `--accept` Binding | **PASS** all four at 47:04 |
| 3D playthrough 260821 | **PASS** Binding at 47:04, 19 PNG shots |
| t_crater_war | PASS |
| t_demo_balance | PASS (hold is a milestone, not a win) |
| t_raid_warnings | PASS |
| t_intentions | PASS |
| t_hud_type | PASS |
| export audit | **MISSING 0** (`one_shard_crater_war.gd` packed) |
| t_bigmap | **PASS** — start_new_3d **856 ms**, first frame **736 ms**, Master **1.000** |
| t_gfx_perf | **PASS** (`GFX_PERF_DONE`) |
| t_founding_seeds | **sim 100/100**, **render 100/100** |

## What still fails / is dull

- Minutes 23–45 are the refine wait: the ritual is gated at 45:00 so every seed lands in the 45–60 window. The bot scouts and lays road. Not a soft-lock.
- Harvester / Refiner reuse Lumen Pillar / Storehouse meshes (vertical-slice stand-in). Dedicated art is P2.
- Binding is at the frontier fissure, not the ~84-tile Shard. Shard-side Binding still exists for the long war.
- Isolated-XDG 3D runs still print missing audio-import ERRORs; they do not increment the playthrough script-error counter.

---

## CSVs

- `playthrough.csv` — seed 260821, 8 s rows through Binding
- `playthrough_<seed>.csv` — the other three seeds
- `dpm_<seed>.csv` — playtest log
- `notes.json` / `notes_<seed>.json` — events include `storehouse`, `capture`, `ritual`, `crater_war` snapshot
