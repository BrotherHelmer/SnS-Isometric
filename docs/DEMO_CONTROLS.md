# Shard & Sovereign Demo Controls

The demo is designed for keyboard and mouse.

## Camera

- Arrow keys: pan the camera.
- Middle-mouse drag: pan freely. Right-drag also pans while no settler is selected.
- Mouse wheel or `+` / `-`: zoom.
- `Home`: center the Town Hall.

## First order and settlement

- Left-click: select the opening settler, a tile, worker or building.
- With a settler selected, right-click open ground to Move or a tree/rock to Gather.
- The left command dock also exposes Move, Gather and Cancel.
- Choose a category and visual building entry in the left command dock, then left-click valid ground to place a road, structure, Lumen Pillar, wall or Claimant Outpost.
- `R`: rotate the current non-road building before placement.
- `Escape`: cancel the active placement/demolish/clear tool; from Select, open the pause menu.
- Select a building: inspect its thumbnail, purpose, costs, road state, staffing, inputs, storage and current task in the left dock.
- Demolish tool, then left-click: remove an owned construction.
- Clear tool, then left-click: assign a free worker to clear a tree or rock.

Roads are free to plan, but a settler must construct them. Other construction consumes physical materials that carriers collect and deliver.

## Wyrd and Claim

Wyrd extraction and the Shard claim are settlement-level actions. Connected Claimant Outposts harvest nearby Wyrd. When an operational Outpost beside the Shard has connected owned roads and active Lumen, the settlement establishes its claim automatically.

To claim the Shard, extend a connected road and active Lumen network to the center, build a Claimant Outpost, prevent an enemy contesting Outpost, and hold every condition through the full claim night.

## Time and Menus

- `Space` or Pause: pause/resume.
- Speed button: cycle `1x`, `2x`, and `4x`.
- `L`: open/close the Realm Chronicle.
- `Escape` while paused: resume.
- Pause menu: Resume, Save, Restart, Settings, Main Menu, or Quit.
- Main menu Continue: available only for a readable version-6-or-newer local save.

Save data is written to Godot's per-user application-data folder, not beside the executable.

Audio and display settings are available from both the main and pause menus. Master, Music, Effects and Ambience values apply immediately and persist as percentages in the per-user settings file; Mute Music silences the synchronized score without restarting it.
