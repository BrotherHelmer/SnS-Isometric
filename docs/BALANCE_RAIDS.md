# Raid balance

All raid numbers live in `src/GodotClient/Scripts/one_shard_raid_tuning.gd`.
The wave planner (`one_shard_wyrdfall.gd`) and the simulation read those
constants. Defender shot size is unchanged (`GUARD_DAMAGE` 4, `TOWER_DAMAGE` 5)
so existing cadence tests still describe the same soldier and Watchtower swing.

## Why the playtest felt harmless

Night 1 used to spawn two 16 HP / 2 damage raiders with no armour. A staffed
Watchtower deletes one of those in three bolts (~6.6 s). They also never
targeted a Storehouse (zero staff, so it was skipped), and razing a building
returned its cargo to the Town Hall. The raid was a noise event.

## Published numbers

| Wave | Size | HP | Armour | Damage | Steal / storage hit | Notes |
|---|---|---|---|---|---|---|
| Night 1 | 2 | 40 | 1 | 4 | 1 | Teaching wave. Retreats at 72 s. Cannot raze the Town Hall (500 HP) before dawn. |
| Night 2 | 5 | 24 | 1 | 5 | 2 | First real raid. Roster still mixes Raiders and Marauders. |
| Later | 3–10 | 24 + 4×(day−2), +4 Severe / +8 Critical | 1, +1 Critical | 5 + 2×⌊(day−1)/3⌋ | 2 | Pressure still grows the count and the roster. |

Archetype multipliers still apply on top (Marauder 0.58× HP / 0.70× damage,
Brute 2.35× HP / 1.75× damage / +1 armour, Hexer 0.82× HP / 0.75× damage).

Incoming damage is `max(1, raw − armour)`. A soldier therefore deals 3 to a
Night 2 Raider; a Watchtower bolt deals 4.

Raiders siege loot (Storehouse, bakery, camps) after manned towers and gates,
then soldiers. Each storage hit steals available (not reserved) stock, bread
first. Wyrd is never stolen — it is Lumen fuel, not cargo. A building
destroyed during an active raid loses its local inventory instead of dumping
it back into the hall.

## Time-to-kill

First-strike delay is the published animation window (soldier 0.24 s, raider
0.28 s, Watchtower bolt flight 0.65 s). Later hits use the published interval.

### Our side versus one Night 2 Raider (24 HP, armour 1)

| Attacker | Damage after armour | Interval | Hits to kill | Time |
|---|---|---|---|---|
| 1 patrol soldier | 3 | 1.55 s | 8 | 11.1 s |
| 1 staffed Watchtower | 4 | 2.2 s | 6 | 11.7 s |
| Watchtower + 1 soldier | 3 + 4 | — | — | ~6.9 s (5.69 DPS) |
| Watchtower + 2 soldiers | 3+3+4 | — | — | ~4.2 s per Raider; **~21 s for a five-Raider wave** |

A Night 1 Raider (40 HP, armour 1) takes 10 Watchtower bolts (~20.5 s) or 14
soldier swings (~20.4 s). Two of them last a teaching night against one tower.

### Their side versus us

| Target | HP | 1 Raider (5 dmg / 1.6 s) | 3 Raiders (load cap) |
|---|---|---|---|
| Soldier | 40 | 11.5 s | 4.5 s |
| House | 80 | 24.3 s | 8.5 s |
| Storehouse | 220 | 70.7 s | **23.5 s** |
| Watchtower | 300 | 96.3 s | 32.0 s |
| Town Hall | 500 | 160 s | 53.3 s |

Night 1 (4 dmg, 2 raiders, 72 s retreat) deals at most 360 HP if they stay on
the Town Hall — it stands, but an undefended yard loses stock and a House can
fall.

## Intended read

- **Undefended:** three Night 2 Raiders on a Storehouse destroy it in ~24 s and
  empty bread / wood as they hit. The Town Hall still survives a single night.
- **Defended (staffed Watchtower + two Barracks patrols):** the five-Raider
  Night 2 wave dies in about 21 s. The Storehouse and tower take damage; nothing
  is razed.

Headless proofs: `tests/t_raid_combat.gd` (both scenarios) and
`tests/t_raid_combat_log.gd` (Log lines + RAID OVER summary).
