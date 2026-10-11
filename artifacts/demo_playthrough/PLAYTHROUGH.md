# Demo playthrough — 320 province (test #13 / PR #80)

Recorded on `ab53cbd` plus this branch’s blocker fixes. Seed **260821**. Hall `(239, 181)`, Shard `(160, 156)` (~84 tiles away), **4** rival seats. Map 320×320, crater R≈110.

Harness: `tests/t_demo_playthrough.gd` + `src/GodotClient3D/Scripts/production_demo_player.gd`. The bot issues only public `request_*` commands and advances game time at ~8 s/step (fast-forward; clock below is **game time**).

**Result: defeat at 19:23.** The Town Hall fell on night 2. No Binding. No 60-minute ending because the match ended.

Shots: `shots/t00_start.png`, `t05_play.png`, `t07_first_night.png`, `t07_first_raid.png`, `t10_play.png`, `t15_play.png`, `t19_defeat.png`.

---

## Timeline (minutes 0–19)

### 0:00 — Founding
Opening yard after `start_new_3d(260821)`. HUD quest: **A Settlement Begins — Build a Lumber Camp**. Pop 2 / housing 5. Stocks 50 wood, 18 planks, 18 stone, 18 bread, 3 Wyrd. Camera on a lonely keep in a cut meadow; water on the west. The crater and rivals are not on screen (Shard is ~84 tiles inland).

Bot: plan a road, start a **House**.

### 0:08–0:40 — Opening build
Lumber Camp at `(237, 177)`, Farm at `(244, 187)`, more roads. Pop 2→3. Quest still “Build a Lumber Camp” until the camp actually finishes.

### 0:40–5:00 — First dull stretch
House, lumber and farm complete (`bld=4` including the hall). Wood sits at 40–50 (storage full). **Quarry will not place**: 34–35 revealed rocks, almost all `RoadConnection` or `Fog`. The nearest useful rock is ~17 tiles west at `(222, 175)`. The bot lays roads toward it and then waits.

Quest flips to **Build a Quarry** and stays there for the rest of the match.

Notices already on the HUD at minute 5: STORAGE FULL, “6 settlers have been idle for 304s”, “Rival roads pushing toward the Shard”. Night in 1:56. No soldiers. No watchtower yet (unlocks as night draws near).

### 5:36–5:52 — Panic queue
Night-near unlocks the tower. Bot starts **Watchtower** (5:36), **Barracks** (5:44), **Quarry** (5:52) in sixteen seconds. Three paid sites now compete for two carriers. None of them finish before dusk.

### 7:04 — First night / first raid
Night 1. HUD: **RAID — 2 hostiles from the west**, 2 raiders, ETA already elapsed. Dawn in 2:56. Quest still Build a Quarry. Farm and a cottage are up; construction ghosts sit unfinished. Shot `t07_first_night.png` / `t07_first_raid.png`.

The raid damages buildings. The lumber camp is later reported destroyed. Zero enemies killed on the night-1 summary (see minute 15 combat log).

### 7:04–10:00 — Night 1
Pop holds at 10. Buildings dip 4→3 when lumber dies. Bot tries another Lumber Camp at 8:00. Still no soldiers. Still no finished quarry. `t10_play.png`.

### 10:00–15:00 — Day 2, nothing to do
Dawn. Night in ~2:00 again. HUD stacks: STORAGE FULL, RAID OVER (72s, 0 killed, 2 damaged, 1 destroyed lumber, 12 resources lost), combat ticks on the farm. Quest **still** Build a Quarry. Pop 10, soldiers 0, Wyrd 1–3, no outpost, no Lumen. `t15_play.png`.

This is the longest dull stretch: the player can see a raid aftermath and a full store, but the first intention is incomplete and the next night is already on the clock.

### 15:00–18:00 — Second lumber / farm, pop crash
Bot starts another lumber (18:16) and farm (18:32). During night 2 the yard collapses: pop 10→5, buildings 4→1, bread 0.

### 19:23 — Defeat
**THE REALM HAS FALLEN.** Town Hall fell. Days survived 1. Population 5. Wyrd extracted 0. Enemies defeated 0. Combat toast: Town Hall destroyed, 5 raiders from the south-east. `t19_defeat.png`.

Claim at death: “Needs: operational Outpost beside the Shard, connected owned road, connected active Lumen, 12 accumulated Wyrd.” Shard still ~80 tiles of fog away. No rival was ever seen on the map (scout depth 14; seats are across the crater).

Minutes 20–60 did not happen.

---

## Blockers

### Fixed on this branch
1. **Lumber Camp stuck on CLEARING SITE** — footprint trees did not get a woodcutter when every peasant was already on a farm or road. First intention could never start. Fix: spawn a site clearer for priority-10 footprint trees (`_spawn_site_clearer`).
2. **Lumber Camp stuck on Waiting for deliveries** — carriers preferred free road tiles over construction hauls, then one carrier sat **Blocked** on the last tile around the keep with 2 wood in transit forever. Fix: construction supply before road-building; a blocked construction haul completes the dropoff instead of holding transit.

### Not fixed (listed, no redesign)
3. **Quarry cannot be placed near the hall** — rocks in fog or off the road spine. A sensible player needs a 15+ tile road before the first quest’s second criterion. Not a crash; it is why the quest lasts the whole match.
4. **Watchtower / barracks / quarry started together never finish** — three paid sites, two carriers, then night. The bot now serialises to one building at a time (post-run fix). The underlying carrier/last-mile problem can still return if a player queues the same way.
5. **Town Hall dies on night 2 with 0 soldiers** — if the tower and barracks do not complete, the 320-map raid is lethal. This ended the demo.

---

## Dull periods

| Game time | Why it is dull |
| --- | --- |
| 0:48–5:30 | Economy is up. Nothing to spend on except roads toward an unseen rock. Six idle settlers. Storage full. |
| 7:30–10:00 | Night raid is a toast, not a fight you can command. |
| 10:00–17:00 | Day 2: same quest, same full storage, same “build a quarry”, night timer already ticking. No new buildings, no scout, no shard, no rival. |
| 17:00–19:23 | Collapse. No time to recover. |

Almost every 90 s after the first minute logged as an idle gap (no new order). That is the DPM problem: the bot (and a human in the same state) has nothing useful to click.

---

## Unclear UI or quests

- **HUD type is doubled / broken** on lavapipe (`AsettlementBeginings`, `Buildld a Quarryy`, `STORAGEFULL`, `RAIDID`, `THE REALM HAS FALLEN`). Buttons read `TRYAGAIN`, `NEWREALM`. A new player cannot parse the quest or the raid toast.
- **First quest is two buildings** (Lumber + Quarry) but the pill only names the current criterion. After lumber, the pill still says “A Settlement Begins” for 19 minutes.
- **“Rival roads pushing toward the Shard”** appears in the first minutes with no rival on screen and no way to walk there. Reads as flavour, not a goal.
- **Raid warning** (`2 hostiles from the west`) has no map ping the bot could see. The player has no army to send.
- **Build strip** shows Quarry locked behind lumber, Watchtower “as night draws near”, Outpost after a tower — but the Shard is 84 tiles away with no breadcrumb.
- **Defeat overlay** does not say how to win next time (Bind the Shard / hold two nights / rebuild). It only lists the hall fell.

---

## Bugs

- Site-clear + blocked construction haul (fixed, see above).
- **Raid events did not always hit `raid_started` in the journal** in time for the harness; the night screenshot still shows the raid. Harness now also keys off `raid_active`.
- **Lumber destroyed on night 1**, first quest still wants a quarry; no “your production died, rebuild” beat beyond a combat toast.
- Font atlas / type doubling on this Linux/lavapipe capture (may be host-specific; still how the 1080p shots look).
- Audio ERROR spam for missing `.ogg` / `.wav` imports (pre-existing; dummy driver). Not counted as a new script error.

---

## Balance

- **Night 1 raid arrives before the first quest is done.** Tower unlocks 90 s before dusk; 8 stone + 4 planks and a carrier queue means it is not up for the first wave.
- **0 soldiers at 15:00.** Barracks costs 10 planks + 8 stone and unlocks with the tower. Training never started.
- **Storage fills in the first two minutes** (start 50 wood + lumber). The next building (storehouse) needs planks the player does not have without a sawmill, which unlocks after lumber and costs 6 wood they are told to save.
- **Scout depth 14** on a 320 map. Rivals and the Shard are 80–150 tiles away. Scouting cannot produce an encounter.
- **Binding** needs an outpost within 6 tiles of the Shard, roads, Lumen, 12 Wyrd, 120 s hold. At ~1.6 s/road tile plus carrier contention, 84 tiles is a long night-2 project even if the hall lives.
- Rival AI is already “pushing roads” on the HUD at minute 5 while the player cannot see them. Rival claim unlock is 2280 s (38 min) — the player died at 19.

---

## Missing for a 1-hour demo

Content and goals, not a redesign list:

1. **A quest that can be finished in the first day** — lumber alone, or a quarry in the founding stone cluster, not 17 tiles of road.
2. **A finished watchtower before night 1** — cheaper tower, earlier unlock, or a prebuilt sentry. Night 1 should be tense, not a hall check.
3. **Something to do in minutes 8–20** — a scout that can actually reach a frontier marker, a named rock/wyrd tile on the minimap, a second house that matters.
4. **A visible rival or crater goal by minute 15** — even a one-shot reveal / “the Shard lies west” camera beat. Right now the win condition is off-map.
5. **An ending the player can reach in 35–55 minutes** — Binding on the 320 map is not a 1-hour route unless roads/Lumen are much faster or the Shard is closer. A mid-demo “held two nights” or “first outpost” beat would give the session a close.
6. **Readable HUD type** — the 1080p shots are not shippable as a store page or playtest packet until the font stops doubling.
7. **Raid you can play** — soldiers, a ping, a recall. The current raid is a toast and then a defeat screen.

What worked: founding reads as a settlement, the farm/cottage/field compose a picture, night lighting and the raid toast *want* to be dramatic, the defeat screen is an ending (just not the one the design asked for).

---

## Run log (csv)

`playthrough.csv` — one row per 8 s: clock, day/night, pop, housing, soldiers, buildings, roads, wood/planks/stone/wheat/bread/wyrd, quest title, event tag, victory, finished.

Peak: pop 10, buildings 4, roads 19, wood ~50, soldiers 0, Wyrd 3→0. Finished `1163.4` s, `victory=0`.
