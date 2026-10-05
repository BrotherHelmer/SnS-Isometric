# GFX-02: AgX grade reset

Presentation-only value reset on top of GFX-1. No HUD, audio, gameplay-rule
or save-format changes. SDFGI, volumetric fog and PCSS stay off.

## Intent

GFX-1 added contrast by crushing brightness / contrast / saturation. That
destroyed shadow information and turned dusk into an orange wash, while
night roads read as the brightest surfaces. GFX-02 moves contrast into
**AgX** and period **17³ LUTs**, lifts shadows, cools dusk fill, and
darkens night roads.

| | Day | Dusk | Night |
| --- | --- | --- | --- |
| Tonemap | AgX | AgX | AgX |
| Exposure / brightness / contrast | 1.00 / 1.00 / 1.00 | 1.02 / 1.00 / 1.00 | 1.00 / 1.00 / 1.00 |
| Saturation | 0.94 | 0.93 | 0.92 |
| Sun / moon | `#F0C89A` 1.28 | `#E8A878` 1.08 | `#7892AC` 0.48 |
| Ambient / fill | moon `#7892AC` | cool `#6A8A9C` / `#6A88A0` | `#24383A` / `#3A5058` |
| Road lift | 0.03 | 0.04 | 0.12 (was 0.38) |

World tints come from the approved 14-colour master palette. Gold/orange
is scarce: dusk keeps a warm key but a blue/cyan fill so local greens and
browns survive.

LUT knots lift the old crush (`0.18 → 0.11`) to about `0.18 → 0.20–0.23`.
Chroma inside the LUT is held so mean pixel sat cannot rise above the
GFX-1 day 0.596 / dusk 0.553 caps.

## Pixel gates

Same 18-step Day 3 / dusk / Night 2 shots. HUD excluded.

| Gate | Threshold |
| --- | --- |
| Day world luminance σ | 0.07–0.14 (AgX + lifted shadows; GFX-1 crush was 0.176) |
| Day mean luma | 0.22–0.32 |
| Day mean sat (Y' ≥ 0.10) | ≤ 0.598 (GFX-1 measured 0.597) |
| Dusk mean sat | ≤ 0.555 (GFX-1 measured 0.553) |
| Dusk warm-pixel share | 0.20–0.50 (GFX-1 orange wash was 0.668) |
| Dusk mean luma | ≥ 0.16 |
| Night mean luma | ≥ 0.11 |
| Night near-black (Y' < 8/255) | ≤ 0.12 |
| Night road / grass | 1.20–1.80 (GFX-1 was 2.80) |

## Perf

Budget: dusk and night frame time at most +15% vs GFX-1 `231178e` on
lavapipe; day must not be worse. `t_gfx_gate_shots.gd` prints `GFX_PERF`
lines for day / dusk / night / first-view.
