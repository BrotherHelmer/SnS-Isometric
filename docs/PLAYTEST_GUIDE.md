# Shard & Sovereign — Windows playtest

Build: 0.2.0-playtest.4. This is a local internal candidate for the planned closed Steam Playtest. Steam distribution is not configured yet.

## Start

Extract the whole ZIP into a folder, then open `ShardAndSovereign.exe`. Keep the `.pck` beside the executable. No Godot editor or developer tools are required. Choose **NEW REALM**, then **BEGIN**. Use Advanced to enter a repeatable seed; 260821 is the review seed.

You are founding a settlement in a province shared with a rival. Build a working economy, prepare for night raids, extend roads and Lumen toward the Shard, then begin Binding when its requirements are met. Binding takes 120 simulation seconds and triggers the Reckoning. A destroyed Town Hall, lost population or successful rival Binding ends the run.

## Controls

| Action | Control |
| --- | --- |
| Select / build | Left click |
| Open construction choices | BUILD button |
| Rotate building | R while placing |
| Cancel | Escape |
| Pan | Arrow keys, middle-mouse drag, minimap click |
| Zoom | Mouse wheel |
| Pause / speed | HUD buttons |
| Save / continue / settings | MENU |

Workers and defenders act autonomously. Roads have no resource cost, but workers must construct them. Buildings need road access, resources and appropriate staffing. Goods are carried between local inventories; a resource visible in the province is not necessarily available at the Town Hall.

To remove a contesting rival Outpost, select it and choose **ASSAULT RIVAL OUTPOST**. Trained patrol soldiers travel there and attack; tower sentries remain home. Soldiers can be killed while away. **RECALL ASSAULT SOLDIERS** returns them to the settlement. You must reveal the target and provide a walkable approach.

## First session

Build a House and a Lumber Camp near connected roads; watch the first delivery. Establish a Farm and Bakery for food, then a Quarry and Sawmill to support construction. Inspect stalled buildings for the reason. A Watchtower needs a trained soldier; a Barracks supplies recruits. Night 1 teaches the threat; later nights and Wyrd extraction raise the stakes. Outposts and Lumen support expansion and the Shard race.

The current match-length hypothesis is 35–55 minutes; this is being tested. Pause and speed controls change wall-clock duration.

## Progress and recovery

The game autosaves every two minutes of active real time. **SAVE & QUIT**, including the window close button during play, saves before exiting and keeps the game open if saving fails. Continue selects the most recently written manual save or autosave. Each has a recovery copy. A corrupt primary can recover automatically; unsupported save versions are rejected without replacement. Starting another realm preserves an active previous realm separately.

Playtest data is isolated under `%APPDATA%\ShardAndSovereign\Playtest`. It does not overwrite the old demo's Godot save folder. The old demo's incompatible province saves are not imported automatically. Recovery files and the previous realm can be supplied with a feedback report.

## Feedback

Choose **SAVE FEEDBACK REPORT** in the menu. A local folder opens with a report, current realm and logs. Add what happened, what you expected, and reproduction steps before sharing it with the developer. Nothing is uploaded automatically.

For an unassisted pilot, play the first ten minutes without reading a build-order walkthrough. Record the first confusing moment, first delivery, food trouble, first night, time/reason for stopping, and whether you wanted another run. Include build, seed and machine/GPU details.
