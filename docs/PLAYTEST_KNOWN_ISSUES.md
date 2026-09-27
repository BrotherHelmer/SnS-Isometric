# Internal candidate limitations

Build: 0.2.0-playtest.25

- This candidate is not yet cleared for public Steam release. Steamworks setup and IDs are deferred at the owner's request.
- Human first-session comprehension, unassisted full-match wins/losses, integrated-GPU performance and clean physical Windows-machine testing remain external gates.
- The prior playtest.1 build passed a clean 60-minute rerun after an earlier Windows audio-device invalidation. Playtest.25 awaits its own hour-long soak and audible device-reconnection check.
- Nineteen opening-style model scenes, coordinated terrain/lighting and character materials are integrated. This is a stylized adaptation; animated character geometry is retained. Lower-end performance with the new geometry remains unmeasured.
- The three-seed command-only bot now completes all three matches, including mid-Binding save/reload. Human strategy, difficulty and session length remain unvalidated.
- The intended 35–55 minute session length is provisional. Automated checks and accelerated simulations do not establish whether the game is fun or well paced.
- Controller, Steam Deck, Linux, achievements and Steam Cloud are not advertised as supported. The Windows renderer is Forward+; Compatibility is an unverified fallback.
- Asset provenance records cover the KayKit runtime, project-synthesised audio and pre-generated AI title illustration; final branding and the exact distribution manifest still need owner sign-off before public publication.
- Supported save formats are versions 6–8. Test copies of real historical saves before relying on migration for a public update. A save written by a future build is rejected.
- The restricted development environment cannot read the Windows certificate store. An unrestricted save-safety run is clean; this exact environment error is recorded separately from game failures.

See `docs/RELEASE_EXECUTION_STATUS.md` in the project for current validation results and remaining work.

## Recent UX Improvements (post-playtest.4)

**Placement Legend Visibility** (playtest.20): Legend now stays visible during building placement. Color meanings ("GREEN = valid · YELLOW = needs clearing · RED = blocked") shown persistently on one line while dynamic status ("VALID · Can place here" or actionable error) updates on second line. Before playtest.20, the legend was overwritten by the status when hovering over tiles, making it hard to learn color meanings.

**Placement Clarity & Zoom** (playtest.19): Building placement now shows color-coded feedback directly on the ghost footprint with legend. Validation errors are more actionable ("No road access. Extend roads from Town Hall first..." instead of vague messages). Camera zoom range reduced (max 68 vs 85) and scroll step smoothed (3.5 vs 4.0) to prevent accidentally zooming to "lost" speck view. Town Hall now has taller civic tower and wider footprint for clearer distinction from Houses at founding.

**Early Defense** (playtest.6): Increased initial fog-of-war reveal radius (8→12 tiles) around the starting Town Hall. Players can now place a Watchtower in a sensible spot near the Town Hall during Day 1, before the first night raid arrives.

**Road Connectivity**: Improved error messages now explicitly guide players to extend roads from the Town Hall before placing buildings. Valid placement areas are highlighted through the existing build pads system when a building type is selected.

**Food & Storage**: Increased starting Bread (12→18) and Town Hall storage overflow (8→20) to provide better early-game breathing room. Added Storehouse and Watchtower to early objectives. Storage-full warnings now include hints about the Farm→Bakery→Storehouse chain.

**Night Readability**: Improved night lighting visibility (ambient 0.38→0.50, sun energy 0.24→0.35, fill energy 0.24→0.32) while maintaining atmospheric mood. First-night warning now specifically mentions defensive buildings if no Watchtower exists. Reduced attack notification spam.

**Combat & Building UX** (playtest.7):
- **Shard Direction Cue**: Removed the on-screen `▲ SHARD` direction indicator to prevent revealing shard bearing before discovery.
- **Placement Markers**: Expanded build pad scanning radius (5→8 tiles) to cover more valid placement locations, including sites eligible for auto-spur road connections.
- **Watchtower Combat**: Unmanned watchtowers are now treated as lower-priority targets by enemies (same as other buildings). Enemies will damage unmanned towers normally. Tower guards properly engage enemies instead of fleeing.
- **Guard UI**: Removed "Carrying" field from guard inspection panels, as tower guards and patrol soldiers do not haul resources.
- **Occupancy Indicators**: Buildings now show subtle daytime occupancy hints (window emission changes) when staffed or garrisoned, making it easier to identify which buildings are active.
- **C&C-Style Building Bar**: Added a bottom-screen building miniatures strip showing all buildable types for quick access, complementing the existing categorized BUILD palette.

**Visual & UX Polish** (playtest.8):
- **Camera Stability**: Removed automatic camera jump to shard area that could reveal shard location prematurely. Camera stays on settlement unless player deliberately pans.
- **Building Identity**: Made buildings more visually distinct at a glance:
  - **Lumber Camp**: Added tent marker and rustic camp props vs industrial sawmill
  - **Sawmill**: Added circular saw blade with teeth and organized plank stacks
  - **Farm**: Added sheep in paddock, fence posts, and clear agricultural identity
  - **Barracks**: Enhanced military appearance with armor stand, entry banner, and martial features
  - **Town Hall → Castle**: When Barracks is built, Town Hall visually upgrades to Castle with turrets, crenellations, and royal banner
- **C&C Bar Icons**: Replaced plain color blocks with visual building icons (house silhouette, saw blade, shield/spear, etc.)
- **Build Tooltips**: Bottom bar building buttons now show tooltips with what the building does + resource costs on hover
- **Resource Icons**: Replaced colored resource bars with distinctive icons (log for wood, wheat stalks, stone, bread loaf, crystal for wyrd, etc.)
- **Audio**: Placeholder audio generation script added (Issue #6 - proper CC0/libre SFX still needed for production)
