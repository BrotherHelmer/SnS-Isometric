# Phase 3 — R106 Scorecard (round181) — internal only

## MY CHOICE (stated as required): switch to building openings/details
Reason: walls' remainder is now stronger-worked *degree*, while openings are a *kind*-gap — they make the target's houses read inhabited/hand-finished at full frame.

## Initial diagnosis (per building type, before changes)
- **Houses (×2):** rich already — door with inner panel, 2–4 lit windows, shutters, dormer, stone chimney. Minor: no window frames, no door lintel/step, all panes always lit.
- **Huts (×3):** **door only** — no windows, no chimney. Biggest gap.
- **Aframes (×2):** door + stone chimney (uncapped); no windows.
- **Roundhouses (×2):** door + exactly 1 window; no lintel/frames.
- **Roundbarn:** door + 1 window + uncapped stone chimney.
- **Octstores (×2, stone):** door only on the drum.
- **Castle / watchtower:** dark openings, banners/pennants, lit tower window already exist — kept, not duplicated.

## Changes (all existing colour keys: ffd98a lit pane, 3d2b18 dark pane, 54381f timber, 5d7a34 shutter, stone)
- Window unit everywhere: timber frame box proud of wall + inset pane 0.40–0.48 wide (sized to survive at 60–90px house scale), seeded lit (ffd98a) vs dark (3d2b18) per building (~78% lit), consistent with R105 seeded irregularity — no new regular grid (positions/angles follow each building's own seeded RNG and drum curvature where round).
- Hut: 2 framed windows + shutters, door lintel, seeded stone chimney with cap through the thatch (~60% of huts).
- Aframe: 2 framed windows, door lintel, chimney cap.
- Roundhouse: second framed window (angled to drum), door lintel, frame on existing window.
- Roundbarn: second framed window, chimney cap. Octstore: 2 angled drum windows, door lintel.
- Houses: timber frames behind existing panes, door lintel + stone step, seeded lit/dark panes.
- All other surfaces R86–R105 unchanged.

## Perf
- Full frame: **282 draws** (281 + 1 new stone shade key; cap 290), prims 375,288, authored tris ~166,206.

## Judgement (full frame vs target + building close)
- Full frame: warm lit windows now dot every building type — huts and aframes no longer blank-walled; buildings read inhabited across the settlement.
- Building close (octstore): framed lit window with timber surround reads hand-finished, pane survives at scale; dark/lit mix avoids uniform "all lights on".
- Honest limit: at full frame the panes are necessarily small; the inhabited read comes from their presence/placement across all buildings rather than any single detailed opening. Castle openings were left as-is (already present) — if Black reads the castle as blank, that is the next gap.

## Verdict
**R106: honest self-assessment — kind-gap closed scene-wide; borderline overall.** Awaiting Black. Nothing to Helmer.
