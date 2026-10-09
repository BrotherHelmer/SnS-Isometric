# GFX-N self-playtest notes

Harness: `tests/t_gfx_n_playtest.gd` on Godot 4.7 Forward+ via Xvfb +
lavapipe. Seed = `DEFAULT_SEED` (260821). Covers the first **15 game
minutes** (opening, build, scout, first night, raid).
`SNS_PLAYTEST_LOG=1` also wrote `artifacts/gfx_n/playtest/dpm.csv`.

CSV: `docs/gfx/gfx_n_playtest.csv`  
Comparison cameras: `tests/t_gfx_n_shots.gd` → `artifacts/gfx_n/after/`.  
CONCEPT vs NOW / GFX-M vs GFX-N:
    `/opt/cursor/artifacts/gfx-n/concept_vs_now_*.png` and
`gfxm_vs_gfxn_*.png`.

Master bus stayed `1.000`. Scout result:
`Bjorn scouts toward the fog.` Build road / house: **true / true**.
Showcase buildings / roads: **16 / 60** (playtest) and **15 / 60**
(shots). Script errors: **0**.

Stacked on GFX-M (`83670a8`, PR #70, ChatGPT **6.8/10**). Day grade
knobs (sat 1.12 / contrast 1.12 / exposure 0.86) were **frozen**.
Meshes / texture system / creek / forest / night stay. Green roofs,
sandy terrain colours, and pale meadow rocks were reverted.

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
| 1 Lush green terrain | **Partial** | Meadow uniform `#556D3F`, tex_mix 0.20, roughness 0.94. Poly Haven maps are luminance only. On lavapipe the sunlit lawn still reads khaki (opening mid-lawn g−r ≈ 0, luma 75) vs concept olive. Darker moss authoring did not beat the frozen Filmic + `#FFE8CE` sun. |
| 2 Unmistakable roads | **Partial** | Magenta `set_road_debug` is bound (`road_debug=1.0`). 512² union mask bakes a connected three-route network (`pkg2_road_control.png`, 5659 nonzero texels). On-board magenta did not read through lavapipe sampling, so the clay `#AE906D` lattice is still the raised mesh + splat, not an unmistakable concept road. |
| 3 KayKit remap | **Pass** | Hexagon castle / home / lumbermill kept. Remap shader: limestone `#CDBD9F`, plaster `#DFCBA9`, timber `#60432E`, muted teal `#426B68`, terracotta `#A96343`. No emerald. Town Hall is light limestone. |
| 4 Rocks + creek | **Pass** | Ridge `#898776` / `#B6AC94` / `#5E655B`, meadow rocks hidden. Curve3D water `#345E64`, r 0.35, banks `#847257`. |
| 5 Clustered groundcover | **Pass** | 4–5 tufts at forest edges, 3 at yards, sparse meadow centre. |

Licences: `docs/ASSET_LICENSES.md` (Kaykit remap row). No Quaternius
files were imported.

## Frame / wait times (lavapipe, not a 4070)

| event | wait_ms | frame_ms | night | errors | notes |
| --- | ---: | ---: | ---: | ---: | --- |
| opening_day | 7981 | 214.6 | 0 | 0 | ridge / creek landmark |
| build_day | 2735 | 202.5 | 0 | 0 | road + house placed |
| scout_day | 5000 | 212.0 | 0 | 0 | `Bjorn scouts toward the fog.` |
| first_night | 3114 | 191.3 | 1 | 0 | first night inside the window |
| night_raid | 2127 | 191.6 | 1 | 0 | RAID banner, moonlit blue |
| fifteen_minutes | 2865 | 238.2 | 0 | 0 | elapsed 901.6 s |
| showcase_day | 3987 | 305.4 | 0 | 0 | 16 buildings / 60 roads |
| showcase_wide | 4239 | 367.7 | 0 | 0 | 1.5× cap (39) |
| fog_edge | 4189 | 366.4 | 0 | 0 | zoom 39, **day** |

`wait_ms` is wall time for 12 process frames + one `frame_post_draw`.
`frame_ms` is `Performance.TIME_PROCESS` on software Vulkan.

## Perf guard (same machine)

| step | GFX-M lavapipe warm | lavapipe GFX-N cold | lavapipe GFX-N warm |
| --- | ---: | ---: | ---: |
| `start_new_3d` | 462 ms | **650 ms** | **646 ms** |
| showcase `_sync_presentation` | 587 ms | **668 ms** | **669 ms** |
| first frame after showcase | 1616 ms warm | 6510 ms | **1503 ms** |

`T_GFX_E_PERF` PASS. `T_GFX_PERF` PASS (`GFX_PERF_DONE`: day 206 /
dusk 195 / night 170 / first-view 158 ms). Start stays inside 2×
GFX-D (1000 ms). Helmer's first-frame gate is **< 3 s**: the warm
lavapipe first frame is **1.50 s**. The 6.5 s cold number is shader
compile on llvmpipe, not a GDScript rebuild.

## Tests

| test | result |
| --- | --- |
| `t_gfx_n` | PASS |
| `t_gfx_n_playtest` | PASS (15 game minutes, errors=0) |
| `t_gfx_n_shots` | PASS |
| `t_gfx_m` | PASS |
| `t_gfx_l` | PASS |
| `t_gfx_k` | PASS |
| `t_gfx_j` | PASS |
| `t_gfx_i` | PASS |
| `t_gfx_h` | PASS |
| `t_gfx_g` | PASS |
| `t_gfx_f` | PASS |
| `t_gfx_e` | PASS |
| `t_gfx_e_perf` | PASS (cold + warm) |
| `t_gfx_d` | PASS |
| `t_gfx_light` | PASS |
| `t_gfx_b` | PASS |
| `t_gfx_c` | PASS |
| `t_gfx_perf` | PASS (`GFX_PERF_DONE`) |
| `opening_style_models` | PASS |
| `phase4_2_parse_smoke` | PASS |
| `audit_export_packing.py` | PASS (`MISSING FROM EXPORT: 0`) |

## 3D-area metrics (HUD cropped, lavapipe)

`luma / sat` — same crop boxes for M and N this run.

| shot | GFX-M mid-lawn | GFX-N mid-lawn |
| --- | --- | --- |
| opening_day | 70.0 luma, g−r +4.8 | 75.3 luma, g−r +0.2 |
| showcase_day | 101.6 luma, g−r +3.4 | 115.4 luma, g−r −2.9 |

Hue was not retuned (grade frozen). N's limestone hall lifts luma.
The meadow did **not** become the concept's lush olive on lavapipe.

## Playability gates

| gate | result |
| --- | --- |
| No crashes / script errors | **Pass** — playtest `errors=0` |
| First frame < 3 s | **Pass** — warm lavapipe **1503 ms** |
| All tests + perf guard | **Pass** |
| Export MISSING | **0** |
| Master bus | **1.000** |
| 15-minute self-playtest | **Pass** — opening, build, scout, first night, raid |

## Strict self-score

**7.2 / 10** on lavapipe. Helmer's holiday bar is **≥ 8/10**. I am
not calling 8. ChatGPT rated M **6.8** and projected **7.2–7.6** if
all five N items landed on the board. Architecture did: the Hexagon
castle is light limestone, house roofs are terracotta, civic roofs
are muted teal, emerald is gone. Rocks are retinted or hidden, the
creek is `#345E64`, groundcover clusters at the tree line. Terrain
and roads did not earn the top of that band — the lawn is still
khaki under the frozen grade, and the 512² union mask is proven in
`pkg2_road_control.png` more than in the gameplay camera. That is
the bottom of ChatGPT's 7.2–7.6 window, not an 8. A 4070 shot may
add a quarter-step of shadow and clay contrast. Do not merge on
this score.

## Five acceptance tests

| test | lavapipe |
| --- | --- |
| 1 Lush green terrain `#556D3F` | Partial — uniform + luminance detail; still khaki on filmic |
| 2 Unmistakable roads / magenta debug / 512² | Partial — union mask baked; on-board lattice still faint |
| 3 KayKit per-surface remap, no emerald | Pass — limestone hall, teal + terracotta roofs |
| 4 Rocks `#898776` or hidden; creek `#345E64` | Pass |
| 5 Clustered groundcover | Pass — forest edges / landmarks |
