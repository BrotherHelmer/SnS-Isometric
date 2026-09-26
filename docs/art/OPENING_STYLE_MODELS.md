# First playable opening-style model set

Build: 0.2.0-playtest.4. Adapted from the approved opening-screen art kit.

## In the game

Six replacement buildings: Town Hall, House, Storehouse, Lumber Camp, Bakery and Watchtower. Farm uses the house, Sawmill uses the lumber camp and rival Outposts use the watchtower. Forests and rock deposits use new fir, broadleaf and rock meshes. The founding yard includes the new fence, lantern and cart.

These are real three-dimensional meshes with geometry on every side, native Godot materials, emissive windows and normal shadows. They support existing building rotation, construction/completion, selection, ownership banners, damage feedback, logistics sockets and saved games. Nature remains batched through the existing MultiMesh renderer. No additional simulation entities or resources are created by decorative props.

The town hall's visual bounds are now 6 × 7.4 × 5.6 metres; its authoritative 4 × 4-cell footprint is unchanged. Other building bounds retain their existing presentation sizes. Semantic sockets derive from the same profile.

## Source and rebuilding

- Source: `tools/build_opening_style_models.gd`.
- Output: `assets/settlement3d/runtime/opening_style/`, nineteen `.tscn` scenes with corresponding `.res` meshes and a model manifest.
- Run the generator with the pinned Godot 4.7 engine in headless mode and isolated APPDATA, then run the normal release build. Regeneration is deterministic.
- Geometry is merged into one mesh per asset with material surfaces. Per-model triangle and material-surface counts are recorded in model_manifest.json. Material surfaces remain a performance cost to measure on lower-end hardware.
- The generated roof/ground bitmap prototypes are not used: this set uses geometric roof shingles and authored material colours.

## Validation and scope

`tests/opening_style_models.gd` checks loaded bounds, grounding, selection areas, delivery sockets, construction-to-completion transitions and the single-mesh structure required by nature instancing. In rendered mode it also captures `artifacts/opening_style/model_gallery.png` for visual review. The normal release suite includes this check.

This is a first playable low-poly adaptation, not a reconstruction of the illustration's full detail. The follow-up pass covers Quarry, Barracks, Lumen Pillar, rival camp, wall crenellations, grass, bushes and wheat. Terrain uses muted procedural meadow variation; figures use a shared cloth-palette shader while keeping the tested rigs. Day, dusk and night lighting, roads and fog now follow the same palette. This remains a stylized interpretation rather than identical image detail. No claim of lower-end performance or final art approval is made by this update.

## Environment follow-up — playtest.4

Terrain colour is supplied in linear space to its world-coordinate material, removing the overly bright green vertex-colour treatment. Broad and fine procedural variation reduces repeated flat-colour tiles. New grass/bush meshes replace bright vendor foliage; farm beds and carried wheat use authored wheat geometry. Fog colours are darker and cooler; visibility and reveal rules are unchanged.

Characters receive cached palette materials that mute green/cyan clothing while preserving skin, leather, steel, skeletons, tools and animations. Rival/hostile identification markers remain separate. All material changes operate on instances; vendor assets remain intact.

Daylight pairs warm sunlight with a cooler ambient fill. Dusk uses restrained atmospheric haze, and night retains readable blue-green ground with warm windows. Recommended quality enables ambient occlusion and 2x edge antialiasing; Scalable Low disables both. Roads use a shared day/night-tinted unshaded material to avoid near-ground lighting artifacts. They do not receive local cast shadows. Roof shingles are stepped to avoid coplanar overlap; wall arms now extend in their actual connection direction and carry stone crenellations.

Lighting review captures use one paused saved settlement under explicit day/dusk/night palettes; the HUD's original saved phase is not changed. These are presentation comparisons, not evidence of a naturally elapsed whole day. `tests/settlement_style_capture.gd` records them and performs a headless terrain/rig smoke check. New model bounds and construction checks cover the added building families.

Lower-end performance, human readability and final artistic polish still require playtesting. Animated character geometry is retained, not rebuilt from the illustration.
Rendered lighting check: the sampled world region measured mean display luminance 0.4012 by day, 0.1913 at dusk and 0.1076 at night (night/day about 0.27). The capture check requires night to remain above 0.02 and below 60% of day. These measurements support this scene only, not all monitors or player accessibility needs. The older fixed sun-energy threshold was updated to a relative 25%-of-day limit for the intentional new palette.
