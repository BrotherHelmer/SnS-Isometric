# Scorecard Phase 3 R64 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.
First-glance test asked: one painted landscape with a
settlement in it? Answer: closer at ground level, still no
at full frame.

## Per point
- Contact grounding (new): every building now sits on a
  worn-earth lens (a8895a, tapered blob) + a darker AO
  lens (alpha 0.42) + 4 grass tuft blobs against its
  walls; castle gets a larger pair. All merged (existing
  keys + one alpha key). In the close shot buildings sit
  INTO the ground with worn earth and shadow at the base
  instead of floating on clean grass; at full frame the
  village ground reads more worked around each house.
- Shared light: a second warm omni pool added over the
  hill (17,8,-5, energy 0.55, range 13) matching the
  village pool's colour, so wall and village receive the
  same warm pooling; post grade (ACES + saturation) was
  already frame-wide. Fog rebalanced 0.0008 -> 0.0012
  for gentle aerial perspective by depth on both.
- Honest first-glance: grounding helps where you look at
  buildings, but the whole still reads as modelled
  objects on a terrain — the painted-illustration gap
  (surface brushwork vs textured low-poly, the R41
  finding) remains dominant. Contact/fog/light unify
  the parts; they do not repaint them.
- Retained: wall composition/content, palette, forms,
  trees, crowd. No animals invented.

Perf round135: 288 draw calls (<=290; +3 for the alpha
AO key and new contact keys), 482,213 prims, ~164,788
authored tris (contact blobs counted).

Rounds: 135 (full + close).
Screenshots: phase3/round135.png, round135_close.png;
scorecard SCORECARD_PHASE3_R64.png.
