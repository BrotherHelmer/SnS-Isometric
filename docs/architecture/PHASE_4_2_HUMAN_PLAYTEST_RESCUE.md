# Shards & Sovereign — Phase 4.2 Human Playtest Rescue

**Result: PASS — ready for next human fun playtest**

Phase 4 / 4.1 remain the One Shard loop. This phase does not add buildings, chains, enemies, tech, or quests. It removes expansion friction, makes REACH THE SHARD actionable, makes Night 2 reach the perimeter, and stops presenting generated score as music.

Engine: Godot 4.7 stable (`D:\SnS_Isometric\.tools\godot-4.7\Godot_v4.7-stable_win64_console.exe`). Review seed **260821**. Captures: `artifacts/phase4_2/screenshots/`. Isolated user data: `artifacts/phase4_2/isolated_user`.

## 1. Human findings reproduced

The playtest complaints mapped to four roots, all reproduced in simulation:

| Complaint | Reproduced |
| --- | --- |
| Trees too slow / no room for a Storehouse | Founding forest + storage-full lumber halt could freeze Clear & Build |
| STORAGE FULL blocking and repeating | Centered persistent warning, no log |
| “I've built everything. Now what?” | Macro title REACH THE SHARD with no next steps |
| Two/three soldiers and one tower delete raids | Tower range/damage and Night 2 spawn let waves die in approach |
| Watchtower guard stands at the base | Ground worker presentation for staffed towers |
| Demo audio | Phase 4.1 oscillator score in the default mix |

Positive reports (smooth frame, night look, worker states, settlement sim) were treated as constraints, not reopeners.

## 2. Tree clearing before / after

| | Before (playtest) | After |
| --- | --- | --- |
| Lumber interval / yield | Felt like a long wait per tree | **2.0 s / 1 Wood** |
| Nearby / far deposit size | High remaining per tree | **4 nearby / 6 far** |
| One woodcutter, 45 s, seed 260821 | Human: “too slow” | **530 → 527 trees** (three felled, including walk time) |

Cadence is work authority, not animation speed-up. A dedicated camp now removes a nearby tree in well under 45 s once the worker is on site (~8 s of chops for a 4-deposit tree).

## 3. Tree yield / cadence change

Wood income stays about **30 Wood/min** per staffed camp (1 per 2 s). Visual clearing improved by cutting remaining per tree, so more trunks disappear for the same Wood. Manual / site-clear jobs still yield **2 Wood** and remove the tree immediately.

## 4. Clear & Build architecture

Most buildings (not Quarry, not protected features) may be **planned on harvestable TREE cells**.

1. Placement validates with **CLEARING REQUIRED**.
2. The site is accepted; trees are **not** deleted.
3. Footprint trees become priority-10 clear jobs.
4. Status is **CLEARING SITE**; the construction mesh is hidden while trees live.
5. Woodcutters prefer those tiles; idle population can spawn clearers.
6. Construction time runs only after the footprint is grass.

Stone, Shard, Wyrd, camps, and other protected tiles still refuse silent erase.

Optional **CLEAR** tool lives under Infrastructure: drag-mark TREE cells as priority-8 jobs. Not required for normal placement.

## 5. Starting clearing change

Town / rival founding apron radius is **8**, plus a small side pad. Random trees skip tiles closer than 8. Forest stays on the rim. Seed 260821: **≥80 grass / <20 trees** in radius 6 of Town Hall. Capture: `01_starting_clearing.png`.

## 6. Storage anti-softlock

- Construction still **reserves** from existing stock, so a Storehouse can be planned at cap.
- Town Hall non-Wyrd cap includes **+8 overflow** (`TOWN_HALL_OVERFLOW`).
- **Priority tree jobs still fell when lumber output is full.** Extra Wood fills overflow if any room remains; the tree still goes. That breaks “storage full → woodcutters idle → cannot clear a Storehouse pad.”

Test: full Wood/Planks/Stone + forested Storehouse footprint → `Construction started: Storehouse.`

## 7. Notification / toast redesign

Long-lived center STORAGE FULL banners are gone. Routine events use a **toast**: icon, headline, body, dismiss X. Hold ~4.2 s (7.5 s critical), then fade. Identical titles cooldown in the sim (`_notice_if_new`, 48 s for storage/bakery). RAID / Town Hall attack stay critical.

## 8. Event log

**LOG** opens a compact history (~40 entries): economy, construction, danger, and the rest of `push_notice`. Dismissing the toast does not delete the log. Capture: RAID toast on `09_night2_raid_approach.png`.

## 9. Objective / action guidance

The button still shows SURVIVE → REACH THE SHARD → SECURE THE SHARD → BIND THE SHARD.

Click expands 2–3 **context steps** and glances the camera at the Shard, with a brief **▲ SHARD** edge marker if the beacon is off-screen.

After House + Lumber + Farm, seed 260821 reports:

> REACH THE SHARD — Build roads and Outposts toward the beacon.  
> 1. Extend a connected road toward the Shard.  
> 2. Build a Claimant Outpost on the frontier.  
> 3. Keep the Outpost connected to Lumen.

Capture: `06_objective_reach_the_shard.png`.

## 10. Outpost onboarding

When the starter economy is ready and no Outpost exists, one hint fires (not at game start):

> OUTPOSTS EXTEND YOUR REALM. Connect one by road and Lumen to push toward the Shard.

Distinct from the later “Outposts harvest Wyrd” hint. Build menu prefixes **FRONTIER ·** on Outpost and Lumen Pillar in that state.

## 11. Night baseline formula

```
effective = wyrd_pressure + night_baseline(day)
Night 1: size 2 Raiders, teaching, baseline 0
Night 2: size 5, Raider/Marauder mix, baseline 16, HP 30
Later: band from effective pressure; Brutes enter as pressure rises
```

No scaling from tower or soldier **count**. Wyrd remains the dominant player-controlled escalator.

## 12. Night 1 vs Night 2 results

| | Night 1 | Night 2 (1 tower, seed 260821) |
| --- | --- | --- |
| Size | 2 | 5 (includes Marauders) |
| Spawn | Teaching | 11–16 tiles, skip in-tower-range tiles |
| Result | Survivable | Closest approach **6–7** tiles; **3–4 still alive** after ~24–28 s; run not finished |

Night 2 no longer dies in deep fog. Contact is the Town Hall protection rim (~8) plus tower fire, not a pre-settlement wipe.

## 13. Tower balance changes

| | Was (playtest feel) | Now |
| --- | --- | --- |
| Range | Long enough to cover the whole approach | **8** (overlay matches) |
| Damage | Deletes | **5** on projectile **impact** (life 0.65 s) |
| Cooldown | Too fast | **2.2 s** |

One shot wounds a Night 2 Raider; it does not delete them. Projectile damage stays impact-only.

## 14. Guard balance changes

Guard damage **4**, cadence **1.55 s**, HP 40. One exchange does not kill a Raider. Rebuild smoke: 1v1 still resolves for the guard over ~20 s; 2 Raiders still win a lone open-field soldier.

## 15. Enemy HP / cadence changes

Night 2 Raider **30 HP / 7 damage**. Marauder (`skitterer`) stays fast (`speed` 0.52 step multiplier) and thinner so it can slip tower fire. Brute stays slow and heavy for later pressure. No new archetypes.

## 16. Watchtower guard presentation

Staffed tower guards snap to the footprint, state Guarding / Night Watch / Fighting, and present `platform: true`, `elevation: 4.85`. The adapter remaps them to the **ranger** silhouette and offsets world Y. They do not idle as a ground peasant at the base. Automated presentation test PASS. Capture `08_watchtower_guard.png` shows a distinct tower beside Town Hall; a follow-up human look should confirm the ranger on the parapet at game speed.

## 17. Audio audit

See `docs/art/PHASE_4_2_AUDIO_AUDIT.md`. Score stems classified **C** and muted. Ambience / Wyrd / cues remain. No new packs imported.

## 18. New audio sources / licenses

None imported. Kenney CC0 packs are the preferred next source. Ledger: `docs/art/AUDIO_LICENSE_LEDGER.md`.

## 19. Manual audio assessment

`tests/phase4_2_audio_evidence.gd` PASS: states resolve; **no score stem** in the active mix; raid fires `enemy` once.

A headphone quality pass was not run here. Day/night are mix-distinct (night birds −28 dB vs day −11). Raid is a sting, not a looping metal bed. Generated birds/Wyrd/UI still read as prototype content. **Do not call the soundtrack finished.**

## 20. Combat matrix

| Case | Evidence |
| --- | --- |
| 1 guard vs 1 Raider | Damage both ways; first exchange does not finish the Raider |
| 2 guards vs 3 / 3 vs 5 | Not separately timed; 2 Raiders still beat 1 open-field guard |
| 1 tower vs Night 2 | Closest 6; 3 alive after 28 s; not a fog wipe |
| 1 tower + 2 guards vs Night 2 | Same spawn rules; first_ten 1-tower prep closest 7, 4 alive, settlement up |
| Marauder vs road | Fast archetype retained; included in Night 2 roster |
| Brute vs fortification | Unlocked by later pressure bands, not Night 2 |

Readability target: prepared player holds the rim; Night 2 is uncomfortable; tower is valuable, not a force field.

## 21. Human 15-minute playtest result

Headless first-ten / first-two-nights stand-in (`tests/phase4_2_first_ten_minutes.gd`) PASS on 260821:

- Apron is buildable
- Woodcutter removes trees inside 45 s
- Starter economy → REACH THE SHARD + Outpost steps
- Full storage + trees → Storehouse still plans
- Night 1 teaching wave of 2, survivable
- Night 2 size 5, reaches outer defence, survivable

A live 15-minute session is still the next human fun playtest. This pass did not sit a person through dusk with headphones.

## 22. Human Night 2 result

Seed 260821, ordinary one-tower prep:

- RAID toast: “5 hostiles are emerging from the fog.”
- Spawn outside tower range
- Closest **6–7** (protection rim), **not** deleted in wilderness
- Settlement still up

Melee in the streets is uncommon because the Town Hall bubble still holds at 8 tiles. Contact is perimeter fire + possible patrol fights. That matches “outer defence” more than “inside the houses.”

## 23. Performance regression

No optimization pass. Capture suite after warmup **~19–21 FPS** at 1920×1080 Forward+ on the workstation used for 4.1. First-frame hitches remain capture artifacts. Player report of smoothness was preserved; no new profiler work.

## 24. Remaining weaknesses

- Generated ambience / chop / UI / Wyrd drone still demo-quality; score gap is documented, not filled with more math-music.
- Town Hall protection bubble (8) equals tower range, so Night 2 “melee in the yard” is rare without walking guards out.
- Platform-guard capture is weaker than the sim descriptor; needs a human eye at play speed.
- Clear & Build still wants a connected Lumber Camp or free population; it no longer deadlocks when that camp’s bin is full.
- `CLEARING REQUIRED` ghost/label in automated capture 02 is easy to miss versus a live mouse preview.

## Tests run

| Test | Result |
| --- | --- |
| `tests/phase4_2_parse_smoke.gd` | PASS |
| `tests/phase4_2_human_playtest_rescue.gd` | PASS |
| `tests/phase4_2_first_ten_minutes.gd` | PASS |
| `tests/phase4_2_audio_evidence.gd` | PASS |
| `tests/phase4_2_capture_suite.gd` | PASS (12 shots) |
| `tests/phase4_wyrdfall_smoke.gd` | PASS |
| `tests/phase4_1_parse_smoke.gd` | PASS |
| `tests/godot_rebuild_smoke.gd` | PASS |

## Final status

**PASS — ready for next human fun playtest**

The player should now be able to say: I’ll clear this and expand here; storage is a Storehouse problem; next is an Outpost toward the Shard; Night 2 is actually uncomfortable. They should not hear a looping synth “score.” They should still be asked, in the next sitting, whether the remaining ambience/SFX feel buyable.
