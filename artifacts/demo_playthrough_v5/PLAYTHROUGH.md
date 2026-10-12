# Demo playthrough v5 — Seal defence choice + visible rival escalation (PR #84)

Recorded on `cursor/seal-defence-a689`, stacked on PR #83 (`60d2902`). Official seed **260821**. Hall `(239, 181)`, Shard `(160, 156)` (~84 tiles west), **4** rival seats. Map 320×320, crater R≈110. Fissure at `(218, 175)`.

Harness: `tests/t_demo_playthrough.gd` + `src/GodotClient3D/Scripts/production_demo_player.gd`. The bot issues only public `request_*` commands and advances game time at 8 s/step. Clock below is **game time**.

**Result: THE FISSURE IS SEALED when 12 Stabilized is earned + 120 s defence, with a mid-ceremony choice at ~60 s.** No Seal clock. Survival (`THE REALM HOLDS`) is a milestone toast, not a win. The real **Shard Binding is a later act** (hook only).

At 6 Stabilized the player still chooses a Wyrd pact:
- **A / refine** — the kiln runs hotter (same 3-raw recipe, faster ticks).
- **B / secure** — invest 3 Stabilized; the vent harvests faster and the rival raid loses its teeth.

During the Seal, at ~60 s, a second choice:
- **wall** — reinforce the palisade (+HP / +ward). The ceremony needs 20 more seconds.
- **overcharge** — finish ~20 s sooner. The wall is thinner and another wave comes.

The bot alternates A/B and wall/overcharge per seed. The rival foreshadows at 10:00–15:00 (distant smoke / scout), reveals on a seeded time in 14:00–20:00, then paints growing banners, an army route, and a TIER / threat marker **before** each push or raid.

Shots (3D, 1920×1080, seed 260821). ChatGPT review set is exactly the 10 files in `shots_for_review/` named in `PROMPT.txt`.

---

## Acceptance (4 seeds)

| Seed | Reveal | Foreshadow | 6-wyrd | Seal choice | Victory | Longest idle |
| --- | --- | --- | --- | --- | --- | --- |
| **260821** | 19:26 | **14:14** | **A refine** | **wall** | **45:31** | **1:04** (64 s) |
| 261306 | 19:08 | **13:24** | **B secure** | **overcharge** | **44:59** | **1:42** (101.5 s) |
| 261597 | 19:34 | **10:58** | **A refine** | **wall** | **44:43** | **1:48** (107.5 s) |
| 260918 | 16:02 | **10:18** | **B secure** | **overcharge** | **53:07** | **1:28** (88 s) |

Windows: Seal (victory) 42–55 min. Idle = no new build, choice, or threat. No stretch longer than 3 minutes.

---

## Timeline — seed 260821 (minutes 0–46)

### 0:00 — Founding
Opening yard. Quest: **A Settlement Begins**.

### 5:21 — Plank loop
**Storehouse** completes at **5:21**.

### 7:04 — First night
**RAID — 2 hostiles**, 60 s warning.

### 12:00 — Frontier and the fissure
**THE SHARD LIES W.** Geologist marks `(218, 175)`. Wyrd Harvester starts on the vent.

### 14:14 — Foreshadow
**SCOUT SIGHTING — distant rival smoke on the crater road.** TIER 1 SMOKE. Before the reveal.

### 19:26 — Rival reveal (seeded)
Rival Claimant Outpost sighted. Banners grow to TIER 2 SIGHTED.

### 20:47 — Capture
**CAPTURED — +8 Wood, +4 Stone, +2 Wyrd.** No Stabilized dump.

### 22:31 — Escalation, then a push
**RIVAL ARMY MARKED — banners grow. A push is coming down this road.** TIER 3 PUSH. The Outpost lands eight seconds later.

### 24:23 — Raid ping, then a raid
**RAID PING — the rival marks a route onto the Wyrd vent.** TIER 4 RAID. The harvester raid follows.

### 31:43 — Choice at 6 Stabilized
**FASTER REFINING** (path A). Path B would have spent 3 Stabilized to ward the vent.

### 43:11 — 12 Stabilized, Seal begins
Bot calls `request_begin_seal`. **SEAL BEGUN — defend 120 seconds.**

### 44:15 — Seal defence choice
**WALL REINFORCED — the palisade holds. The ceremony needs 20 more seconds.** Path overcharge would have finished faster and called another wave.

### 45:31 — THE FISSURE IS SEALED
Ceremony held. Overlay: **THE FISSURE IS SEALED — the ceremony held.** Longest idle: **64 s**.

---

## Other seeds

Same rule: Seal starts the step the store reaches 12. Bot paths alternate.

### 261306 — path B / overcharge
Hall `(238, 143)`. Foreshadow 13:24. Reveal 19:08. Choice **secure** at 34:31. Seal choice **overcharge**. **Victory 44:59.** Idle **1:42**. Fissure `(216, 149)`.

### 261597 — path A / wall
Hall `(241, 182)`. Foreshadow 10:58. Reveal 19:34. Choice **refine** at 33:59. Seal choice **wall**. **Victory 44:43.** Idle **1:48**. Fissure `(220, 178)`.

### 260918 — path B / overcharge
Hall `(76, 188)`, crater **NE**. Foreshadow 10:18. Reveal 16:02. Choice **secure** at 43:27. Seal choice **overcharge**. **Victory 53:07.** Idle **1:28**. Fissure `(100, 181)`.

---

## Gates (this pass)

| Gate | Result |
| --- | --- |
| 4-seed `--accept` Seal | **PASS** — 45:31 / 44:59 / 44:43 / 53:07 |
| Longest idle ≤ 3 min | **PASS** — 1:04 / 1:42 / 1:48 / 1:28 |
| t_crater_war | PASS (Seal defence choice; banners / route / threat before push; 10–15 foreshadow) |
| t_demo_balance | PASS (hold is a milestone) |
| export audit | **MISSING 0** |
| first frame | **918 ms** (`t_first_screen`) |

## What still fails / is dull

- 3D banner meshes can sit off the review camera; the HUD threat line and the raid ping carry the map read.
- Harvester / Refiner thumbs still reuse nearby civic models.
- The real Shard Binding is a later-act hook only.

---

## CSVs

- `playthrough.csv` — seed 260821
- `playthrough_<seed>.csv` — the other three
- `dpm_<seed>.csv` — playtest log
- `notes.json` / `notes_<seed>.json` — includes `choice`, `seal_choice`, `foreshadow_at`, `rival_reveal_at`, `first_12_at`, `ritual_at`, `longest_idle`
