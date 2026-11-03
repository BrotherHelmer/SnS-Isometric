# SCORECARD — Phase 3 R89 (round164): warm wall palette (internal only)

Reference: restored target (`phase3/target_reference_restored.png`), R88 round163.
Target bottom-half composition. Layout/relief/background unchanged.

## Warm rubble — 7/10
**Does the castle read warm rubble first now? Yes.** Full frame, castle walls
read warm beige-tan rubble before anything grey; roofs remain a darker, redder
terracotta and stay clearly distinct from walls; nothing went orange/red.
- Texture repainted with the *identical* R88 seed/layout (seed 8813, same
  multi-scale areas: min/med/max 12,330/40,022/163,208px), palette shifted
  warm: per-stone family moved to beige-brown-grey (texture mean RGB
  176/147/111, was ~158/150/138 neutral), warm component +0-26 per stone
  (15% extra-warm tan), mortar warmed to dark brown (84,67,50).
- **Changed beyond the texture (exactly):** (1) the scene stone colour at root
  in `_setup` for round>=3, `9d9584 -> a5917a` — this drives the 45% stone
  tint-through and every relief/foundation stone colour derived from `stone`
  (castle relief, house foundations), so relief no longer re-greys the wall;
  (2) stone tint-through base in `mat_for` warmed (1.04,1.00,0.94 ->
  1.06,0.99,0.88); (3) the two hardcoded `Color("9d9584")` relief colours in
  the roundhouse arc courses changed to `a5917a` to match. No other material
  colours touched; saturation kept muted (warm shift is hue, not saturation —
  castle does not compete with terracotta roofs).
Honest remainder: warmth is uniform across stone faces — the target varies
warmth by face/light more — and the roundhouse drum in close is dominated by
one very large pale texture stone (R88's large-cell tail), which reads a bit
blank next to the modelled relief.

**Overall honest self-score ~6.5/10. Not a Black PASS claim.**

## Perf
R89 round164: **273 draws / 312,737 prims / ~141,279 authored tris** — unchanged
(colour/texture values only; fresh-clone .import/project.godot noise unstaged).

Renders: evidence `phase3/round164.png` + `phase3/round164_close.png` (1280x800).
