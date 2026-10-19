# Phase 3 — R110 Scorecard (round185) — internal only

## MY CHOICE (stated as required): settlement airiness/spacing
The first-glance composition gap Black named: target breathes (open grass, clear lanes, separate painted forms); ours crammed forms into a modelled mass.

## Changes (`target_style_scene.gd`, layout only)
- **Two buildings spread** (every reference updated by exact coordinate replacement, verified counts in the edit): hut (7.5,5.5)→(8.2,6.8) and aframe (-4.5,6.0)→(-5.6,7.6). For each: build call, worn-yard patch, R75 detail-pass anchor, main/branch path polylines, flag pole and contact-disc lists all moved together, so details, paths and yards follow the buildings. Both stay inside the flat settlement disc (radii 10.6 and 9.4, same seating regime as before — crops verify grounded, no float/sink, paths arrive at doorsteps).
- The aframe's old fence segment was removed rather than moved (it would have sat inside the new footprint) — thinning and a lane opening in one.
- **Selective clutter thinning (not wholesale):** R75 side-clutter (woodpile/lean-to/crate clusters) removed on homes 2, 6, 9 only; door lanterns and step stones at every home kept (lived-in). Two centre canopy bushes and one castle-front barrel/crate cluster removed.
- Freed ground is open R96–R97 meadow; **no new trees/props added** (R69 tree spacing discipline kept). Castle remains central focal point; hill/mine/snow composition untouched; all surfaces R86–R109 unchanged.

## Perf
- **283 draws** (unchanged — thinning removed geometry inside already-merged keys), prims 458,128 (down from 459,528), authored tris ~165,498.

## Judgement (full frame vs target, first glance)
- The south-west and centre-east lanes read a little more open; the moved aframe/hut sit as separate forms with grass around them, and the settlement does **not** read empty — settlers, pennants, lanterns, windows (R106) and remaining detail keep it lived-in.
- Honest limit: this is a modest gain, not a transformation. The centre (castle + octstore + roundhouses) is inherently dense and was left as the focal cluster; at first glance the settlement still reads denser and more modelled than the target's airy painted spacing. Two ~1.5u moves are what the layout allows without reseating the whole village and its path/detail web.

## Verdict
**R110: honest self-assessment — airiness improved modestly and safely, borderline overall.** Awaiting Black. Nothing to Helmer.
