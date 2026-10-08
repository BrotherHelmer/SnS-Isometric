# GFX-B gap analysis

Visual north star: `concept_1.png` (Farthest Frontier–like Nordic diorama).
Compared against Helmer’s 8/10 playtest (`pt0810/day_scout.png`, `pt0810/night_raid.png`)
and the GFX-A / G1 zoom shot (`g1_gfx_zoom_day.png`). Helmer already likes the
crops — those stay. This pass is presentation only: no RTS rewrite, no scout /
night-guard / raider-outline gameplay, no Master-volume change.

GFX-A (GFX-1 → GFX-10 + G1) already shipped AgX grading, two-scale ground,
SSAO, PSSM, clay roads, roughness bands, a 6-tree kit, night windows, story
zones, and an island waterline. The remaining gap is **read**: the concept is a
lush, warm, material-rich settlement in water; the live build still reads as a
khaki board with a painted olive unknown and a grey toy keep.

Effort bands: **S** shader/palette only · **M** new authored meshes or HUD
art · **L** remodel / new vegetation kit.

---

## 1. Palette, lighting, grading

| | Concept | Live (GFX-A) |
| --- | --- | --- |
| Grass | Living meadow green, cool shadows | Olive / khaki `#78815A` / `#586746` |
| Sun | Warm gold, readable form | `#F2C888` @ 1.50, AgX, sat 0.94 |
| Midtones | Rich cream plaster, terracotta, slate | Muted grey-green wash |
| Night | Blue-green ground, warm panes | Terrain collapses toward near-black |

The concept is not more saturated so much as **greener and warmer in the
right places**. GFX-02’s sat caps (day ≤ 0.598, dusk ≤ 0.555) are still the
budget — a hue shift toward green, not a sat bomb.

| ID | Gap | Pri | Effort |
| --- | --- | --- | --- |
| B-01 | Authored grass is yellow-olive; far zoom is a khaki pancake | **P0** | S |
| B-02 | Day key could be a hair warmer without breaking AgX gates | P1 | S |
| B-03 | Night ground / fill too low; windows carry the whole picture | **P0** | S |
| B-04 | Full LUT rewrite / glow / volumetric | P2 | M — needs a quality toggle |

**Keep:** AgX, period 17³ LUTs, cool dusk fill, no SSIL/glow/volumetrics on
Recommended. **Do not** crush B/C/S again.

---

## 2. Terrain and coast

G1 already made the province an island: water plane, rounded-rect waterline,
2-tile beach, horizon hills. That geography stays.

The concept shore is a **teal-green sea** with foam and trees on the lip. Live
water is a dark pewter disk (`deep 0.16,0.26,0.28`) that dies into the
sky-ground. Interior grass still wins over the two-scale shader (vertex mix
0.48), so the island reads as one khaki oval.

| ID | Gap | Pri | Effort |
| --- | --- | --- | --- |
| B-05 | Grass / moss hue + stronger macro patches (keep dirt + crops) | **P0** | S |
| B-06 | Water a step toward teal-green, still fog-disabled / unshaded | P1 | S |
| B-07 | Carved coves, rock stacks, animated swell | P2 | M — G1 land-mask tests must not regress |

**Keep:** `t_g1_coast_land.gd` contract (every playable tile + entity on land
with a 2-tile beach). No coast remesh in GFX-B.

---

## 3. Building silhouettes and materials

Concept castle: pale cream masonry, dark **slate-blue** roofs, tall keep.
Concept houses: cream plaster, dark timber, **terracotta / brown** roofs.

Live opening-style meshes already have the right *block-out* (keep, curtain,
stepped shingles). Materials betray them: stone `#a99d81` classifies as
plaster, slate `#304d44` is teal-green, and GFX-07 only sets roughness + a
±5–8% instance shift. The keep reads as a grey toy, not stone.

| ID | Gap | Pri | Effort |
| --- | --- | --- | --- |
| B-08 | Runtime remap: castle → pale masonry + blue-grey slate | **P0** | S |
| B-09 | Runtime remap: house / farm / bakery teal roofs → terracotta | **P0** | S |
| B-10 | Remodel silhouettes, timber framing, new castle mesh | P2 | L — out of scope |

**Keep:** imported silhouettes, roughness bands, fresnel bevel, wheat sheaves.

---

## 4. Vegetation

Concept: mixed fir / broadleaf mass, understory, trees on the waterline.
Live: GFX-08’s 6-silhouette MultiMesh kit + Kenney trees + opening-style fir /
broadleaf. Helmer called out the **crops** as a win.

Canopy tints (`#2A3C30`, `#3A4A28`) are almost black from the strategy camera,
so the kit looks like one dark cone-wall.

| ID | Gap | Pri | Effort |
| --- | --- | --- | --- |
| B-11 | Lift canopy tints a step (still Nordic, not tropical) | P1 | S |
| B-12 | New tree hero meshes / denser interior forest | P2 | M — foliage_density already scales |
| — | Farm wheat / garden plots | **keep** | — |

---

## 5. Fog of war

Called out in the brief. Unexplored *interior* tiles are a world-space sheet
at y = 0.06, unshaded, opacity 1.0, colour `FOG_UNKNOWN_BASE (0.09, 0.12, 0.08)`
— the same olive family as the grass. It reads as **unpainted khaki ground**,
not mist. Off-map is correctly the G1 beach / sea (#47).

| ID | Gap | Pri | Effort |
| --- | --- | --- | --- |
| B-13 | Cool slate unknown + multi-octave wisps so the sheet reads as atmosphere | **P0** | S |
| B-14 | Soften the reveal edge (shader only; reveal set unchanged) | P1 | S |
| B-15 | True volumetric unknown / height-fog volume | P2 | M — needs a quality toggle; lavapipe night budget |

**Keep:** on-map unknown stays unknown. No gameplay reveal changes. No scout
vision edits (parallel branch `cursor/dawn-aftermath-72ce`).

---

## 6. UI framing

Concept chrome is navy with a gold hairline — already the T-SNS-UI Look
direction (`production_hud_skin.gd`, Cinzel + Source Sans 3). Live HUD is
close; the world is what breaks the diorama, not the bars.

| ID | Gap | Pri | Effort |
| --- | --- | --- | --- |
| B-16 | Thicker gold hairline / more opaque console | P2 | S–M |
| B-17 | New frame art, type, thumbnails | P2 | M |

**Keep:** 11 px floor, RAID banner top-right, no centre pop-ups. No HUD
rewrite in GFX-B.

---

## 7. Night readability

`night_raid.png`: moon `#7892AC` @ 0.48, ambient `#24383A` @ 0.66, cheap-path
(SSAO off, one-octave terrain). Windows `#F2B56B` work. Grass and roads
collapse; the raid is a dark oval with two combat toasts.

| ID | Gap | Pri | Effort |
| --- | --- | --- | --- |
| B-18 | Lift moon / fill / night ground tint; keep windows the brightest pixels | **P0** | S |
| B-19 | Raider / scout / night-guard outlines | **leave** | — parallel agent |
| B-20 | Bloom on panes / volumetric moonlight | P2 | S — only behind a quality toggle |

Night road/grass gate stays 1.20–1.80. Do not re-lift roads to GFX-1 white
(`road_lift` stays ≤ 0.16).

---

## GFX-B cut (this PR)

Implement **P0** and cheap **P1** as presentation-only shader / material /
palette edits:

| Do now | Postpone |
| --- | --- |
| B-01, B-05 grass hue + macro | B-04 glow / volumetrics |
| B-03, B-18 night lift | B-07 coast remesh |
| B-08, B-09 castle + roof remaps | B-10 building remodel |
| B-13, B-14 cool atmospheric FoW | B-12 new tree kit |
| B-06 water teal (cheap) | B-16, B-17 HUD chrome |
| B-11 canopy lift (cheap) | B-19 raider outlines (other branch) |

No `.github/workflows` edits. No extra Actions. Assets remain CC0 KayKit or
project-authored opening-style meshes (`docs/art/ASSET_LEDGER.md`). Target
box is an RTX 4070; nothing heavier than the existing Recommended profile
ships without a quality switch. SDFGI, volumetric fog, PCSS, SSIL, glow stay
off on Recommended.
