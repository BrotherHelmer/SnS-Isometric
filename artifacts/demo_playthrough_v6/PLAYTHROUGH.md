# Demo playthrough v6 — midgame caravan + distinct Seal looks (PR #85)

Recorded on `cursor/midgame-event-a689`, stacked on PR #84 (`c0fca8e`). Official seed **260821**. Hall `(239, 181)`, Shard `(160, 156)` (~84 tiles west), **4** rival seats. Map 320×320, crater R≈110. Fissure at `(218, 175)`.

Harness: `tests/t_demo_playthrough.gd` + `src/GodotClient3D/Scripts/production_demo_player.gd`. The bot issues only public `request_*` commands and advances game time at 8 s/step. Clock below is **game time**.

**Result: THE FISSURE IS SEALED when 12 Stabilized is earned + 120 s defence, with a mid-ceremony choice at ~60 s.** No Seal clock. Survival (`THE REALM HOLDS`) is a milestone toast, not a win. The real **Shard Binding is a later-act hook** (hook only).

Between **15:00 and 22:00**, before the rival's first push, a refugee caravan arrives:
- **shelter** — two workers take the hall. Extra mouths raise Wyrd exposure.
- **fortify** — spend wood, raise palisades, delay the first push.

At 6 Stabilized the player still chooses a Wyrd pact:
- **A / refine** — the kiln runs hotter (same 3-raw recipe, faster ticks).
- **B / secure** — invest 3 Stabilized; the vent harvests faster and the rival raid loses its teeth.

During the Seal, at ~60 s, a second choice. The two paths now **look different on screen**:
- **wall** — amber ward ring and palisade segments. The ceremony needs 20 more seconds.
- **overcharge** — brighter, faster pulse, thinner ward, a visible extra wave. The rite finishes ~20 s sooner.

The bot alternates caravan / A-B / wall-overcharge per seed.

Shots (3D, 1920×1080, seed 260821, plus staged Seal looks). ChatGPT review set is exactly the 10 files in `shots_for_review/` named in `PROMPT.txt`.

---

## Acceptance (4 seeds)

| Seed | Event (15–22) | 6-wyrd | Seal choice | Victory | Longest idle |
| --- | --- | --- | --- | --- | --- |
| **260821** | **20:00 shelter** | **A refine** | **wall** | **46:04** | **1:04** (64 s) |
| 261306 | **18:08 fortify** | **B secure** | **overcharge** | **42:04** | **1:12** (72 s) |
| 261597 | **19:12 shelter** | **A refine** | **wall** | **44:44** | **1:01** (61 s) |
| 260918 | **19:44 fortify** | **B secure** | **overcharge** | **53:48** | **1:28** (88 s) |

Windows: Seal (victory) 42–55 min. Idle = no new build, choice, or threat. Longest idle under 90 s on all four seeds.

---

## Timeline — seed 260821 (minutes 0–46)

### 0:00 — Founding
Opening yard. Quest: **A Settlement Begins**.

### 5:28 — Plank loop
**Storehouse** completes at **5:21**.

### 7:04 — First night
**RAID — 2 hostiles**, 60 s warning.

### 12:00 — Frontier and the fissure
**THE SHARD LIES W.** Geologist marks `(218, 175)`. Wyrd Harvester starts on the vent.

### 20:00 — Refugee caravan
**REFUGEES SHELTERED — two workers take the hall. The extra mouths raise Wyrd exposure.** Fortify would have spent wood and delayed the first push.

### 20:47 — Capture
**CAPTURED — +8 Wood, +4 Stone, +2 Wyrd.** No Stabilized dump.

### 23:20 — Escalation, then a push
**RIVAL ARMY MARKED — banners grow. A push is coming down this road.** TIER 3 PUSH. The Outpost lands after the telegraph.

### 33:04 — Choice at 6 Stabilized
**FASTER REFINING** (path A). Path B would have spent 3 Stabilized to ward the vent.

### 43:44 — 12 Stabilized, Seal begins
Bot calls `request_begin_seal`. **SEAL BEGUN — defend 120 seconds.**

### 44:48 — Seal defence choice
**WALL REINFORCED — the palisade holds.** Amber ward ring and palisade posts. Path overcharge would have pulsed brighter, thinned the ring, and called another wave.

### 46:04 — THE FISSURE IS SEALED
Ceremony held. Overlay: **THE FISSURE IS SEALED — the ceremony held.** Gold banners on the fissure. Longest idle: **64 s**.

---

## Other seeds

Same rule: Seal starts the step the store reaches 12. Bot paths alternate. Caravan is always before the first push.

### 261306 — fortify / path B / overcharge
Hall `(238, 143)`. Caravan **18:08 fortify**. Foreshadow 13:24. Reveal 19:08. Choice **secure** at 32:32. Seal choice **overcharge**. **Victory 42:04.** Idle **72 s**. Fissure `(216, 149)`.

### 261597 — shelter / path A / wall
Hall `(241, 182)`. Caravan **19:12 shelter**. Foreshadow 10:58. Reveal 19:34. Choice **refine** at 33:44. Seal choice **wall**. **Victory 44:44.** Idle **61 s**. Fissure `(220, 178)`.

### 260918 — fortify / path B / overcharge
Hall `(76, 188)`, crater **NE**. Caravan **19:44 fortify**. Foreshadow 10:18. Reveal 16:02. Choice **secure** at 41:44. Seal choice **overcharge**. **Victory 53:48.** Idle **88 s**. Fissure `(100, 181)`.

---

## Gates (this pass)

| Gate | Result |
| --- | --- |
| 4-seed `--accept` Seal | **PASS** — 46:04 / 42:04 / 44:44 / 53:48 |
| Longest idle < 90 s | **PASS** — 64 / 72 / 61 / 88 |
| t_crater_war | PASS (caravan 15–22; both Seal looks; banners / route / threat before push) |
| export audit | **MISSING 0** |
| first frame | **1457 ms** (`t_first_screen`; pre-existing Watchtower unlock fail is unrelated) |

## What still fails / is dull

- Staged Seal close-ups use a stripped yard so the ward / palisade / wave can be read; the hour itself is the 260821 playthrough.
- Harvester / Refiner thumbs still reuse nearby civic models.
- The real Shard Binding is a later-act hook only.
- Pre-existing `Cannot open file` for a few audio / civic_keep imports during 3D is unchanged.

---

## CSVs

- `playthrough.csv` — seed 260821
- `playthrough_<seed>.csv` — the other three
- `dpm_<seed>.csv` — playtest log
- `notes.json` / `notes_<seed>.json` — includes `midgame_choice`, `choice`, `seal_choice`, `first_12_at`, `ritual_at`, `longest_idle`
