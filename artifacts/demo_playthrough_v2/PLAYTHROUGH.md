# Demo playthrough v2 — one-hour hold (PR #81)

Recorded on `cursor/demo-playthrough-a689` at `d9bc1a0` (hold hour) plus the P2 HUD/notice pass on this branch. Official seed **260821**. Hall `(239, 181)`, Shard `(160, 156)` (~84 tiles west), **4** rival seats. Map 320×320, crater R≈110.

Harness: `tests/t_demo_playthrough.gd` + `src/GodotClient3D/Scripts/production_demo_player.gd`. The bot issues only public `request_*` commands and advances game time at 8 s/step. Clock below is **game time**.

**Result: THE REALM HOLDS at 45:00.** Four nights survived. Watchtower, Barracks, frontier stake and a visible rival all land inside the one-hour window. Binding remains the longer war.

Shots (3D, 1920×1080, seed 260821): `t00_start`, `t04_first_quest`, `t05_play`, `t07_first_night`, `t07_first_raid`, `t10_play`, `t12_frontier`, `t15_play`, `t18_rival`, `t20_play`, `t25_play`, `t30_play`, `t35_play`, `t40_play`, `t44_victory`. Type proof after the outline-off pass: `hud_victory_type`, `hud_raid_type`.

---

## Acceptance (4 seeds)

| Seed | Survive 25+ | Shard | Rival | Victory | Minute |
| --- | --- | --- | --- | --- | --- |
| **260821** | yes | yes (12:00, west) | yes (18:00, Claimant Outpost at 236,162) | THE REALM HOLDS | **45:00** |
| 261306 | yes | yes | yes (18:00, Claimant Outpost at 229,164) | THE REALM HOLDS | **45:00** |
| 261597 | yes | yes | yes (18:00, Claimant Outpost at 237,163) | THE REALM HOLDS | **45:00** |
| 260918 | yes | yes (12:00, NE) | yes (18:00, Claimant Outpost at 99,197) | THE REALM HOLDS | **45:00** |

P0/P1 on 260821:

1. Founding quarry stone at `(248, 185)`, **7.3 tiles** from the hall (band 5–8). Quarry placed at 4:08.
2. Construction deliveries beat road jobs. Barracks finishes on day 1 with stock in the hall.
3. Watchtower unlocks at **2:00**, started immediately, complete before night 1. Raid warning **60 s**, map ping, 2 visible raiders.
4. Night 1 stays at **2** raiders (Barracks not yet complete at dusk). Later nights cap at **5** once the Barracks stands.

---

## Timeline — seed 260821 (minutes 0–45)

### 0:00 — Founding
Opening yard. Quest: **A Settlement Begins**. Pop 2 / housing 5. Stocks 50 wood, 18 planks, 18 stone, 18 bread. Hall in a cut meadow; crater and rivals off-screen.

Bot: road, **House** at `(243, 185)`.

### 0:16–0:32 — Opening economy
**Lumber Camp** `(237, 177)` at 0:16. **Farm** `(244, 187)` at 0:32. Pop 2→5. Roads stitch the yard.

### 2:00 — Watchtower
Military unlocks. Bot starts **Watchtower** `(238, 181)`. House / lumber / farm already up (`bld=4`). Stone deposit for the quarry sits 7 tiles east.

### 2:56 — Barracks
**Barracks** `(243, 182)` starts. Carriers haul planks and stone instead of walking off to lay frontier road. Night 1 is still 2:00 away.

### 4:08 — Quarry
**Quarry** `(246, 178)` on the guaranteed founding stone. First intention completes at **4:56** (`A Settlement Begins`).

### 5:00 — Yard is armed
Pop 9, **3 soldiers** already training, `bld=7` (hall, house, lumber, farm, tower, barracks, quarry). Wood 100, stone 2 (just spent). Quest flips to **Build a Storehouse** — the bot cannot afford it (planks reserved / spent) and keeps pushing roads. This is a dull stretch, not a soft-lock.

### 7:04 — First night / first raid
Night 1. **RAID — 2 hostiles**, 60 s warning already fired, map ping on the approach. Pop 10, **4 soldiers**, Watchtower watching. Lumber is not destroyed. Dawn 10:00.

### 10:00–12:00 — Day 2, west
Roads walk west toward the crater. Pop 10, 4 soldiers, yard intact.

### 12:00 — Frontier
**THE SHARD LIES W — a frontier marker is within reach.** Corridor reveal, Shard ping, and a player **Claimant Outpost** planted on the marker (~24 tiles, ≥16 required for the hold). Goal is on the map and reachable.

### 15:00 — Holding
Same keep, same four soldiers. Roads continue west. Storage-full toasts. No collapse.

### 18:00 — Rival
**Rival Claimant Outpost** revealed at `(236, 162)` — on the map, walkable from the yard. Night 2 begins on the same clock (5 raiders, Barracks is up, 4 soldiers + tower).

### 20:00–40:00 — Nights 2–4
Every night is a 5-raider cap after the Barracks. Pop stays 10, buildings stay 7, soldiers stay 4. The bot lays a long west road (248 tiles by the hold). Quest later reads **Stone Shortage** (storehouse still unaffordable). Dull, but the settlement is not dying.

### 45:00 — THE REALM HOLDS
Day 5, dawn already broken. Overlay: **THE REALM HOLDS — five days on the frontier. Binding the Shard remains the longer war.** Days survived 4. Watchtower, Barracks, frontier stake, Shard revealed. Match ends. Binding was not attempted (12 Wyrd + shard-side outpost still the long war).

---

## Other seeds

Same bot, same hold rules. All three also finish **THE REALM HOLDS at 45:00**.

### 261306
Hall `(238, 143)`, Shard `(156, 161)`, 3 rivals. First quest at 1:20. Night 1 at 7:04 with 2 raiders. Rival Claimant Outpost at `(229, 164)` at 18:00. Hold at 45:00.

### 261597
Hall `(241, 182)`, Shard `(162, 163)`, 4 rivals. First quest at 1:28. Night 1 at 7:04 with 2 raiders. Rival Claimant Outpost at `(237, 163)` at 18:00. Hold at 45:00.

### 260918
Hall `(76, 188)`, Shard `(157, 156)`, 3 rivals. First quest at 4:32. Night 1 at 7:04 with 2 raiders. Frontier **NE** at 12:00. Rival Claimant Outpost at `(99, 197)` at 18:00. Hold at 45:00.

---

## Gates (this pass)

| Gate | Result |
| --- | --- |
| t_demo_balance | PASS (stone 5–8 on 4 seeds, tower@120s, construction before roads, raid 60s + ping, 2→5 only after Barracks, hold at 2700) |
| t_raid_warnings | PASS |
| t_economy_feedback | PASS |
| t_hud_type | PASS (Label/Button/RichTextLabel outline_size 0) |
| t_sns_ui_look | PASS |
| t_bigmap | PASS — start_new_3d **822 ms**, first frame **715 ms**, Master **1.000** |
| export audit | **MISSING 0** |
| t_founding_seeds sim | **100/100** including the quarry-stone 5–8 band |

## What still fails / is dull

- **Storehouse was unaffordable** on the recorded 260821 hour (4 planks left after the tower + barracks). The bot now falls through to a Sawmill instead of spinning on that quest; the 45:00 CSVs were recorded before that change and still show the stall.
- **Dull road-laying** from minute 12 to 45. Something meaningful happens at 12 (frontier), 18 (rival), 7/18/30/40 (nights), 45 (hold). The in-between is settlers walking west.
- **1080p type**: HUD outline_size is now 0 plus a 1 px shadow. Tight crops of `THE REALM HOLDS / FIVE DAYS` are a single stroke. Cinzel ball terminals can still be misread as an extra letter (HOLDSO / RAIDOID) by a reviewer model; not re-verified on a discrete GPU.
- **Binding** is still the longer war and is not reachable in this hour on the 320 map.
- **git push** of the local commits after `ca9967c` is blocked in this environment (no GitHub write credentials). PR #81 body is updated; remote code may still be the pre-hold revision until the branch is pushed.
- Official **3D hour shots** are from the hold recording; `hud_victory_type` / `hud_raid_type` are the type-proof pass.

---

## CSVs

- `playthrough.csv` — seed 260821, 8 s rows through the hold
- `playthrough_<seed>.csv` — the other three seeds
- `dpm_<seed>.csv` — playtest log
- `notes.json` / `notes_<seed>.json`
