# Scorecard Phase 3 R58 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Per point
- Brown/earthy wall: rock_painted colour-graded to target
  brown (R x1.10, G x0.90, B x0.68 per channel) and the
  terrain shader's rock term warmed (x1.06,0.88,0.66) with
  a height-based base darkening (x0.68 at ground rising to
  x1.0 at h8) so the wall foot/talus sits darker into the
  ground. The right wall and back wall now read brown and
  earthy at full frame, matching target's tone direction;
  a lighter patch remains low on the right wall (snow-
  tinted vertex colour showing through the rock term).
- Strata at full frame: larger strata bands painted into
  rock_painted (~340px period in texture = ~1.3 world
  height units at the face UV), dark band bases, plus
  down-face crack lines. Bands now read in the FULL shot
  across the back wall and right wall, not only in the
  hill close (compare round128 pale wall vs round129).
- Meadow separation retained: grass still samples the
  clean meadow detail — no bands returned to foreground.
- Retained: cliff form, terraces at wall foot, crest,
  village/castle/paths, fog/strip as accepted. No animals.

Perf round129: 283 draw calls, 462,589 prims, ~152,044
authored tris.

Rounds: 129 (full + hill close).
Screenshots: phase3/round129.png, round129_hill.png;
scorecard SCORECARD_PHASE3_R58.png.
