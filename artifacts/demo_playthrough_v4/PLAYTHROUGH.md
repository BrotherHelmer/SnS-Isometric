# Demo playthrough v4 — Seal the Fissure (PR #83)

Recorded on `cursor/seal-fissure-a689`, stacked on `cursor/crater-war-a689` (`d19d3c7`). Official seed **260821**. Hall `(239, 181)`, Shard `(160, 156)` (~84 tiles west), **4** rival seats. Map 320×320, crater R≈110. Fissure at `(218, 175)`.

Harness: `tests/t_demo_playthrough.gd` + `src/GodotClient3D/Scripts/production_demo_player.gd`. The bot issues only public `request_*` commands and advances game time at 8 s/step. Clock below is **game time**.

**Result: THE FISSURE IS SEALED when 12 Stabilized is earned + 120 s defence.** No Seal clock. Survival (`THE REALM HOLDS`) is a milestone toast, not a win. The real **Shard Binding is a later act** (hook only).

At 6 Stabilized the player chooses a Wyrd pact:
- **A / refine** — the kiln runs hotter (same 3-raw recipe, faster ticks).
- **B / secure** — invest 3 Stabilized; the vent harvests faster and the rival raid loses its teeth.

The bot alternates A / B / A / B across the four seeds. The rival reveals on a seeded time in 14:00–20:00, pushes after the first harvest, and raids after the first Stabilized. No +180/+360 clocks.

Shots (3D, 1920×1080, seed 260821). ChatGPT review set is exactly the 10 files in `shots_for_review/` named in `PROMPT.txt`.

---

## Acceptance (4 seeds)

| Seed | Reveal | Choice | 12 Stabilized | Seal start | Victory | Longest idle |
| --- | --- | --- | --- | --- | --- | --- |
| **260821** | 19:27 | **A refine** | **43:12** | 43:12 | **45:12** | **1:04** (64 s) |
| 261306 | 19:08 | **B secure** | **43:20** | 43:20 | **45:20** | **1:42** (101.5 s) |
| 261597 | 19:35 | **A refine** | **42:24** | 42:24 | **44:24** | **1:52** (112 s) |
| 260918 | 16:02 | **B secure** | **51:28** | 51:28 | **53:28** | **1:28** (88 s) |

Windows: Seal (victory) 42–55 min. Idle = no new build, choice, or threat. No stretch longer than 3 minutes.

---

## Timeline — seed 260821 (minutes 0–45)

### 0:00 — Founding
Opening yard. Quest: **A Settlement Begins**.

### 5:21 — Plank loop
**Storehouse** completes at **5:21**.

### 7:04 — First night
**RAID — 2 hostiles**, 60 s warning.

### 12:00 — Frontier and the fissure
**THE SHARD LIES W.** Geologist marks `(218, 175)`. Wyrd Harvester starts on the vent.

### 19:27 — Rival reveal (seeded)
Rival Claimant Outpost sighted. Not a fixed 18:00 beat.

### 20:48 — Capture
**CAPTURED — +8 Wood, +4 Stone, +2 Wyrd.** No Stabilized dump.

### 22:32 — First harvest, then a push
The harvester drinks. **RIVAL PUSH** plants another Outpost on the fissure.

### 24:24 — First Stabilized, then a raid
The refiner yields. **HARVESTER RAID** strikes the vent.

### 31:44 — Choice at 6 Stabilized
**FASTER REFINING** (path A). Path B would have spent 3 Stabilized to ward the vent.

### 43:12 — 12 Stabilized, Seal begins
Bot calls `request_begin_seal`. **SEAL BEGUN — defend 120 seconds.** Camera holds the fissure. A cyan ceremony column rises on the vent.

### 45:12 — THE FISSURE IS SEALED
Ceremony held. Overlay: **THE FISSURE IS SEALED — the ceremony held.** Longest idle: **64 s**.

---

## Other seeds

Same rule: Seal starts the step the store reaches 12. Bot path alternates.

### 261306 — path B
Hall `(238, 143)`. Reveal 19:08. Choice **secure** at 34:32. **12 Stabilized 43:20.** Seal **45:20**. Idle **1:42**. Fissure `(216, 149)`.

### 261597 — path A
Hall `(241, 182)`. Reveal 19:35. Choice **refine** at 34:00. **12 Stabilized 42:24.** Seal **44:24**. Idle **1:52**. Fissure `(220, 178)`.

### 260918 — path B
Hall `(76, 188)`, crater **NE**. Reveal 16:02. Choice **secure** at 43:28. **12 Stabilized 51:28.** Seal **53:28**. Idle **1:28**. Fissure `(100, 181)`.

---

## Gates (this pass)

| Gate | Result |
| --- | --- |
| 4-seed `--accept` Seal | **PASS** — 45:12 / 45:20 / 44:24 / 53:28 |
| Longest idle ≤ 3 min | **PASS** — 1:04 / 1:42 / 1:52 / 1:28 |
| t_crater_war | PASS (Seal copy; choice A/B; reactive rival; later-act hook) |
| t_demo_balance | PASS (hold is a milestone) |
| export audit | **MISSING 0** |

## What still fails / is dull

- Rival reveal is seeded, not a story beat with a scout.
- Harvester / Refiner now have their own simple models; thumbs still reuse Lumen / Storehouse.
- The real Shard Binding is a later-act hook only.

---

## CSVs

- `playthrough.csv` — seed 260821
- `playthrough_<seed>.csv` — the other three
- `dpm_<seed>.csv` — playtest log
- `notes.json` / `notes_<seed>.json` — includes `choice`, `rival_reveal_at`, `first_12_at`, `ritual_at`, `longest_idle`
