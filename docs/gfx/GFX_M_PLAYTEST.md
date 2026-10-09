# GFX-M self-playtest notes

Harness: `tests/t_gfx_m_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). Covers the first **15 game
minutes** (opening, build, scout, first night, raid).
`SNS_PLAYTEST_LOG=1` also wrote `artifacts/gfx_m/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_m_playtest.csv`  
Comparison cameras: `tests/t_gfx_m_shots.gd` → `artifacts/gfx_m/after/`.  
CONCEPT vs NOW / GFX-L vs GFX-M:
    `/opt/cursor/artifacts/gfx-m/concept_vs_now_*.png` and
`gfxl_vs_gfxm_*.png`.

Master bus stayed `1.000`. Scout result:
`Bjorn scouts toward the fog.` Build road / house: **true / true**.
Showcase buildings / roads: **16 / 60** (playtest) and **15 / 60**
(shots). Script errors: **0**.

Stacked on GFX-L (`a21f0d4`, PR #69, ChatGPT **6.7/10**). Day grade
knobs (sat 1.12 / contrast 1.12 / exposure 0.86) were **frozen**.
L/K fog / forest / wheat / night stay.

W = Town Hall 4×4 = **10.0 m**. R = cell × 0.97 = **2.425 m**.
H = house visual height ≈ **4.09 m**.

## Script

1. Fresh opening hamlet + ridge / creek, camera on
   `opening_camera_focus()` at zoom 26.
2. Place a road off the hall entrance and a house two tiles east.
   Both `request_build` calls succeeded.
3. Spawn / select a free patrol guard and issue Scout (Y) toward the
   western fog. Result: `Bjorn scouts toward the fog.`
4. Advance through the rest of day 1 (`DAY_LENGTH_SECONDS` 420) into
   first night, then spawn two raiders and capture the RAID banner.
5. Advance through night + remainder so `elapsed_seconds` ≥ 900
   (~15 game minutes), then stamp the showcase and pull back to the
   **1.5× zoom cap** (39).

No scout / guard / raider outline files were touched.

## Per-item (plan order)

| item | result | notes |
| --- | --- | --- |
| 0 Revert + freeze | **Pass** | Oversized pale foreground rocks removed. Town Hall foundation inset 0.88 and ≤ 0.05B. Creek retinted `#315D62` / roughness 0.32. Grade knobs untouched. |
| 1 Rock / foundation scale | **Pass** | Ridge rocks 0.15–0.55B wide, ≤ 0.35H, albedo `#8E8C78` / `#B4AA92` / `#626B61`, r 0.92, parked on forest flanks. |
| 2 Road network | **Partial** | Centre `#AB8963`, raised 0.110, showcase 60 road tiles + extra spokes. At zoom 26 the lanes still sit close to the pale meadow and do **not** read as the concept's unmistakable clay network. |
| 3 Modular .glb buildings | **Pass** | Live catalog: KayKit Medieval Hexagon `building_castle_green` / `building_home_A_green` / `building_lumbermill_green`, remapped toward plaster `#DDCAA8`, limestone `#C8BA9C`, timber `#5F422E`, slate `#426B66`. Still a dark teal castle vs the concept's warm limestone keep. |
| 4 1024² terrain textures | **Partial** | Poly Haven CC0 1K diffs in the splat shader (meadow / forest / dirt / rock), tinted toward `#526B40`. On lavapipe the floor reads brighter and sandier than L (showcase luma 86.8 vs 75.9), not the concept's lush olive. |
| 5 Ridge + curved creek | **Pass** | 8 bevelled masses + KayKit debris on the flanks. Curve3D water `#315D62`, shallow `#638D86`, banks `#8A7658`. Less visible at the opening camera than the hall. |

Licences: `docs/ASSET_LICENSES.md`. No Quaternius files were imported.
ambientCG 1K packs were downloaded as a fallback and are **not** shipped.

## Frame / wait times (lavapipe, not a 4070)

| event | wait_ms | frame_ms | night | errors | notes |
| --- | ---: | ---: | ---: | ---: | --- |
| opening_day | 9404 | 216.4 | 0 | 0 | ridge / creek landmark |
| build_day | 2985 | 225.1 | 0 | 0 | road + house placed |
| scout_day | 5173 | 236.3 | 0 | 0 | `Bjorn scouts toward the fog.` |
| first_night | 3152 | 183.9 | 1 | 0 | first night inside the window |
| night_raid | 2128 | 197.2 | 1 | 0 | RAID banner, moonlit blue |
| fifteen_minutes | 3011 | 265.6 | 0 | 0 | elapsed 901.6 s |
| showcase_day | 4053 | 316.6 | 0 | 0 | 16 buildings / 60 roads |
| showcase_wide | 4298 | 381.4 | 0 | 0 | 1.5× cap (39) |
| fog_edge | 4315 | 377.4 | 0 | 0 | zoom 39, **day** |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan.

## Perf guard (same machine)

| step | GFX-L lavapipe | lavapipe GFX-M cold | lavapipe GFX-M warm |
| --- | ---: | ---: | ---: |
| `start_new_3d` | 460 ms | **452 ms** | **462 ms** |
| showcase `_sync_presentation` | 541 ms | **585 ms** | **587 ms** |
| first frame after showcase | 2033 ms warm | 7580 ms | **1616 ms** |

`T_GFX_E_PERF` PASS. `T_GFX_PERF` PASS (`GFX_PERF_DONE`: day 222 /
dusk 221 / night 188 / first-view 166 ms). Start stays inside 2×
GFX-D (1000 ms). Helmer's first-frame gate is **< 3 s**: the warm
lavapipe first frame is **1.62 s**. The 7.6 s cold number is shader
compile on llvmpipe, not a GDScript rebuild.

## Tests

| test | result |
| --- | --- |
| `t_gfx_m` | PASS |
| `t_gfx_m_playtest` | PASS (15 game minutes, errors=0) |
| `t_gfx_m_shots` | PASS |
| `t_gfx_l` | PASS |
| `t_gfx_k` | PASS |
| `t_gfx_j` | PASS (stone `#635B4C` accepted) |
| `t_gfx_i` | PASS |
| `t_gfx_h` | PASS |
| `t_gfx_g` | PASS |
| `t_gfx_f` | PASS |
| `t_gfx_e` | PASS (first MeshInstance3D, KayKit volume) |
| `t_gfx_e_perf` | PASS |
| `t_gfx_d` | PASS (first MeshInstance3D, KayKit volume) |
| `t_gfx_light` | PASS |
| `t_gfx_b` | PASS |
| `t_gfx_c` | PASS (first MeshInstance3D, KayKit volume) |
| `t_gfx_perf` | PASS (`GFX_PERF_DONE`) |
| `opening_style_models` | PASS |
| `phase4_2_parse_smoke` | PASS |
| `audit_export_packing.py` | PASS (`MISSING FROM EXPORT: 0`) |

## 3D-area metrics (HUD cropped, lavapipe)

`luma / luma_std / sat / hue` — same crop for L and M this run.

| shot | CONCEPT | GFX-L | GFX-M |
| --- | --- | --- | --- |
| opening_day | 79.6 / 51.4 / 0.412 / 52° | 67.3 / 49.4 / 0.397 / 62° | 71.0 / 57.8 / 0.335 / 67° |
| showcase_day | 78.6 / 50.3 / 0.389 / 55° | 75.9 / 50.5 / 0.449 / 47° | 86.8 / 59.5 / 0.383 / 45° |
| showcase_wide | 79.6 / 51.4 / 0.412 / 52° | 73.9 / 46.6 / 0.276 / 68° | 81.3 / 53.5 / 0.231 / 67° |
| fog_edge | — | 68.7 / 45.8 / 0.269 / 93° | 73.0 / 53.2 / 0.219 / 97° |
| night_raid | — | 44.2 / 25.2 / 0.059 / 160° | 47.1 / 28.2 / 0.070 / 188° |

Hue was not retuned (grade frozen). Showcase luma jumped ~11 points
because the Poly Haven meadow reads brighter / sandier than L's olive
splat. Saturation dropped on the wide / fog cameras. The concept is
still a denser, greener, higher-contrast Nordic diorama with a brown
road lattice the lavapipe board does not match.

## Playability gates

| gate | result |
| --- | --- |
| No crashes / script errors | **Pass** — playtest `errors=0` |
| First frame < 3 s | **Pass** — warm lavapipe **1616 ms** |
| All tests + perf guard | **Pass** |
| Export MISSING | **0** |
| Master bus | **1.000** |
| 15-minute self-playtest | **Pass** — opening, build, scout, first night, raid |

## Strict self-score

**7.1 / 10** on lavapipe. Helmer's holiday bar is **≥ 8/10**. I am
not calling 8. ChatGPT held L at 6.7 and projected M at 7.0–7.3 for
corrections + roads, 7.4–7.8 only if architecture and textures
actually read. Against `concept_1.png` the board now has a real
KayKit Hexagon castle / cottage / mill instead of opening-style
boxes, the foam rocks and bunker plinth are gone, and the creek is
dark water. Roads still do not announce themselves at zoom 26. The
1024² splat lifts luma and washes the meadow toward sand, not lush
olive. That is a half-step from L, inside the 7.0–7.3 band, not an
8. A 4070 shot may add a quarter-step of shadow and texture. Do not
merge on this score.

## Five acceptance tests

| test | lavapipe |
| --- | --- |
| 1 Rock / foundation scale | Pass — flanks, 0.15–0.55B, ≤ 0.35H, foundation ≤ 0.05B |
| 2 Unmistakable road network | Partial — 60 tiles / `#AB8963`, still faint on the pale floor |
| 3 Modular CC0 .glb hall / house / workshop | Pass — KayKit Hexagon live catalog, concept palette remap |
| 4 Real 1024² terrain in the splat | Partial — Poly Haven 1K bound; reads sandy, not lush |
| 5 Ridge + curved creek / shoreline | Pass — Curve3D `#315D62` r 0.32 + 8 bevelled + CC0 rocks |
