#!/usr/bin/env bash
# VisualLab candidate assets (lab only, never exported). Official sources, 0 kr, CC0.
# Places files under assets/visuallab/ (gitignored). Verifies SHA-256 of the downloaded archives.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"; DL="${VL_DL:-/workspace/vl_assets}"; mkdir -p "$DL"
KZ="$DL/kenney_fantasy-town-kit_2.0.zip"; QZ="$DL/quaternius_medieval_village_megakit_standard.zip"
[ -f "$KZ" ] || curl -sL https://kenney.nl/media/pages/assets/fantasy-town-kit/efe948d309-1754222374/kenney_fantasy-town-kit_2.0.zip -o "$KZ"
if [ ! -f "$QZ" ]; then
  # itch.io free download (official Quaternius store page, "name your own price", 0 paid)
  CK=$(mktemp); P=https://quaternius.itch.io/medieval-village-megakit
  curl -sL -c "$CK" "$P" -o "$CK.html"
  T=$(grep -o 'name="csrf_token" value="[^"]*"' "$CK.html" | head -1 | sed 's/.*value="//;s/"$//')
  U=$(curl -s -b "$CK" -X POST --data-urlencode "csrf_token=$T" "$P/file/12563480?source=view_game&as_props=1&after_download_lightbox=true" | python3 -c "import sys,json;print(json.load(sys.stdin)['url'])")
  curl -sL "$U" -o "$QZ"
fi
echo "1a7530c09f4d2fa2cdee259876f089334f8b1f27fa86a0c4f54ef86cdd8676ef  $KZ" | sha256sum -c -
echo "e60dea67c10f30dccccfbff92a7933f5ea5cfe99be0e2a0fa5118cceabeec5c4  $QZ" | sha256sum -c -
OUT="$ROOT/assets/visuallab"; rm -rf "$OUT"; mkdir -p "$OUT/kenney_ftk" "$OUT/quaternius_mvm"
T=$(mktemp -d); unzip -qo "$KZ" -d "$T/k"; unzip -qo "$QZ" -d "$T/q"
cp -r "$T/k/Models/GLB format/"* "$OUT/kenney_ftk/"; cp "$T/k/License.txt" "$OUT/kenney_ftk/"
cp -r "$T/q/Medieval Village MegaKit[Standard]/glTF/"* "$OUT/quaternius_mvm/"; cp "$T/q/Medieval Village MegaKit[Standard]/License_Standard.txt" "$OUT/quaternius_mvm/"
rm -rf "$T"; echo "VisualLab assets in $OUT"
