# Shards & Sovereign asset ledger

Snapshot date: 2026-08-21  
Authoritative vendor drop: `D:\SnS_Isometric\assets\Kaykit`

## Gate status

**PASS.** All six Phase 1 packs and the three previously installed Medieval Hexagon variants are present as preserved ZIP archives plus extracted, versioned source directories. Each archive member count matches its extracted file count, every source directory retains the vendor `License.txt`, and all nine licenses are Creative Commons Zero (CC0 1.0).

The raw vendor tree is treated as immutable. `assets\Kaykit\.gdignore` keeps it outside the production Godot import graph; the isolated Phase 1 lab consumes only the reproducible runtime allowlist.

## Immutable source records

| Vendor archive | Version / tier | Bytes | SHA-256 | Archive files | Extracted files | License date |
| --- | --- | ---: | --- | ---: | ---: | --- |
| `KayKit_Character_Animations_1.1.zip` | 1.1 | 14,858,957 | `65882F31F905AD2E953819648A59287CDEAB8F623908D5EF701971D3758BE20F` | 37 | 37 | 2025-12-10 |
| `KayKit_Adventurers_2.0_FREE.zip` | 2.0 FREE | 13,024,345 | `ABE48F4763FBA0896BAB486EE9E6D08CA6B5B3884B9601F235C8847AE94DC479` | 250 | 250 | 2025-10-22 |
| `KayKit_Mystery_Monthly_Series_6_(1.1).zip` | 1.1 | 41,650,373 | `AF5EDC90635DA34652469DD9EB90C7C35758F32202F7FE842233A90CCA8AD3A0` | 413 | 413 | 2026-07-16 |
| `KayKit_Forest_Nature_Pack_1.0_FREE.zip` | 1.0 FREE | 6,435,630 | `2EE83E63BB7695F2D884EC27DDF6FCE020789A452E7D5C5B0BBDFC4F6EA1FC8C` | 641 | 641 | 2025-04-29 |
| `KayKit_ResourceBits_1.0_FREE.zip` | 1.0 FREE | 8,520,574 | `7056F1310896A4612A67703FD6D5AF389FCCCDEB46DF0A89E2322AA8E3BCFCF7` | 466 | 466 | 2025-04-03 |
| `KayKit_RPGToolsBits_1.0_FREE.zip` | 1.0 FREE | 3,885,168 | `A17C2A54DF93D525E90D960BAF3C68638DEFB4F424E204CEEAD6EA1F89E9C7DD` | 339 | 339 | 2025-11-26 |
| `KayKit_Medieval_Hexagon_Pack_1.0_FREE.zip` | 1.0 FREE | 35,251,508 | `4FBB374C45732C88522BD3439E9415BF568C683236EDE336B4E61D161155BA12` | 1,473 | 1,473 | 2024-04-26 |
| `KayKit_Medieval_Hexagon_Pack_1.0_EXTRA.zip` | 1.0 EXTRA | 56,555,250 | `E32E033EE0B1AD5414CA320D5C5CA56CC12BFFF6E7B98801E8F777DBCF12C901` | 2,768 | 2,768 | 2024-04-26 |
| `KayKit_Medieval_Hexagon_Pack_1.0_SOURCE.zip` | 1.0 SOURCE | 64,657,578 | `ABF18DDDF87E70F61617AF1AA7463D012D95DCA70764CBF5D49A5E30504733E7` | 2,769 | 2,769 | 2024-04-26 |

All archive hashes are SHA-256 over the original ZIP bytes. Counts exclude directory-only ZIP entries. Source files were not renamed, converted, or edited during extraction.

## License metadata

All packs identify Kay Lousberg as creator/distributor and carry CC0 1.0. The included text explicitly permits personal, educational, and commercial use. Attribution is optional. The source `License.txt` remains beside each extracted pack; this ledger is an audit index, not a replacement for those files.

## Runtime allowlist

`tools\phase1_sync_runtime_assets.ps1` deterministically rebuilds `phase1_3d_lab\assets\runtime` from the immutable vendor source and mirrors the four production simulation scripts used by the proof. The generated `allowlist_manifest.json` records source path, runtime path, byte size, and SHA-256 for every copied file.

| Runtime group | Files | Import policy |
| --- | ---: | --- |
| Characters | 8 | Vendor-supplied GLB |
| Animation libraries | 8 | Vendor-supplied Rig_Medium GLB |
| Buildings and settlement props | 19 | Vendor-supplied glTF + BIN + texture dependencies |
| Farm assets | 13 | Vendor-supplied GLB or glTF dependency sets |
| Nature | 45 | Vendor-supplied glTF + BIN + shared texture |
| Resources and cargo | 19 | Vendor-supplied glTF + BIN + shared texture |
| Tools | 11 | Vendor-supplied glTF + BIN + shared texture |
| Production simulation mirror | 4 | Byte-for-byte GDScript copies |
| **Total** | **127** | No duplicate runtime paths |

No asset conversion is required for Phase 1. GLB is the preferred runtime format for rigged characters and animations; supplied glTF is used directly for static assets so its BIN and texture dependencies remain explicit and reproducible.

## Rig and animation gate

Godot 4.7 imported and exercised Barbarian, Farmer_A, and Farmer_B against all eight Rig_Medium libraries without retargeting. The three skeletons expose the same 23 named joints and compatible parent/rest relationships. Farmer_B uses a different numeric bone ordering, so all bindings and sockets are name-based.

The eight libraries provide 139 clips:

| Library | Clips |
| --- | ---: |
| CombatMelee | 22 |
| CombatRanged | 20 |
| General | 15 |
| MovementAdvanced | 13 |
| MovementBasic | 11 |
| Simulation | 14 |
| Special | 15 |
| Tools | 29 |

The focused gate played and verified pose deformation for Idle_A, Walking_A, Running_A, Chop, Hammer, Pickaxe, Melee_1H_Attack_Chop, Hit_A, and Death_A. Holding_A is present, and a physical `Wood_Log_A` prop was attached to the discovered `handslot.r` bone through `BoneAttachment3D`.

The animation files contain 43 root-position tracks across the libraries. Phase 1 deliberately leaves world translation under simulation authority: `CharacterView3D` drives semantic animation state while authoritative routes drive character position. No animation state changes production, inventory, pathfinding, or combat results.

## Evidence

### Opening-style playable geometry — 2026-09-26

`assets/settlement3d/runtime/opening_style/` contains twelve project-authored 3D models adapted from the pre-generated AI reference sheet in `assets/art_direction/opening_style_v1/`. These are native Godot mesh resources and scenes, built reproducibly by `tools/build_opening_style_models.gd`; they are not extracted KayKit meshes or automatic image-to-3D reconstructions. The set contains town hall, house, storehouse, lumber camp, bakery, watchtower, fir, broadleaf, rocks, fence, lantern and cart. Building geometry is normalized to the presentation profile; gameplay footprints and saves retain their existing meanings. Related roles reuse appropriate models (farm/house, sawmill/lumber camp, Outpost/watchtower).

Meshes are merged by material into one mesh per model for compatibility with instanced nature rendering. `model_manifest.json` records surface and triangle counts. The roof and meadow raster candidates remain outside the runtime: the models use geometric shingles and authored materials. AI reference provenance remains applicable to the design process. This is the first playable adaptation, not a claim of visual parity with the title illustration.

### Title-screen illustration — 2026-09-26

`assets/settlement3d/runtime/interface/title_settlement_v1.png` is pre-generated AI artwork created with OpenAI's image-generation tool for this project. It depicts a decorative settlement at dusk, not the live game map. It contains no baked-in title or interface text. This asset is separate from the KayKit CC0 assets listed above. Record it as pre-generated AI content when completing the eventual Steam content survey; no runtime image generation is used.


- Runtime manifest: `phase1_3d_lab\assets\runtime\allowlist_manifest.json`
- Rebuild script: `tools\phase1_sync_runtime_assets.ps1`
- Focused rig log: `phase1_3d_lab\artifacts\final_rig_validation.log`
- Scale log: `phase1_3d_lab\artifacts\final_scale_validation.log`
- Full Phase 1 handoff: `docs\architecture\PHASE_1_3D_FOUNDATION_REPORT.md`

### Environment follow-up — 2026-09-26

Playtest.4 expands the authored opening-style set from twelve to nineteen model scenes, adding Quarry, Barracks, Lumen Pillar, rival camp, grass, bush and wheat. Existing wall geometry receives stone crenellations. Character clothing and terrain colour changes use project-authored runtime shaders; no vendor bitmap or rig is edited. The previously generated meadow/roof bitmap prototypes remain unused. Geometry continues to derive from the recorded AI art direction; see OPENING_STYLE_MODELS.md for integration and validation limits.

### Settlement SFX — 2026-09-27 (Playtest.7)

The core settlement sound effects in `assets/settlement/audio/` are **procedurally generated** using Python/NumPy sine synthesis, envelope shaping, and noise generation. Style inspiration: clear, punchy colony-sim audio reminiscent of The Settlers II (Amiga) character, but all sounds are original procedural synthesis—no sampling, ripping, or copyrighted audio sources.

**Generated SFX** (CC0 - original procedural work):
- `ui_click.wav` — UI button/selection confirmation (0.08s)
- `build_start.wav` — Construction hammer start (0.12s)
- `build_complete.wav` — Building finished chime (0.4s)
- `road.wav` — Road construction (0.12s)
- `delivery.wav` — Resource delivery confirmation (0.18s)
- `attack.wav` — Combat hit/impact (0.14s)
- `tower.wav` — Watchtower projectile launch (0.25s)
- `night.wav` — Night warning bell (0.8s)
- `enemy.wav` — Enemy spawn/appearance (0.3s)

**License**: CC0 Public Domain Dedication. These are original procedurally generated audio created for this project via `tools/generate_settlement_sfx.py`. No external samples, commercial assets, or copyrighted audio were used. Attribution optional.

**Retained**: `ambience.wav`, `music.wav`, `destroyed.wav`, and `soldier.wav` from earlier phases remain unchanged pending further audio direction.