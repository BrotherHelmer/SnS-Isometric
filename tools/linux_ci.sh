#!/usr/bin/env bash
# Shard & Sovereign - Linux build + test pipeline (port of build_release.ps1,
# verify_release.ps1 and test_release_package.ps1, plus the in-engine
# --evidence-ui capture under Xvfb).
#
# Usage: tools/linux_ci.sh [--repo DIR] [--out DIR] [--ref DIR] [--ref-label TXT] [--label TXT]
#                          [--skip-windows] [--timeout SEC] [--quick]
#   --repo  project checkout to test (default: the checkout this script lives in)
#   --out   output root (default: /tmp/sns_ci_<timestamp>)
#   --ref   folder with reference ui_0X*.png shots to compare the capture with
#   --ref-label / --label  captions for the side-by-side compare images
#
# Every Godot process gets its own XDG_DATA_HOME/XDG_CONFIG_HOME/XDG_CACHE_HOME
# under the output root, so no real user data (~/.local/share) is ever touched.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_HOME="${GODOT_HOME:-/home/box/godot/4.7}"
GODOT="$GODOT_HOME/Godot_v4.7-stable_linux.x86_64"
TEMPLATES="$GODOT_HOME/templates"
EXPECTED_ENGINE="4.7.stable.official.5b4e0cb0f"
OUT="/tmp/sns_ci_$(date +%Y%m%d_%H%M%S)"
REF=""
SKIP_WINDOWS=0
QUICK=0
TIMEOUT=180
SEED=260821
REF_LABEL="Reference"
LABEL="This run (Linux, Xvfb + lavapipe)"
# Extra checks beyond the 22 Windows release tests; reported separately so the
# 22/22 figure stays comparable with verify_release.ps1. Skipped if absent.
EXTRA_TESTS=(t_sns_ui_leftovers t_sns_ui_look t_gfx_light t_raid_combat t_raid_combat_log t_night_audio_sweep t_night_build t_fog_reveal t_intentions t_playtest_log t_scout_direction t_fog_discoveries t_economy_feedback t_raid_warnings t_placement_quality)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --out) OUT="$2"; shift 2;;
    --repo) REPO="$(cd "$2" && pwd)"; shift 2;;
    --ref-label) REF_LABEL="$2"; shift 2;;
    --label) LABEL="$2"; shift 2;;
    --ref) REF="$2"; shift 2;;
    --skip-windows) SKIP_WINDOWS=1; shift;;
    --quick) QUICK=1; shift;;  # dev only: skip parse check + verification
    --timeout) TIMEOUT="$2"; shift 2;;
    *) echo "unknown arg $1"; exit 2;;
  esac
done
# Mesa lavapipe so Xvfb gate/evidence shots stay on Vulkan Forward+.
# An empty VK_ICD_FILENAMES lets Godot fall back to OpenGL Compatibility,
# which scores a black-green settlement and fails every GFX-1 gate.
export VK_ICD_FILENAMES="${VK_ICD_FILENAMES:-/usr/share/vulkan/icd.d/lvp_icd.json}"
mkdir -p "$OUT"/{logs,users,export/linux,export/windows,evidence,smoke}
SUMMARY="$OUT/summary.txt"
: > "$SUMMARY"
T0=$(date +%s)
FAILED=0

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$SUMMARY"; }
result() { # name status detail
  printf '%-26s %-5s %s\n' "$1" "$2" "$3" | tee -a "$SUMMARY"
  [[ "$2" == "PASS" || "$2" == "SKIP" ]] || FAILED=1
}
# Isolated user dirs per run label.
with_user() { local label="$1"; shift
  local u="$OUT/users/$label"; mkdir -p "$u"/{data,config,cache}
  # Export templates must be visible to the editor in the isolated data dir.
  mkdir -p "$u/data/godot/export_templates"
  ln -sfn "$TEMPLATES" "$u/data/godot/export_templates/4.7.stable"
  XDG_DATA_HOME="$u/data" XDG_CONFIG_HOME="$u/config" XDG_CACHE_HOME="$u/cache" HOME="$u" "$@"
}
# Same error filter as the Windows scripts.
error_lines() { grep -E '^(SCRIPT ERROR:|ERROR:|FAIL[: ]|.*_FAIL)' "$@" 2>/dev/null | grep -v '^ERROR: Failed to read the root certificate store\.' || true; }

log "repo=$REPO rev=$(git -C "$REPO" rev-parse HEAD) dirty=$(git -C "$REPO" status --porcelain | wc -l) out=$OUT vk_icd=$VK_ICD_FILENAMES"
ENGINE_VERSION="$("$GODOT" --headless --version 2>/dev/null | tail -1)"
[[ "$ENGINE_VERSION" == "$EXPECTED_ENGINE" ]] && result engine PASS "$ENGINE_VERSION" || result engine FAIL "got '$ENGINE_VERSION' want $EXPECTED_ENGINE"

# 1) Headless import (build_release.ps1 step 1).
log "import"
with_user import "$GODOT" --headless --path "$REPO" --editor --import --log-file "$OUT/logs/import.log" > "$OUT/logs/import.console.txt" 2>&1
code=$?; errs=$(error_lines "$OUT/logs/import.console.txt" | wc -l)
[[ $code -eq 0 && $errs -eq 0 ]] && result import PASS "exit=$code errors=0" || result import FAIL "exit=$code errors=$errs"

if [[ $QUICK -eq 0 ]]; then
# 2) Parse check: --check-only on every GDScript in src/, tests/, tools/.
log "parse check"
parse_errors=0; parse_files=0
: > "$OUT/logs/parse_check.txt"
while IFS= read -r f; do
  parse_files=$((parse_files+1))
  outp=$(with_user parse "$GODOT" --headless --path "$REPO" --check-only --script "res://$f" 2>&1)
  n=$(grep -cE 'Parse Error|SCRIPT ERROR|Compile Error' <<<"$outp")
  if [[ $n -gt 0 ]]; then parse_errors=$((parse_errors+n)); { echo "== $f"; grep -E 'Parse Error|SCRIPT ERROR|Compile Error' <<<"$outp"; } >> "$OUT/logs/parse_check.txt"; fi
done < <(cd "$REPO" && find src tests tools -name '*.gd' | sort)
[[ $parse_errors -eq 0 ]] && result parse_check PASS "$parse_files scripts, 0 parse errors" || result parse_check FAIL "$parse_errors error lines (logs/parse_check.txt)"

# 3) Export packing audit (same python audit as Windows).
log "export packing audit"
( cd "$REPO" && python3 tools/audit_export_packing.py ) > "$OUT/logs/export_audit.txt" 2>&1
code=$?; missing=$(grep -oE 'MISSING FROM EXPORT: [0-9]+' "$OUT/logs/export_audit.txt" | grep -oE '[0-9]+$')
[[ $code -eq 0 ]] && result export_audit PASS "missing=${missing:-?}" || result export_audit FAIL "exit=$code missing=${missing:-?}"

# 4) Release verification: the 22 tests from verify_release.ps1, same pass rule.
TESTS=(release_save_safety release_logistics_safety release_session_safety release_outpost_assault release_presentation_regressions opening_style_models settlement_style_capture phase4_2_parse_smoke godot_rebuild_smoke godot_rivalry_smoke phase8_bakery_haul phase4_wyrdfall_smoke phase4_full_run_harness phase4_2_human_playtest_rescue phase6_presence phase7_review_evidence phase5_start_menu_layout phase5_settlement_speak phase3_ui_interaction_smoke phase3_2_real_playthrough playtest31_audio_cheer playtest31_ui_majors)
log "release verification (${#TESTS[@]} tests)"
vpass=0; vfail=()
for t in "${TESTS[@]}"; do
  o="$OUT/logs/test_$t.txt"
  timeout "$TIMEOUT" bash -c "$(declare -f with_user); OUT='$OUT' TEMPLATES='$TEMPLATES' with_user 'test_$t' '$GODOT' --headless --path '$REPO' --log-file '$OUT/logs/test_$t.log' --script 'res://tests/$t.gd'" > "$o" 2>&1
  code=$?
  errs=$(error_lines "$o" | wc -l)
  if [[ $code -eq 0 && $errs -eq 0 ]] && grep -qE '^\w+ PASS' "$o"; then vpass=$((vpass+1)); echo "  $t passed=True exit=$code" | tee -a "$SUMMARY"
  else vfail+=("$t"); echo "  $t passed=False exit=$code" | tee -a "$SUMMARY"; error_lines "$o" | head -5 | sed 's/^/    /' | tee -a "$SUMMARY"; fi
done
[[ ${#vfail[@]} -eq 0 ]] && result release_verification PASS "$vpass/${#TESTS[@]}" || result release_verification FAIL "$vpass/${#TESTS[@]} failed: ${vfail[*]}"

# 4b) Extra tests (not part of the Windows 22).
for t in "${EXTRA_TESTS[@]}"; do
  if [[ ! -f "$REPO/tests/$t.gd" ]]; then result "extra:$t" SKIP "not in this revision"; continue; fi
  o="$OUT/logs/test_$t.txt"
  timeout "$TIMEOUT" bash -c "$(declare -f with_user); OUT='$OUT' TEMPLATES='$TEMPLATES' with_user 'test_$t' '$GODOT' --headless --path '$REPO' --log-file '$OUT/logs/test_$t.log' --script 'res://tests/$t.gd'" > "$o" 2>&1
  code=$?; errs=$(error_lines "$o" | wc -l)
  npass=$(grep -c '^PASS ' "$o"); nfail=$(grep -c '^FAIL ' "$o")
  if [[ $code -eq 0 && $errs -eq 0 ]] && grep -qE '^\w+ PASS' "$o"; then result "extra:$t" PASS "$npass checks"
  else result "extra:$t" FAIL "exit=$code fail=$nfail errors=$errs"; error_lines "$o" | head -5 | sed 's/^/    /' | tee -a "$SUMMARY"; fi
done

# 4c) Real-state GFX-1 gates from the 18-step save (written by phase3_2_real_playthrough).
log "gfx pixel gates (18-step Day 3 / dusk / Night 2)"
GATES="$OUT/gfx_gates"
mkdir -p "$GATES"
if [[ ! -f "$REPO/artifacts/phase3_2/persistence/eighteen_step_playthrough.json" ]]; then
  result gfx_pixel_gates FAIL "missing eighteen_step_playthrough.json"
else
  timeout 180 xvfb-run -a -s "-screen 0 1280x720x24" bash -c "$(declare -f with_user); export OUT='$OUT' TEMPLATES='$TEMPLATES' GFX_GATE_OUT='$GATES'; with_user gfx_gates '$GODOT' --path '$REPO' --audio-driver Dummy --resolution 1280x720 --script res://tests/t_gfx_gate_shots.gd" > "$OUT/logs/gfx_gates_stdout.txt" 2>&1
  code=$?
  renderer=$(grep -m1 -E 'Vulkan|OpenGL|Forward\+|GFX_GATE_RENDERER' "$OUT/logs/gfx_gates_stdout.txt" || true)
  if grep -qE 'switching to OpenGL|OpenGL API|Compatibility' "$OUT/logs/gfx_gates_stdout.txt"; then
    result gfx_pixel_gates FAIL "not Forward+/Vulkan: $renderer"
  else
    python3 "$REPO/tools/gfx_pixel_gates.py" "$GATES/gfx_day.png" "$GATES/gfx_dusk.png" "$GATES/gfx_night.png" | tee "$OUT/logs/gfx_gates.txt"
    gate_code=${PIPESTATUS[0]}
    [[ $code -eq 0 && $gate_code -eq 0 ]] && result gfx_pixel_gates PASS "$(grep GFX_PIXEL_GATES "$OUT/logs/gfx_gates.txt") renderer=$renderer" || result gfx_pixel_gates FAIL "capture=$code gates=$gate_code renderer=$renderer"
  fi
fi

else result parse_check SKIP "--quick"; result release_verification SKIP "--quick"; FAILED=1; fi  # --quick never passes

# 5) Export. Done in a scratch copy so the working tree (export_presets.cfg) is never modified.
log "export (scratch copy)"
SCRATCH="$OUT/scratch_project"
rm -rf "$SCRATCH"; mkdir -p "$SCRATCH"
tar -C "$REPO" --exclude=./.git --exclude=./artifacts --exclude=./dist -cf - . | tar -C "$SCRATCH" -xf -
mkdir -p "$SCRATCH/.tools/godot-4.7" "$SCRATCH/artifacts/release_candidate"
ln -sfn "$TEMPLATES" "$SCRATCH/.tools/godot-4.7/templates"
python3 - "$SCRATCH/export_presets.cfg" <<'PY'
import re, sys
p = sys.argv[1]; s = open(p).read()
head = s[s.index('[preset.0]'):s.index('[preset.0.options]')]
# Windows from Linux: rcedit is not available, so resources (icon/version) are not patched.
s = s.replace('application/modify_resources=true', 'application/modify_resources=false')
linux = head.replace('[preset.0]', '[preset.1]').replace('name="Windows Desktop"', 'name="Linux CI"').replace('platform="Windows Desktop"', 'platform="Linux"')
linux = re.sub(r'export_path="[^"]*"', 'export_path=""', linux)
linux += '[preset.1.options]\n\ncustom_template/debug=""\ncustom_template/release=".tools/godot-4.7/templates/linux_release.x86_64"\ndebug/export_console_wrapper=0\nbinary_format/embed_pck=false\ntexture_format/s3tc_bptc=true\ntexture_format/etc2_astc=false\nbinary_format/architecture="x86_64"\n\n'
open(p, 'w').write(s.rstrip('\n') + '\n\n' + linux)
PY
with_user notices "$GODOT" --headless --path "$SCRATCH" --script res://tools/write_engine_notices.gd > "$OUT/logs/notices.console.txt" 2>&1
grep -q 'ENGINE_NOTICES PASS' "$OUT/logs/notices.console.txt" && [[ $(error_lines "$OUT/logs/notices.console.txt" | wc -l) -eq 0 ]] && result engine_notices PASS "" || result engine_notices FAIL "logs/notices.console.txt"
LINUX_BIN="$OUT/export/linux/ShardAndSovereign.x86_64"
with_user export_linux "$GODOT" --headless --path "$SCRATCH" --export-release "Linux CI" "$LINUX_BIN" --log-file "$OUT/logs/export_linux.log" > "$OUT/logs/export_linux.console.txt" 2>&1
code=$?; errs=$(error_lines "$OUT/logs/export_linux.console.txt" | wc -l)
[[ $code -eq 0 && $errs -eq 0 && -s "$OUT/export/linux/ShardAndSovereign.pck" ]] && result export_linux PASS "$(du -h "$OUT/export/linux/ShardAndSovereign.pck" | cut -f1) pck" || result export_linux FAIL "exit=$code errors=$errs"
if [[ $SKIP_WINDOWS -eq 0 ]]; then
  with_user export_windows "$GODOT" --headless --path "$SCRATCH" --export-release "Windows Desktop" "$OUT/export/windows/ShardAndSovereign.exe" --log-file "$OUT/logs/export_windows.log" > "$OUT/logs/export_windows.console.txt" 2>&1
  code=$?; errs=$(error_lines "$OUT/logs/export_windows.console.txt" | wc -l)
  [[ $code -eq 0 && $errs -eq 0 && -s "$OUT/export/windows/ShardAndSovereign.pck" ]] && result export_windows PASS "bonus; exe resources not patched (no rcedit)" || result export_windows FAIL "exit=$code errors=$errs (bonus)"
  cp "$SCRATCH/artifacts/release_candidate/GODOT_COPYRIGHT.txt" "$OUT/export/windows/" 2>/dev/null
fi
cp "$SCRATCH/artifacts/release_candidate/GODOT_COPYRIGHT.txt" "$OUT/export/linux/" 2>/dev/null
( cd "$OUT/export" && sha256sum linux/* windows/* 2>/dev/null > SHA256SUMS.txt )

# 6) Smoke test (test_release_package.ps1): packaged game, --verify-release soak.
log "smoke test (packaged Linux build, headless, 8 s soak)"
cp "$OUT"/export/linux/ShardAndSovereign.{x86_64,pck} "$OUT/smoke/" 2>/dev/null
timeout 90 bash -c "$(declare -f with_user); export OUT='$OUT' TEMPLATES='$TEMPLATES'; cd '$OUT/smoke' && with_user smoke ./ShardAndSovereign.x86_64 --log-file '$OUT/smoke/validation.log' --headless -- --verify-release --soak-seconds=8" > "$OUT/smoke/stdout.txt" 2>&1
code=$?; errs=$(grep -E '^(SCRIPT ERROR:|ERROR:|FAIL )' "$OUT/smoke/stdout.txt" | grep -vc 'root certificate store')
grep -q 'RELEASE_PACKAGE_PROBE PASS' "$OUT/smoke/stdout.txt" && [[ $code -eq 0 && $errs -eq 0 ]] && result smoke PASS "RELEASE_PACKAGE_PROBE PASS" || result smoke FAIL "exit=$code errors=$errs"

# 7) In-engine UI evidence capture under Xvfb (Vulkan via Mesa lavapipe).
log "evidence capture (xvfb, 1280x720)"
EV="$OUT/evidence"
timeout 300 xvfb-run -a -s "-screen 0 1280x720x24" bash -c "$(declare -f with_user); export OUT='$OUT' TEMPLATES='$TEMPLATES'; cd '$OUT/smoke' && with_user evidence ./ShardAndSovereign.x86_64 --audio-driver Dummy --resolution 1280x720 -- --seed=$SEED --evidence-ui='$EV' --audio-master=0.0" > "$OUT/logs/evidence_stdout.txt" 2>&1
code=$?; shots=$(ls "$EV"/ui_0*.png 2>/dev/null | wc -l)
renderer=$(grep -m1 -E 'Vulkan|OpenGL' "$OUT/logs/evidence_stdout.txt")
script_errs=$(grep -c 'SCRIPT ERROR' "$OUT/logs/evidence_stdout.txt" || true)
[[ $code -eq 0 && $shots -ge 5 && $script_errs -eq 0 ]] && result evidence_capture PASS "$shots shots; $renderer" || result evidence_capture FAIL "exit=$code shots=$shots script_errors=$script_errs"

# 8) Optional comparison with reference shots.
if [[ -n "$REF" && -d "$REF" ]]; then
  python3 - "$EV" "$REF" "$OUT/compare" "$REF_LABEL" "$LABEL" <<'PY' | tee -a "$SUMMARY"
import sys, os
from PIL import Image, ImageChops, ImageDraw, ImageStat
ev, ref, out, ref_label, label = sys.argv[1:6]; os.makedirs(out, exist_ok=True)
for name in sorted(os.listdir(ref)):
    if not (name.startswith('ui_0') and name.endswith('.png')): continue
    a = os.path.join(ref, name); b = os.path.join(ev, name)
    if not os.path.exists(b): print(f"  compare {name}: MISSING in capture"); continue
    A = Image.open(a).convert('RGB'); B = Image.open(b).convert('RGB')
    if A.size != B.size: B = B.resize(A.size)
    d = ImageChops.difference(A, B); st = ImageStat.Stat(d.convert('L'))
    hist = d.convert('L').histogram(); frac = sum(hist[25:]) / (A.width * A.height)
    # HUD-only regions (top bar + bottom console) vs whole frame
    def region(y0, y1):
        r = d.convert('L').crop((0, y0, A.width, y1)); return ImageStat.Stat(r).mean[0]
    print(f"  compare {name}: mean_abs_diff={st.mean[0]:.2f} changed_px(>24)={frac*100:.1f}% top_bar={region(0,46):.2f} console={region(A.height-184,A.height):.2f}")
    W = A.width * 2 + 10; c = Image.new('RGB', (W, A.height + 28), (20, 20, 20)); c.paste(A, (0, 28)); c.paste(B, (A.width + 10, 28))
    dr = ImageDraw.Draw(c); dr.text((8, 8), f"{ref_label} - {name}", fill=(230,230,230)); dr.text((A.width + 18, 8), label, fill=(240,200,128))
    c.save(os.path.join(out, name.replace('.png', '_compare.png')))
PY
  [[ ${PIPESTATUS[0]} -eq 0 ]] && result compare PASS "$OUT/compare" || result compare FAIL "python3 + Pillow required"
fi

T1=$(date +%s)
log "total runtime $((T1-T0)) s"
if [[ $FAILED -eq 0 ]]; then log "LINUX_CI PASS"; exit 0; else log "LINUX_CI FAIL"; exit 1; fi
