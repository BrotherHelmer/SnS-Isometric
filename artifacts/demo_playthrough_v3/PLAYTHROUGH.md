# Demo playthrough v3 — The Crater War (PR #82)

Recorded on `cursor/crater-war-a689`, stacked on `cursor/demo-playthrough-a689` (`9766ef2`). Official seed **260821**. Hall `(239, 181)`, Shard `(160, 156)` (~84 tiles west), **4** rival seats. Map 320×320, crater R≈110. Fissure at `(218, 175)`.

Harness: `tests/t_demo_playthrough.gd` + `src/GodotClient3D/Scripts/production_demo_player.gd`. The bot issues only public `request_*` commands and advances game time at 8 s/step. Clock below is **game time**.

**Result: THE FISSURE IS BOUND when 12 Stabilized is earned + 120 s defence.** No Binding clock. Survival (`THE REALM HOLDS`) is a milestone toast, not a win. Pacing is economy: harvest 1 raw / 32 s (half if the corridor is unsecured), refine 3→1 / 22 s, capture grants wood/stone/+2 Wyrd and **0 Stabilized**. Exposure burns only above a refine reserve. The rival second-pushes the fissure and raids the harvester.

Shots (3D, 1920×1080, seed 260821). ChatGPT review set is exactly the 10 files in `shots_for_review/` named in `PROMPT.txt`.

---

## Acceptance (4 seeds)

| Seed | Storehouse | 12 Stabilized | Ritual start | Binding | Longest idle |
| --- | --- | --- | --- | --- | --- |
| **260821** | 5:21 | **42:24** | 42:24 | **44:24** | **1:45** (104.7 s) |
| 261306 | 2:31 | **44:32** | 44:32 | **46:32** | **2:27** (147.3 s) |
| 261597 | 3:38 | **44:40** | 44:40 | **46:40** | **2:28** (148.3 s) |
| 260918 | 5:08 | **50:24** | 50:24 | **52:24** | **1:28** (88 s) |

Windows: 12 Stabilized 40–52 min, Binding 42–55 min. Idle = no new build, choice, or threat; a living rival Outpost and an active assault count as play. No stretch longer than 3 minutes.

Capture pays +8 wood / +4 stone / +2 Wyrd / **0 Stabilized**. Rival reveal stays a demo beat at 18:00 (`DEMO_RIVAL_SECONDS`); the bot assaults as soon as that Outpost is visible. The rival returns: second push ~+180 s, harvester raid ~+360 s, further contests every ~150 s.

---

## Timeline — seed 260821 (minutes 0–45)

### 0:00 — Founding
Opening yard. Quest: **A Settlement Begins**. Pop 2 / housing 5.

### 0:16–5:21 — Plank loop
Lumber, farm, watchtower, quarry, sawmill. **Storehouse** completes at **5:21**. Barracks starts 5:04.

### 7:04 — First night
**RAID — 2 hostiles**, 60 s warning. Dawn 10:00.

### 12:00 — Frontier and the fissure
**THE SHARD LIES W.** Geologist marks `(218, 175)`. Wyrd Harvester starts on the vent. Corridor Outpost is the harvest-rate gate.

### 18:00 — Rival (demo beat)
Rival Claimant Outpost revealed at `(219, 171)`. Bot assaults immediately.

### 19:20 — Capture
**CAPTURED — +8 Wood, +4 Stone, +2 Wyrd.** No Stabilized dump. Rival will return.

### 22:00 — Exposure choice
Raw Wyrd exposure rises. Raise a Lumen on the harvester or refine the surplus. Burn only fires above reserve + refine input so the stockpile cannot starve.

### 22:16 — Rival second push
**RIVAL PUSH — they raise another Outpost on the fissure.**

### 25:20 — Harvester raid
**HARVESTER RAID — hostiles from the south mean the Wyrd vent.** Size 1 against a 220 HP harvester with a raid ward. Later contests at 26:08, 39:52, 42:24.

### 42:24 — 12 Stabilized, ritual begins
CSV first hits 12 at **2544 s**. Bot calls `request_begin_binding` on that step. **BINDING BEGUN — defend 120 seconds.**

### 44:24 — THE FISSURE IS BOUND
Ritual held. Overlay: **THE FISSURE IS BOUND — the ritual held.** Longest idle stretch: **104.7 s** (40:32–42:17, corridor walk while the last Stabilized ticks).

---

## Other seeds

Same rule: ritual starts the step the store reaches 12. Same rival second push + harvester raid.

### 261306
Hall `(238, 143)`. Storehouse 2:31. Capture 18:56. Exposure 21:12. Second push 21:52. Harvester raid 24:56. **12 Stabilized 44:32.** Binding **46:32**. Idle **2:27**. Fissure `(216, 149)`.

### 261597
Hall `(241, 182)`. Storehouse 3:38. Capture 18:56. Exposure 21:28. Second push 21:52. Harvester raid 24:56. **12 Stabilized 44:40.** Binding **46:40**. Idle **2:28**. Fissure `(220, 178)`.

### 260918
Hall `(76, 188)`, crater **NE**. Storehouse 5:08. Capture 19:20. Second push 22:16. Exposure 24:24. Harvester raid 25:20. Refiner forced by minute 25 and unstuck if no worker can reach it. **12 Stabilized 50:24.** Binding **52:24**. Idle **1:28**. Fissure `(100, 181)`.

---

## Gates (this pass)

| Gate | Result |
| --- | --- |
| 4-seed `--accept` Binding | **PASS** — 44:24 / 46:32 / 46:40 / 52:24 |
| 12 Stabilized window 40–52 | **PASS** — 42:24 / 44:32 / 44:40 / 50:24 |
| Longest idle ≤ 3 min | **PASS** — 1:45 / 2:27 / 2:28 / 1:28 |
| t_crater_war | PASS (paced rates; 0 capture Stabilized; second push + harvester raid) |
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
- `notes.json` / `notes_<seed>.json` — includes `first_12_at`, `ritual_at`, `second_push_at`, `harvester_raid_at`, `longest_idle`
