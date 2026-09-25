# Shards & Sovereign — Phase 4.1 Presentation Identity

**Result: PASS — ready for serious human fun/balance playtest**

Phase 4.1 does not reopen the One Shard loop. Pressure, waves, rival unlock, Binding duration, and economy costs are unchanged. The work is identity: Lumen warmth, rare Wyrd, authored lighting states, HUD hierarchy, and a state-driven mix.

Engine: Godot 4.7 stable (`D:\SnS_Isometric\.tools\godot-4.7\Godot_v4.7-stable_win64_console.exe`). Captures and audio evidence used Forward+. Isolated user data: `artifacts/phase4_1/isolated_user`. Review seed: **260821**. KayKit remains the production mesh ecosystem.

## 1. Visual north star

A warm little civilisation survives in a world transformed by the Wyrd.

Day is the reward state: readable settlement, timber, work, roads. Dusk is apprehension. Night is a fragile pool of inhabited light. The Shard is the obsession. Binding is the visual/audio climax. Identity is carried by lighting, particles, banners, UI colour, and mix states — not lore dumps.

## 2. Wyrd treatment

Wyrd stays in the cyan/violet family and stays rare.

It appears on the Shard cluster, impact scar, revealed springs, active Outpost glow, Pressure meter, Binding chrome, and Reckoning atmosphere. It is not washed across the medieval settlement. Settlement materials stay timber, plaster, pale stone, and firelight.

## 3. Lumen treatment

Lumen is not yellow Wyrd. It is warm white / amber / firelight: windows, doorways, bakery oven, Watchtower lantern, civic gold roof accents, and a quiet night ambience layer. No giant magical circles were added.

## 4. Wyrd spring change

Revealed rivalry sites now spawn a local presentation node: darkened mineral basin, small cyan/violet crystals, restrained OmniLight, mist, and one floating fragment. Scale is local-anomaly, not Shard. Capture: `artifacts/phase4_1/screenshots/09_wyrd_spring.png`.

## 5. Shard change

The beacon is no longer one inverted prism in a bowl. It is a clustered silhouette (four crystals), taller thin column, layered mist + motes, irregular debris, and a dark impact scar. Binding raises pulse, column energy, and mote speed. The column remains the strategic-distance destination. Capture: `17_distant_shard.png`, `18_shard_impact_zone.png`, `21_reckoning.png`.

## 6. Impact-zone change

Terrain tint toward cold slate is stronger in the inner ring. Trees lean on two axes. Crater height is slightly irregular (floor bumps, asymmetric rim). Debris is offset rather than a regular circle. The story reads as a strike, not a tidy arena.

## 7. Rival visual identity

Rival Town Hall keeps the civic compound but uses wine cloth, umber roof accents, and a frontage shield. Rival structures get a banner pole + hanging cloth in addition to hue. Rival workers get a shoulder cloth plus banner (two cues). Barracks yard flags follow faction colour. This is dressing, not a second architecture pack.

Dedicated rival-TH hero framing is still weaker than player-town captures (see weaknesses).

## 8. Town Hall / settlement improvements

Player civic compound kept Phase 3.2 wings/plaza/steps and gained gold roof accents plus plaza goods. Chimney smoke plays on Bakery / Lumber / Sawmill when production is active, and on House / Town Hall / Bakery at night. Watchtower lanterns ignite at dusk/night. Outposts get a small Wyrd glow only while extracting.

## 9. Mid-game bustle proof

`production_demo_fixture.gd` stage `developed` now continues the real sim into quarry, second house, bakery, barracks, and watchtower, then forces daytime and clears enemies. Capture `05_busy_developed_settlement.png` is Day 2 with 14/15 population, carriers, lumber stacks, roads, and active workplaces. It is not posed ambient extras. A dawn toast from the fixture night still overlapped that capture; the fixture now also clears `dawn_summary`.

## 10. Day lighting

Authored day palette: warm sun `#ffe0a8`, sky `#5a88a8` → horizon `#d6c9a0`, saturation 1.06, sun pitch −52°. Capture `04_opening_settlement.png` / `05_busy_developed_settlement.png`.

## 11. Dusk lighting

Dusk is its own palette, not a linear night fade: warmer horizon `#e09a62`, sun pitch −12°, longer shadows, cooler fill, first building lights (adapter treats last 60s of day as lights-on). Capture `11_dusk.png` / `12_first_lights.png` plus the compact NIGHTFALL card.

## 12. Night lighting

Night palette: ambient 0.10, sun 0.06, cool fog `#1c2c40`, saturation 0.66. Wilderness loses information. Settlement keeps warm windows and lanterns. Capture `13_night_settlement.png`.

## 13. Reckoning presentation

Reckoning mixes night into a Wyrd-tinted climax (sky/fog toward violet-cyan, Shard pulse, Binding HUD elevated to `SHARD BINDING` + percent). Capture `21_reckoning.png`, `22_late_binding.png` (~78% progress).

## 14. Title screen

Live paused production world. Menu sits on the left: **SHARDS & SOVEREIGN**, thin Wyrd rule, subtitle, then NEW REALM / CONTINUE / SETTINGS / QUIT. Overlay alpha is 0.28 so the world remains visible. Title lighting is forced dusk. A presentation reveal corridor is authored toward the Shard so the background is not random unrevealed forest. Capture `01_title_screen.png`.

The composition is better than Phase 4’s random forest, but the beacon still does not always dominate the frame. That remains a weakness.

Hidden test nodes (`PlaytestStartMenu`, `NewReviewSeed`, `Legacy2D`, `SeedInput`) are preserved.

## 15. New Realm / settings

New Realm: **BEGIN** primary, Difficulty shown as **FRONTIER** (not a fake picker), seed under **ADVANCED**. Settings: Master / Music / Effects sliders (persisted `user://one_shard_audio.json`), visual quality, fullscreen. No dummy controls.

## 16. HUD architecture

Persistent: compact resource chips, population, time, Pressure meter, objective, speed/build.

Contextual: build palette, inspector, road/placement.

Urgent: dusk Nightfall card, raid/starvation toasts, Binding confirm, result screens.

Play chrome (`TopBar` / `LoopBar` only) hides on title and results so the world or the payoff can occupy the frame.

## 17. Pressure UI

`WyrdPressureMeter` is a narrow notched track, labelled QUIET / STIRRING / DANGEROUS / SEVERE / CRITICAL. QUIET does not pulse. CRITICAL jitters. Tooltip still carries the contributor breakdown. It is not a health bar.

## 18. Objective / UI

Objective is the macro title only (`SURVIVE` / `REACH THE SHARD` / `SECURE THE SHARD` / `BIND THE SHARD`). Detail lives on tooltip. During Binding the title becomes **SHARD BINDING** in Wyrd colour with percent as the primary readout.

Nightfall is an event card (visual + dusk sting) that fades; it is not a blocking modal.

Dawn remains a compact aftermath toast.

Binding confirm: cyan title, “The Wyrd will react violently.”, requirement line, Confirm/Cancel hierarchy.

## 19. Victory / defeat

Victory: **SHARD BOUND / REALM SECURED** over an in-engine Shard view, six curated stats, MORE STATS expander, NEW REALM / MAIN MENU.

Defeat: **THE REALM HAS FALLEN**, reason, same stats, TRY AGAIN / NEW REALM / MAIN MENU. No giant red overlay.

Posed `_finish_run` captures still show zeroed production stats. That is capture posing, not a live match.

## 20. Audio-state architecture

`production_audio_director.gd` crossfades stems for MENU / DAY / DUSK / NIGHT / RAID / RECKONING / VICTORY / DEFEAT. Buses: Master, Music, SFX, Ambience. Wyrd drone layers independently at springs/Shard/high Pressure/Binding. Work SFX are a 6-emitter 3D pool with concurrency 3 and a 36 m / strategic-zoom cutoff.

## 21. Day mix

Pastoral foundation + activity layer + wind/birds + quiet Lumen. Spatial chop/hammer only from active workplaces when the camera is close.

## 22. Night mix

Night percussion, reduced activity, Wyrd drone, Lumen hum near civilisation. Intentional quiet.

## 23. Raid mix

One enemy sting (not a looping alarm), metal combat stem, existing attack/tower one-shots.

## 24. Wyrd sonic identity

`wyrd_drone.wav`: low harmonic + crystalline modulation. Shared DNA for dusk, night, springs, Shard proximity, Reckoning. Intensity via bus volume, not a second family.

## 25. Reckoning audio

Enter cue `reckoning_pulse.wav`, then raid + Wyrd stems at higher targets.

## 26. Music implementation

All score is original mathematical synthesis from `tools/generate_presentation_audio.py` (project-owned). Not a commissioned soundtrack. Stems loop with crossfades; quiet gaps come from stem ducking, not a 90-second pop song on repeat. Dawn / victory / defeat are short motifs.

## 27. Audio license ledger

`docs/art/AUDIO_LICENSE_LEDGER.md` (also mirrored into `docs/AUDIO_ASSET_LEDGER.md`). Original synth only for new 4.1 cues. Legacy combat/build WAVs remain under existing third-party notices. No unverified/ripped audio.

## 28. Performance

Simulation profile (80 ticks, seed 260821):

| Phase | avg ms | p95 ms | max ms |
| --- | --- | --- | --- |
| Day | 0.406 | 0.286 | 16.937 |
| Night | 0.462 | 0.357 | 16.712 |
| Reckoning | 2.216 | 2.270 | 19.249 |

Capture-time FPS samples (Forward+, 1920×1080, vsync off, first frames of each staged shot) sat mostly **21–42**. Those numbers are not a cooked playtest profile; they are evidence the presentation still draws. OmniLights remain shadowless locals (windows, lanterns, revealed springs, Shard). Particles are gated to signature uses.

## 29. Screenshot paths

All 24 captures are 1920×1080 under `artifacts/phase4_1/screenshots/`:

| File | Subject |
| --- | --- |
| `01_title_screen.png` | Title |
| `02_new_realm.png` | New Realm |
| `03_settings.png` | Settings |
| `04_opening_settlement.png` | Opening settlement |
| `05_busy_developed_settlement.png` | Developed daytime settlement |
| `06_lumber_industrial.png` | Lumber / industry |
| `07_farm_bakery.png` | Farm / bakery |
| `08_outpost_expansion.png` | Outpost / Shard approach |
| `09_wyrd_spring.png` | Wyrd spring |
| `10_late_day.png` | Late day |
| `11_dusk.png` | Dusk + Nightfall |
| `12_first_lights.png` | First lights |
| `13_night_settlement.png` | Night settlement |
| `14_night_guards.png` | Night guards |
| `15_raider_approach.png` | Raider approach |
| `16_active_combat.png` | Combat |
| `17_distant_shard.png` | Distant Shard |
| `18_shard_impact_zone.png` | Impact zone |
| `19_contested_shard.png` | Contested Shard |
| `20_binding_confirmation.png` | Binding confirm |
| `21_reckoning.png` | Reckoning |
| `22_late_binding.png` | Late Binding ~75%+ |
| `23_victory.png` | Victory |
| `24_defeat.png` | Defeat |

## 30. Known weaknesses

- Title composition still fights FOW; the Shard beacon is not guaranteed as a background hero.
- Capture `05` was taken with a leftover dawn toast from the fixture night (now cleared in code, not recaptured).
- Raid/combat staged cameras often miss silhouettes (`15` / `16` are dark and sparse).
- Instant victory/defeat stats remain zeros because captures call `_finish_run` on a fresh seed.
- Resource chips use two-letter codes + colour, not illustrated icons.
- Rival Town Hall identity is implemented but under-represented in the capture set.
- Capture FPS samples are not a substitute for a long busy-settlement GPU profile.
- Music is original synth beds, not a final soundtrack.

## 31. Manual presentation playtest findings

A full live first day/night with speakers was not sat through as a human session. Review was capture inspection plus an automated mix-state walk (`tests/phase4_1_audio_evidence.gd`).

From that evidence:

| Question | Finding |
| --- | --- |
| Did title create curiosity? | **Partly.** Authored menu, dusk light, left-anchored type. World behind it is still a small revealed island. |
| Did it read as a real game? | **Yes** enough. Not a Godot boot/debug screen. |
| Pleasant settlement? | **Yes** in day/busy captures. KayKit remains, but districts and work are visible. |
| Did Wyrd look different? | **Yes.** Springs and Shard are cyan/mineral, not medieval props. |
| Did dusk change mood? | **Yes.** Horizon, lights, Nightfall card. |
| Did night feel threatening? | **Yes.** Dark wilderness, warm doorway pool. |
| Did audio distinguish time/state? | **Buses and stems do.** Human ear quality is unproven beyond that. |
| Was the world more important than UI? | **Mostly.** Chips are compact. Nightfall is the one large temporary exception. |
| Rival assets identifiable? | **Implemented, under-captured.** |
| Did the Shard pull the eye? | **Yes** at impact and Reckoning. **Weaker** on the title. |
| Did Binding look/sound like a climax? | **Yes** in confirm + Reckoning captures and the reckoning cue. |

Automated audio states observed:

`menu` → `day` → `dusk` (nightfall cue) → `night` → `raid` (enemy cue) → `reckoning` (pulse) → `victory` → `defeat`.

## Acceptance gate

Without reading body text, screenshots distinguish Day, Dusk (Nightfall + lights), Night, Wyrd (springs/Shard), the Shard, and Binding/Reckoning. Rival is the weakest of those distinctions in the capture set.

Without watching, the mix-state harness can tell Day / Night / Raid / Reckoning apart by which stems are up.

First 30 seconds: the title is an authored game menu over a live dusk world, not an engineering overlay.

## Headless / capture commands

```
python .\tools\generate_presentation_audio.py
.tools\godot-4.7\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/phase4_1_parse_smoke.gd
.tools\godot-4.7\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/phase4_wyrdfall_smoke.gd
.tools\godot-4.7\Godot_v4.7-stable_win64_console.exe --path . --rendering-method forward_plus --resolution 1920x1080 --user-data-dir artifacts/phase4_1/isolated_user --script res://tests/phase4_1_capture_suite.gd
.tools\godot-4.7\Godot_v4.7-stable_win64_console.exe --path . --rendering-method forward_plus --resolution 1920x1080 --user-data-dir artifacts/phase4_1/isolated_user --script res://tests/phase4_1_audio_evidence.gd
.tools\godot-4.7\Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/phase4_performance_sample.gd
```

Playtest launch is unchanged: `Play SnS 3D.bat` (Forward+).

## Final result

**PASS — ready for serious human fun/balance playtest**
