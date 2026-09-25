# Current product scope — 2026-09-25

Target: closed Windows Steam Playtest, then a public demo after observed playtests and release gates pass. Steamworks setup is deferred by the owner. No Steam upload or release has been performed.

## Production rules

- One 70×70 province, one Shard, a player settlement and a deterministic rival realm.
- Prebuilt Town Hall with two population; House/Lumber/Farm/Bakery progression, physical construction and hauling, finite inventories and storage pressure.
- Roads cost no resources and require worker construction. Food supports population and soldier training. Night raids threaten workers, buildings and the Town Hall.
- Settlement and worker orders; no directly controlled player Sovereign. The rival retains an internal Sovereign for its planner.
- Seven-minute days and three-minute nights at 1×. The proposed 35–55 minute session length is not yet validated by human sessions.
- Outposts within three tiles of Wyrd nodes harvest Wyrd. Connected Lumen and roads support an operational Shard Outpost. Binding is an explicit action requiring at least 12 Wyrd and 120 seconds of maintained conditions. Historical one-night/two-night victory descriptions are obsolete.
- Opposing Outposts contest Binding. Select a visible rival Outpost and order an assault by free patrol soldiers. They walk to the target and attack in range; tower sentries stay home. Assault soldiers remain vulnerable to raiders and can be recalled. Destroying the rival Outpost removes that obstruction; other Binding requirements still apply. This resolution was selected by the owner on 2026-09-25.
- Town Hall destruction or the rival Binding first causes defeat. Current natural-match evidence is recorded in the execution status; prepared-state rule tests are not proof of a full playable match.

## Persistence

Save formats 6–8 are accepted after structural validation. Future versions are rejected without replacing the live realm. Writes use a verified temporary file, a previous-valid backup and file replacement. Missing/corrupt primary files can recover their backup. Autosave runs every two active wall-clock minutes; pause stops its timer. Continue selects the most recently written manual/autosave using a saved timestamp, with filesystem time for older files.

New Realm preserves the active run as `previous_realm.json`. Quit/window close saves and stays open on failure. Quality/fullscreen and audio settings persist. SAVE FEEDBACK REPORT creates a local folder with a save, settings and available diagnostics. The user chooses whether to share it.

Playtest data is separate from the old demo at `%APPDATA%/ShardAndSovereign/Playtest`. No Steam Cloud migration or genuine historical-save certification is claimed.

## Supported candidate scope

Windows x86_64, keyboard/mouse, Forward+. Controller, Steam Deck, Linux/macOS, achievements and Steam Cloud are not advertised. Low graphics is available; a lower-end GPU and physical clean-machine test remain necessary before publishing minimum requirements.

Production authority: `one_shard_simulation.gd`, definitions, rivalry/tuning and Wyrdfall. Production presentation: `src/GodotClient3D`. Earlier C# tests, old exports and tests that inject prepared state remain historical/regression material.
