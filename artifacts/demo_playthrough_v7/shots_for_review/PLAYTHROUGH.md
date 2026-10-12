# Demo playthrough v7 — Channel Wyrd + caravan aftermath (PR #86)

Recorded on `cursor/channel-wyrd-a689`, stacked on PR #85 (`c36100e`). Official seed **260821**. Hall `(239, 181)`, Shard `(160, 156)` (~84 tiles west), **4** rival seats. Map 320×320, crater R≈110. Fissure at `(218, 175)`.

Harness: `tests/t_demo_playthrough.gd` + `src/GodotClient3D/Scripts/production_demo_player.gd`. The bot issues only public `request_*` commands and advances game time at 8 s/step. Clock below is **game time**.

**Result: THE FISSURE IS SEALED when 12 Stabilized is earned + 120 s defence.** No Seal clock. Survival (`THE REALM HOLDS`) is a milestone toast, not a win. The real **Shard Binding is a later-act hook**.

New this hour:
- **Channel Wyrd** — during the Seal, spend 2 Stabilized to repair one wall/ward segment. 20 s cooldown. `CHANNEL WYRD [C]` button + hotkey. Visible repair VFX. The bot Channels at least once per Seal. Starting the rite still costs 12, then refunds 2 so the first Channel always has stock.
- **Caravan aftermath stays on the map** — Shelter plants persistent tents and extra settlers near town. Fortify keeps palisade segments.
- Opening house is placed before the early road burst. First meaningful build is **0:08** on all four seeds (30–45 s faster than the road-first opening).
- Victory overlay lists caravan, 6-wyrd, Seal, Channel uses, time, and key stats.

The bot still alternates caravan / A-B / wall-overcharge per seed.

Shots (3D, 1920×1080, seed 260821, plus staged Channel / palisade / victory). ChatGPT review set is exactly the 10 files in `shots_for_review/` named in `PROMPT.txt`.

---

## Acceptance (4 seeds)

| Seed | Caravan | 6-wyrd | Seal | Channel | Victory | Longest idle | First build |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **260821** | **20:00 shelter** | **A refine** | **wall** | **1** | **50:36** | **1:12** (72 s) | **0:08** |
| 261306 | **18:08 fortify** | **B secure** | **overcharge** | **1** | **49:16** | **1:20** (80 s) | **0:08** |
| 261597 | **19:12 shelter** | **A refine** | **wall** | **1** | **46:52** | **1:04** (64 s) | **0:08** |
| 260918 | **19:44 fortify** | **B secure** | **overcharge** | **1** | **47:56** | **1:28** (88 s) | **0:08** |

Windows: Seal (victory) 42–55 min. Idle = no new build, choice, Channel, or threat. Longest idle under 90 s on all four seeds. Storehouse 2:11 / 5:32; watchtower still lands before night 1.

---

## Timeline — seed 260821 (minutes 0–51)

### 0:00 — Founding
Opening yard. Quest: **A Settlement Begins**. House is the first plan (roads wait).

### 0:08 — First meaningful build
House completes. First-build clock: **0:08**.

### 5:32 — Plank loop
**Storehouse** completes at **5:32**.

### 7:04 — First night
**RAID — 2 hostiles**, 60 s warning.

### 12:00 — Frontier and the fissure
**THE SHARD LIES W.** Geologist marks `(218, 175)`. Wyrd Harvester starts on the vent.

### 20:00 — Refugee caravan
**REFUGEES SHELTERED — two workers take the hall.** Persistent tents and extra settlers stay near town for the rest of the hour. Fortify would have planted palisade segments.

### 24:00 — Camp still on the map
Tents and settlers are still standing by the hall. The caravan choice is readable later, not only at the offer.

### 36:40 — Choice at 6 Stabilized
**FASTER REFINING** (path A). Path B would have spent 3 Stabilized to ward the vent.

### 48:16 — 12 Stabilized, Seal begins
Bot calls `request_begin_seal`. **SEAL BEGUN — defend 120 seconds.** Store refunds 2 Stabilized for Channel Wyrd.

### 48:32 — Channel Wyrd
**CHANNEL WYRD — a wall segment is repaired.** Button `CHANNEL WYRD [C]`, 20 s cooldown, cyan repair flash on the segment.

### 50:36 — THE FISSURE IS SEALED
Wall path. Ceremony held. Victory overlay lists **Shelter / Faster refine / Reinforce wall / Channel Wyrd 1 / 50:36**. Longest idle: **72 s**.

---

## Other seeds

Same rule: Seal starts the step the store reaches 12. Bot paths alternate. Caravan is always before the first push. Channel is used once during every Seal.

- **261306** — fortify + B + overcharge. Palisades stay up. Victory **49:16**, idle 80 s, first build 0:08.
- **261597** — shelter + A + wall. Victory **46:52**, idle 64 s, first build 0:08.
- **260918** — fortify + B + overcharge. Victory **47:56**, idle 88 s, first build 0:08.
