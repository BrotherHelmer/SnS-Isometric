# Demo playthrough v3 — The Crater War (PR #82)

Recorded on `cursor/crater-war-a689`, stacked on `cursor/demo-playthrough-a689` (`9766ef2`). Official seed **260821**. Hall `(239, 181)`, Shard `(160, 156)` (~84 tiles west), **4** rival seats. Map 320×320, crater R≈110. Fissure at `(218, 175)`.

Harness: `tests/t_demo_playthrough.gd` + `src/GodotClient3D/Scripts/production_demo_player.gd`. The bot issues only public `request_*` commands and advances game time at 8 s/step. Clock below is **game time**.

**Result: THE FISSURE IS BOUND when 12 Stabilized is earned + 120 s defence.** The 45:00 clock unlock is gone. Survival (`THE REALM HOLDS`) is a milestone toast, not a win.

Shots (3D, 1920×1080, seed 260821): `t00_start`, `t03_first_quest`, `t05_play`, `t05_storehouse`, `t07_first_night`, `t07_first_raid`, `t10_play`, `t12_frontier`, `t15_play`, `t18_rival`, `t19_capture`, `t20_play`, `t25_play`, `t26_ritual`, `t28_victory`. ChatGPT review set is exactly the 10 files in `shots_for_review/` named in `PROMPT.txt`.

---

## Acceptance (4 seeds)

| Seed | Storehouse | 12 Stabilized (CSV) | Ritual start | Binding |
| --- | --- | --- | --- | --- |
| **260821** | 5:21 | **26:48** | 26:48 | **28:48** |
| 261306 | 2:31 | **28:00** | 28:00 | **30:00** |
| 261597 | 3:38 | **28:00** | 28:00 | **30:00** |
| 260918 | 5:08 | **33:44** | 33:44 | **35:44** |

Capture still pays +8 wood / +4 stone / +2 Wyrd / +2 Stabilized. Rival reveal stays a demo beat at 18:00 (`DEMO_RIVAL_SECONDS`); the bot assaults as soon as that Outpost is visible.

---

## Timeline — seed 260821 (minutes 0–30)

### 0:00 — Founding
Opening yard. Quest: **A Settlement Begins**. Pop 2 / housing 5.

### 0:16–5:21 — Plank loop
Lumber, farm, watchtower, quarry, sawmill. **Storehouse** completes at **5:21**. Barracks starts 5:04.

### 7:04 — First night
**RAID — 2 hostiles**, 60 s warning. Dawn 10:00.

### 12:00 — Frontier and the fissure
**THE SHARD LIES W.** Geologist marks `(218, 175)`. Wyrd Harvester starts on the vent.

### 18:00 — Rival (demo beat)
Rival Claimant Outpost revealed at `(219, 171)`. Bot assaults immediately.

### 19:20 — Capture
**CAPTURED — +8 Wood, +4 Stone, +2 Wyrd, +2 Stabilized.** Rival relocates at 19:36.

### 22:48 — Refiner
Wyrd Refiner starts. 2 raw → 1 Stabilized / 10 s.

### 26:48 — 12 Stabilized, ritual begins
CSV first hits 12 at **1608 s**. Bot calls `request_begin_binding` on that step. **BINDING BEGUN — defend 120 seconds.**

### 28:48 — THE FISSURE IS BOUND
Ritual held. Overlay: **THE FISSURE IS BOUND — the ritual held.**

---

## Other seeds

Same rule: ritual starts the step the store reaches 12.

### 261306
Hall `(238, 143)`. Storehouse 2:31. Capture 18:56. **12 Stabilized 28:00.** Binding **30:00**. Fissure `(216, 149)`.

### 261597
Hall `(241, 182)`. Storehouse 3:38. Capture 18:56. **12 Stabilized 28:00.** Binding **30:00**. Fissure `(220, 178)`.

### 260918
Hall `(76, 188)`, crater **NE**. Storehouse 5:08. Capture 19:20. Refiner later (31:20). **12 Stabilized 33:44.** Binding **35:44**. Fissure `(100, 181)`.

---

## Gates (this pass)

| Gate | Result |
| --- | --- |
| 4-seed `--accept` Binding | **PASS** — 28:48 / 30:00 / 30:00 / 35:44 |
| t_crater_war | PASS (ready at 12 Stabilized; locked at 11) |
| t_demo_balance | PASS (hold is a milestone) |
| export audit | **MISSING 0** |
| t_bigmap | **PASS** — first frame **736 ms**, Master **1.000** |
| t_founding_seeds | **sim 100/100**, **render 100/100** |

## What still fails / is dull

- Rival *reveal* is still a demo clock at 18:00. Assault follows that beat; Binding no longer does.
- Harvester / Refiner reuse Lumen / Storehouse meshes.
- Binding is at the frontier fissure, not the ~84-tile Shard.

---

## CSVs

- `playthrough.csv` — seed 260821
- `playthrough_<seed>.csv` — the other three
- `dpm_<seed>.csv` — playtest log
- `notes.json` / `notes_<seed>.json` — includes `stabilized_12` and `crater_war.first_12_at`
