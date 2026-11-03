# Scorecard Phase 3 R50 (internal only — nothing to Helmer)

Verdict: NOT matches target at first glance. Black to validate.

## Composition track (judged full frame vs target diagram:
castle centre, settlement spread around, paths winding,
steep brown mountain right third, snow top)
- Spread settlement: 9 outer buildings moved radially out
  from the castle anchor (roundhouses 7.2->9.0 / 9.6->12.0,
  huts, round barn, A-frame, oct-store and both parametric
  houses likewise), castle + centre oct-store stay. Frame
  reads wider/less compact in round108-110; centre is still
  denser than the edges, as in target.
- Winding path network: 5 new routes built from overlapping
  dirt discs along sine-wiggled polylines (village east-west
  route, castle-to-mine route, castle-to-summit route, and
  two connectors to the moved houses), merged into the
  existing dirt mesh — no new draws. The network now visibly
  winds across the whole frame connecting buildings/mine/
  summit; paths are paler/wider than target's worn tan.
- Mountain right third: heightfield steepened (back ramp
  /10 -> /7) and raised (12.5 -> 15.0, centre x14 -> x15),
  two screening trees moved off the face (15,-4)->(19,-7),
  (11,-12)->(8,-15). Hill is taller/steeper and summit sits
  top-right, but honest: it still reads as a background hill
  behind the settlement, NOT target's steep brown mass
  filling the right third — trees and haze still screen its
  lower face, and its slope is on the far side of the frame.
- Camera test round109 (look pushed further east) REJECTED:
  cropped village left and exposed the terrain plane edge
  bottom-right; reverted to round108 framing for round110.
- Retained: R49 palette, forms, trees, miniature crowd,
  castle/houses, summit. No animals invented.

Perf round110: 281 draw calls, 408,129 prims, ~156,072
authored tris (paths are merged discs).

Rounds: 108 (spread+paths+hill), 109 (camera reject),
110 (108 framing confirmed).
Screenshots: phase3/round108.png, round109.png (reject),
round110.png; scorecard SCORECARD_PHASE3_R50.png.
