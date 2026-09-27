# Playtest.7 Remaining Art & Audio Work

This document tracks art and audio improvements identified from Helmer's playtest.6 feedback that require asset generation or sourcing beyond code changes.

## Audio Improvements (Priority: High)

### Current State
The current SFX use placeholder/early audio that lacks the clarity and charm of classic colony sim audio (reference: Settlers II Amiga).

### Required Changes

**Goal**: Modern CC0/libre audio with Settlers II-style clarity and charm for settlement activities.

**Specific Sounds Needed**:
1. **Build Start** (`build_start.wav`) - Hammer/construction beginning
2. **Build Complete** (`build_complete.wav`) - Satisfying completion chime
3. **Delivery** (`delivery.wav`) - Resource dropoff confirmation
4. **Road** (`road.wav`) - Road construction
5. **Attack** (`attack.wav`) - Combat hit/impact
6. **Tower** (`tower.wav`) - Watchtower projectile fire
7. **Enemy** (`enemy.wav`) - Enemy spawn/appearance
8. **Night** (`night.wav`) - Nightfall warning sting
9. **Soldier** (`soldier.wav`) - Military unit feedback
10. **Destroyed** (`destroyed.wav`) - Building destruction

**Sourcing Requirements**:
- Must be CC0, MIT, or other clearly-licensed libre audio
- NO ripping from Settlers II or other copyrighted games
- Options:
  - [Freesound.org](https://freesound.org) (filter by CC0 license)
  - [OpenGameArt.org](https://opengameart.org) audio section
  - Generate procedurally with sfxr/jsfxr/ChipTone for retro-style SFX
  - Commission original short SFX (max 1-2 seconds each)

**Technical Specs**:
- Format: WAV, 44.1kHz or 48kHz, 16-bit
- Length: 0.3s - 2.0s typical
- Style: Clear, punchy, not muddy
- Volume: Normalized, consistent levels

**Asset Ledger**:
Update `docs/art/ASSET_LEDGER.md` with new audio sources, licenses, and dates.

## Building Visual Distinctiveness (Priority: Medium)

### Current State
Many buildings (especially houses, farms, lumber camps) look similar due to shared half-timber + green roof aesthetic.

### Required Changes

**Goal**: Each building type should be instantly recognizable by silhouette, color, or prominent feature.

**Specific Improvements**:

1. **Town Hall** - Already distinct (larger, civic wings). ✓

2. **House** - Current green roof is fine for basic housing.
   - Suggestion: Vary roof hue slightly (olive/teal) or add chimney variations

3. **Lumber Camp** - Needs clear wood-industry identity
   - Add: Visible log pile, axe rack, or sawdust/wood-chip ground scatter
   - Roof: Consider brown/amber thatch instead of green

4. **Quarry** - Should show stone/mining
   - Add: Rock pile beside building, pickaxe display
   - Material: More stone in walls vs timber

5. **Farm** - Agricultural identity
   - Add: Visible wheat bundle, plow, or field-edge fence
   - Roof: Keep green (matches fields) or use warm amber

6. **Sawmill** - Industrial wood processing
   - Add: Gear/waterwheel silhouette, plank stacks
   - Roof: Dark brown or grey (industrial, not agricultural)

7. **Bakery** - Food production
   - Add: Prominent chimney with smoke even during day
   - Roof: Red/terracotta tiles to distinguish from green agricultural roofs

8. **Barracks** - Military training
   - Add: Weapon rack, training dummy, banner
   - Roof: Red or grey (martial, not civilian green)

9. **Watchtower** - Already distinct (tall, defensive). ✓

10. **Storehouse** - Large storage
    - Add: Visible goods/barrel stacks outside
    - Make building larger or double-wide to show capacity

**Implementation Path**:
- Update procedural geometry in `tools/build_opening_style_models.gd`
- OR: Hand-edit `.res` mesh files in Blender/3D tool, re-export
- Document changes in `docs/art/OPENING_STYLE_MODELS.md`
- Update model manifest checksums

**Color Palette Suggestion**:
- Civic: Green roof (Town Hall, House, Storehouse)
- Agricultural: Warm amber/wheat (Farm)  
- Industrial: Brown/grey (Lumber, Sawmill, Quarry)
- Military: Red/grey (Barracks, Watchtower)
- Service: Terracotta/red (Bakery)

## Implementation Status

- [x] Code fixes (shard compass, placement, combat, UI) — Complete
- [ ] Audio replacement — **Needs asset sourcing/generation**
- [ ] Building visual improvements — **Needs 3D modeling work**

## Next Steps

1. **Audio**: Generate or source CC0 SFX, test in-game, update ledger
2. **Buildings**: Prioritize Lumber/Sawmill/Bakery/Barracks for distinct silhouettes
3. **Test**: Verify readability improvements in playtest.7+ builds
