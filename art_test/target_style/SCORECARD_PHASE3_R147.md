# Phase 3 — R147 (round223) scorecard — SW sector cards: shadow + distance, AFTER repairing R146

Self-score: **FAIL ~6.5/10** (verdict for Black; nothing to Helmer)

## 0. DISCLOSURE — R146's committed renders never drew the cards (read first)

R146's final edit put `km.shading_mode = ... # R146: ...` **mid-line** on the card-commit
one-liner. In GDScript everything after `#` is comment, so `km.cull_mode`,
`km.texture_filter`, **`kmi.material_override`, `kmi.cast_shadow` and `add_child(kmi)`
were all dead text**. The card mesh was never added to the scene in round222.

Proof (this round, measured):
- Disabling the commit entirely (`if false:`) vs round222: **109 changed px** (cliff-RNG level) — the mesh contributes nothing.
- Repairing the line raises prims 534,181 → 534,293 = **+112 = exactly the card triangles** (28 `add_foliage_card` calls × 4 tris).
- GDScript probe: `var x := 1 # c; x = 99` prints 1 — mid-line comments kill the rest of the line.

Second, compounding fault: **every render up to this round used a stale imported
`foliage_card.png`** (`.godot/imported/*.ctex` dated 03:29, source repainted later;
game-mode runs do not reimport). R146's "dark scribble → go unshaded" iteration and
all card texture judgements were made against the wrong texture. Forcing an editor
reimport this round changed **33,663 px** (the card tree alone) and the crown went
from black scribble to the intended soft painted mass.

Consequence: Black's bounded YES on R146 ("first crowns that don't read as faceted
spheres") was judged on sector trees whose **main lobes were missing** (mini+skirt
shell only) plus a stale texture. **round223 is the first true render of the R146
construction and the wholesale question should be re-judged on it.**

Sector truth: exactly **ONE** `_build_tree` tree reaches the card branch
(28 card calls = 14 lobes × 2; the other sector candidate is R69-culled, stacked
vi==1 trees return early). Card-mesh AABB: x[-12.44,-7.41], y[0.94,3.07], z[6.68,9.98].
The "sector prototype" is a single tree behind the round tower / SW house.

## 1. What R147 changed (diff audit)

`target_style_scene.gd` only: the dead one-liner card commit became 14 clean lines —
same intended settings (unshaded, alpha_scissor 0.45, cull disabled, LINEAR_WITH_MIPMAPS)
now actually live, with `cast_shadow = ON`. Sector, layout, buildings, terrain,
colour law (incl. `card_col146`), texture file: byte-identical to R146.

## 2. Blocker 1 — card shadow casting

- `cast_shadow = ON` at final settings, **verified at runtime** (probe printed cast=1; OFF control cast=0).
- Mechanism is sound: identical material in an isolated Godot 4.7 test casts a clear
  leaf-cluster shadow (ON/OFF diff 2,642 px; see scorecard PNG panel). A solid box
  dropped at the crown position in-scene also casts.
- In-scene at the frozen camera, the visible effect is tiny: cast ON vs OFF =
  **251 changed px total, ~150 of which is unseeded-cliff RNG jitter**; the real
  residue (~40 px) sits on the tower roof at the crown's lower-right. The one card
  tree stands behind the round tower/SW house from both camera and sun — its shadow
  cone lands on the tower roof/house and inside the already-present tower +
  mini/skirt + contact-disc shadow. **No absurd double-darkening** (nothing new gets dark).
- So: casting is ON and functioning, but a dramatic ground shadow for *this* tree is
  geometrically unavailable without moving it (layout frozen). A hero-shadow demo
  needs an unoccluded tree — Black's layout call, not a technique problem.

### Draw accounting (all measured, same camera)

| variant | draws | prims |
|---|---|---|
| R146 as committed (cards absent) | 288 | 534,181 |
| R147 cards live, cast OFF | 289 | 534,293 |
| **R147 cards live, cast ON (final)** | **289** | **534,293** |
| funding test: under-plane (up2) removed | 288 | 534,281 |

Cast-ON itself costs **+0 draws / +0 prims**. The +1 over the 288 ceiling is the card
mesh's single main-pass draw, i.e. the cheapest working shadow variant is **289**.
Funding attempts: cliff merge = draw-neutral (R146); roof merge = +2 (R146, reverted);
under-plane removal = −1 draw but changes **840 px (full) / 311 px (hill)** of frame
apron → fails the pixel-clean test, **not adopted** (available as Black's option).
Sun rig untouched. **Plainly: shadow cannot be funded to 288 without a visible
change; exact cost = +1 draw.**

Prims 534,293 exceed the ≤534,181 aim by exactly the 112 card tris — R146's figure
existed only because the cards were missing.

## 3. Blocker 2 — distance / mip behaviour

- Full view (~35 m, crown ≈120 px): dab structure and soft alpha contour intact,
  no erosion holes; sphere neighbours at the same distance still read faceted.
- Hill view is cliff-framed; the sector sits at/outside its left edge — no usable far
  sample in the frozen cameras. A labelled downscale series (100/50/25 % of the real
  crown pixels, `round223_distance_series.png`) shows dabs merging progressively,
  mass retained, no cutout collapse (texture interior alpha is dense, core ≈0.9).
- Stills only: temporal mip shimmer under camera motion cannot be measured from
  snapshots and remains the known cutout risk; no still-frame degradation observed.
- No mip/scissor change applied (a 0.25-threshold test changed nothing for shadow
  and was reverted; threshold stays 0.45).
- **Verdict: cards hold up at the sector's far edge in stills.**

## 4. Guards (classifier vs target; R146 in brackets)

| class | round223 | target | R146 |
|---|---|---|---|
| canopy | (52,90,17) HSV(.253,.811,.353) 18.72% | (65,85,23) (.22,.729,.333) | (52,90,17) 18.76% |
| roofs | (155,79,44) 8.45% | (152,107,76) | (154,79,44) |
| stone | (165,172,146) 1.37% | (139,139,128) | (165,172,146) |
| dirt | (147,119,57) 25.14% | (163,139,89) | (147,119,57) |

Canopy median **identical**, share −0.04 pp; stone/dirt identical; roofs ΔR +1
(import refresh). Closed classes hold with the cards actually visible.

## 5. Verdict

The R146 construction, rendered correctly for the first time, produces one genuinely
painted, non-faceted crown (see 200 % crop) and holds every guard. But the round's
mandate was shadow + distance in the sector: shadow casting is enabled and
engine-verified yet visually ~invisible for the single occluded sector tree and
costs **289 draws — one over the ceiling with no pixel-clean funding**. Distance
holds in stills. Combined with the R146 disclosure (prototype misjudged on missing
geometry + wrong texture; sector = 1 tree), the wholesale rollout question returns
to Black on corrected facts. **FAIL ~6.5/10, no PASS claim. Nothing to Helmer.**
