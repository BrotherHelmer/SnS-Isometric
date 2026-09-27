# Verifying .pck File Contents

This guide explains how to confirm that runtime assets are properly packed into the release `.pck` file.

## Problem Context

Godot 4 Windows Desktop exports with `export_filter="resources"` and an explicit `export_files` list can **silently omit runtime assets** if:
- The asset path is constructed via string concatenation in code (e.g., `ROOT + "/opening_style/castle.tscn"`)
- The asset path is hardcoded in a script function (e.g., `"res://assets/settlement/audio/saw.wav"`)
- The path is NOT explicitly listed in `export_presets.cfg` → `export_files=PackedStringArray(...)`

**Historical failures:**
- **Playtest.22**: Castle morph code worked, but `castle.tscn` was NOT in `export_files` → Wine playtest showed missing castle visual
- **Playtest.24**: Audio director referenced 9 audio files not in `export_files` → primary day BGM, ambience, work SFX, settler arrival cues were missing from packed build

## Automated Verification (Preferred)

Use `tools/audit_export_packing.py` to systematically verify all runtime paths:

```bash
cd /workspace
python3 tools/audit_export_packing.py
```

**Success output:**
```
=== EXPORT PACKING AUDIT ===

Total runtime paths: 88
Export files count: 162

⚠ MISSING FROM EXPORT: 0 paths

=== AUDIT COMPLETE ===
Exit code: 0
```

**Failure output (example from pre-playtest.24):**
```
🔴 FILES THAT EXIST ON DISK BUT ARE NOT IN EXPORT_FILES (9):

  - res://assets/settlement/audio/barracks_ready.wav
  - res://assets/settlement/audio/presentation/bgm_settlement_loop.ogg
  ...
```

The audit script:
1. Collects all runtime paths from `ProductionAssetCatalog3D.all_runtime_paths()` 
2. Collects all audio paths from `ProductionAudioDirector3D` STEM_PATHS, CUE_PATHS, and hardcoded work SFX
3. Parses `export_presets.cfg` to extract `export_files` list
4. Reports any paths that exist on disk and are referenced at runtime but are NOT in the export list

**Run this audit before every release build.**

## Manual Verification (Windows `.pck` Inspection)

If you need to inspect an already-built `.pck` file:

### Method 1: Strings + Grep (Quick Check)

The `.pck` file is a Godot-specific archive format, but resource paths are stored as plain text strings:

```powershell
# Check if a specific file is in the .pck
strings dist/ShardAndSovereign_0.2.0-playtest.24/ShardAndSovereign.pck | findstr "bgm_settlement_loop.ogg"

# Check all audio files
strings dist/ShardAndSovereign_0.2.0-playtest.24/ShardAndSovereign.pck | findstr "assets/settlement/audio"
```

On Linux/WSL:
```bash
strings ShardAndSovereign.pck | grep "bgm_settlement_loop.ogg"
strings ShardAndSovereign.pck | grep "assets/settlement/audio"
```

**Expected output:** You should see the full `res://` path if the file is packed:
```
res://assets/settlement/audio/presentation/bgm_settlement_loop.ogg
```

**If missing:** The path will not appear, indicating the file was NOT included in the export.

### Method 2: Godot PCK Explorer (Full Inspection)

Use a third-party tool like [gdsdecomp](https://github.com/bruvzg/gdsdecomp) or Godot's own `--dump-pck` option (if available in your Godot build).

**Note:** This is more involved and usually unnecessary if the automated audit passes.

## Adding Missing Assets

If the audit reveals missing assets:

1. **Open `export_presets.cfg`** in a text editor
2. **Find the `export_files=PackedStringArray(...)` line** (very long single line in preset.0)
3. **Add the missing path(s)** to the array, maintaining alphabetical sorting within each asset group:
   ```
   ..., "res://assets/settlement/audio/saw.wav", ...
   ```
4. **Re-run the audit** to confirm: `python3 tools/audit_export_packing.py`
5. **Rebuild the release**: `pwsh tools/build_release.ps1`

## Prevention Strategy

**Before adding new runtime assets:**
1. Add the asset to the appropriate catalog/director constant (e.g., `BUILDINGS`, `AUDIO_CUE_PATHS`)
2. Add the `res://` path to `export_presets.cfg` → `export_files`
3. Run `python3 tools/audit_export_packing.py` to verify
4. Test in a packaged build (not just editor)

**When modifying asset catalogs:**
- If you add or change paths in `production_asset_catalog.gd` or `production_audio_director.gd`, immediately run the audit
- Never assume dynamic paths (string concat, dictionary values, hardcoded load() calls) will be auto-detected by Godot's export

## Technical Notes

- **Why explicit `export_files`?** The project uses `export_filter="resources"` with an explicit file list to ensure only production runtime assets are included (excludes test fixtures, dev tools, unused vendor files)
- **Why not `export_filter="all_resources"`?** That would pack unnecessary files and bloat the `.pck`; explicit list gives control but requires discipline
- **Alternative approach:** Use include filters (`include_filter="assets/settlement3d/runtime/**,assets/settlement/audio/**"`) but this requires careful glob patterns and still risks omissions

## References

- **Godot Export Docs:** [Godot 4 - Exporting Projects](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html)
- **Asset Catalog:** `src/GodotClient3D/Scripts/production_asset_catalog.gd`
- **Audio Director:** `src/GodotClient3D/Scripts/production_audio_director.gd`
- **Export Config:** `export_presets.cfg`
- **Audit Tool:** `tools/audit_export_packing.py`

---

**Version:** 0.2.0-playtest.24  
**Last Updated:** 2026-09-27
