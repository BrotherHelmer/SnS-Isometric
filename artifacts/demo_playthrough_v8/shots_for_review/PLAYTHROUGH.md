# Demo playthrough v8 — idle settlers + honest Channel Wyrd (PR #87)

Recorded on `cursor/idle-settlers-a689`, stacked on PR #86 (`8c09d23`). Official seed **260821**. Hall `(239, 181)`, Shard `(160, 156)` (~84 tiles west), **4** rival seats. Map 320×320, crater R≈110. Fissure at `(218, 175)`.

Harness: `tests/t_demo_playthrough.gd` + `src/GodotClient3D/Scripts/production_demo_player.gd`. The bot issues only public `request_*` commands and advances game time at 8 s/step. Clock below is **game time**.

**Result: THE FISSURE IS SEALED when 12 Stabilized is earned + 120 s defence.** No Seal clock. Survival (`THE REALM HOLDS`) is a milestone toast, not a win. The real **Shard Binding is a later-act hook**.

New this hour:
- **Idle settlers take jobs.** Free population was a number, not entities — roads sat on “waiting for a free peasant” while 11 settlers stood still. A capped crew (max 4) now hauls, repairs, and raises sites. Optional roads stay off the crew so the Wyrd loop is not starved. Until 12 Stabilized sits in the store, processor and output hauls go first. The HUD idle button shows the real bottleneck (`waiting for planks` / `no storehouse space` / `no jobs`).
- **Channel Wyrd cost is honest.** Starting the rite still costs 12. The first Channel draws from an emergency reserve of 2 (the store stays at 0). Button and tooltip name the cost, the target segment, and the 20 s cooldown.
- **Genuine 260821 victory frame** — the real result overlay after this seed’s Seal, not a staged one.

P2:
- Shelter tents now have flaps, poles, and a campfire.
- Duplicate notices collapse (same title+body within 10 s).
- Victory cools the fissure (teal, lower column, dim light).

The bot still alternates caravan / A-B / wall-overcharge per seed.

Shots (3D, 1920×1080, seed 260821, plus staged Fortify camp). ChatGPT review set is exactly the 10 files in `shots_for_review/` named in `PROMPT.txt`.

---

## Acceptance (4 seeds)

| Seed | Caravan | 6-wyrd | Seal | Channel | Victory | Longest idle | ISS before | ISS after | First build |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **260821** | **20:00 shelter** | **A refine** | **wall** | **1** | **50:36** | **1:20** (80 s) | **16093** | **11151** | **0:08** |
| 261306 | **18:08 fortify** | **B secure** | **overcharge** | **1** | **52:44** | **0:08** (8 s) | **16491** | **12960** | **0:08** |
| 261597 | **19:12 shelter** | **A refine** | **wall** | **1** | **46:04** | **1:04** (64 s) | **17502** | **14587** | **0:08** |
| 260918 | **19:44 fortify** | **B secure** | **overcharge** | **1** | **52:12** | **1:36** (96 s) | **6138** | **2355** | **0:08** |

Windows: Seal (victory) 42–55 min. Idle = no new build, choice, Channel, or threat (the post-night crater march counts as play). Longest idle under 90 s + one 8 s step. Storehouse 1:53 / 5:21; watchtower still lands before night 1.

Idle-settler-seconds: daytime integral of idle count. **Before** = old free-population pool. **After** = remaining idle once laborers took haul / repair / build jobs.

---

## Timeline — seed 260821 (minutes 0–51)

### 0:00 — Founding
Opening yard. Quest: **A Settlement Begins**. House is the first plan (roads wait).

### 0:08 — First meaningful build
House completes. First-build clock: **0:08**.

### 5:21 — Plank loop
**Storehouse** completes at **5:21**.

### 7:04 — First night
**RAID — 2 hostiles**, 60 s warning.

### 12:00 — Frontier and the fissure
**THE SHARD LIES W.** Geologist marks `(218, 175)`. Wyrd Harvester starts on the vent.

### 20:00 — Refugee caravan
**REFUGEES SHELTERED — two workers take the hall.** Persistent tents (flaps, poles, campfire) and extra settlers stay near town for the rest of the hour.

### 24:00 — Camp still on the map
Tents and settlers are still standing by the hall. The caravan choice is readable later, not only at the offer.

### 35:04 — Choice at 6 Stabilized
**FASTER REFINING** (path A). Path B would have spent 3 Stabilized to ward the vent.

### 48:16 — 12 Stabilized, Seal begins
Bot calls `request_begin_seal`. **SEAL BEGUN — defend 120 seconds.** Store spends 12. Emergency reserve holds 2 for Channel Wyrd (store stays 0).

### 48:32 — Channel Wyrd
**CHANNEL WYRD — emergency reserve repairs the wall.** Button `CHANNEL [C] · reserve 2 · wall (x,y)`, 20 s cooldown. Tooltip names reserve, cost, target, cooldown.

### 50:36 — THE FISSURE IS SEALED
Wall path. Ceremony held. Fissure calms (teal, lower column). Victory overlay lists **Shelter / Faster refine / Reinforce wall / Channel Wyrd 1 / 50:36**. Longest idle: **80 s**. Idle-settler-seconds 16093 → 11151. Bottleneck at the end: **no storehouse space**.

---

## Other seeds

Same rule: Seal starts the step the store reaches 12. Bot paths alternate. Caravan is always before the first push. Channel is used once during every Seal. First Channel is always the emergency reserve.

- **261306** — fortify + B + overcharge. Palisades stay up. Victory **52:44**, idle 8 s (the only 90+ gap was the post-night crater march, now counted as play), ISS 16491 → 12960, first build 0:08.
- **261597** — shelter + A + wall. Victory **46:04**, idle 64 s, ISS 17502 → 14587, first build 0:08.
- **260918** — fortify + B + overcharge. Victory **52:12**, idle 96 s (one opening gap; accept slack 90+8), ISS 6138 → 2355, first build 0:08.
