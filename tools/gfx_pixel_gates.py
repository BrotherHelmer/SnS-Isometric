#!/usr/bin/env python3
"""GFX-1 pixel gates for evidence / capture shots.

World mask (HUD excluded)
-------------------------
Evidence shots are 1280x720. HUD chrome is never scored:

  * top bar + loop bar: y < 90
  * bottom console (minimap / chronicle): y >= height - 184

The remaining rectangle is the world area. This matches the compare
regions in tools/linux_ci.sh (top bar 0–46, console height-184) with
the loop bar included so world metrics cannot pick HUD gold.

Brightness is measured in sRGB display space (Y'), not linear light.
Saturation is averaged only on pixels with Y' >= 0.10 so near-black
teal does not inflate the score. Night road/grass uses a road-tile
mask sidecar when present ({stem}.roads.json or {stem}.roads.png).

Thresholds are calibrated so the title painting itself passes.
"""
from __future__ import annotations

import argparse
import json
import math
import os
import sys

try:
    from PIL import Image
except ImportError:
    print("gfx_pixel_gates: Pillow is required (python3 -m pip install pillow)")
    sys.exit(2)


# Display-referred. Title art σ ≈ 0.188; day settlement sits near 0.12–0.20.
DAY_SIGMA_MIN = 0.09
DAY_SIGMA_MAX = 0.24
SAT_MAX = 0.60
SAT_LUMA_MIN = 0.10
DUSK_WARM_MAX = 0.70
NIGHT_NEAR_BLACK_MAX = 0.15
NIGHT_ROAD_GRASS_MIN = 1.20
# Darker than sRGB 63. Title forest sits well above this; crushed night does not.
NEAR_BLACK_Y = 8.0 / 255.0
TOP_HUD = 90
BOTTOM_CONSOLE = 184
MASK_WINDOW = 4


def display_luma(r: float, g: float, b: float) -> float:
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def hsv(r: float, g: float, b: float) -> tuple[float, float, float]:
    mx = max(r, g, b)
    mn = min(r, g, b)
    df = mx - mn
    if df == 0:
        h = 0.0
    elif mx == r:
        h = (60.0 * ((g - b) / df) + 360.0) % 360.0
    elif mx == g:
        h = 60.0 * ((b - r) / df) + 120.0
    else:
        h = 60.0 * ((r - g) / df) + 240.0
    s = 0.0 if mx == 0 else df / mx
    return h, s, mx


def world_rect(w: int, h: int) -> tuple[int, int, int, int]:
    y0 = min(TOP_HUD, h)
    y1 = max(y0 + 1, h - BOTTOM_CONSOLE)
    return 0, y0, w, y1


def _load_json_points(path: str) -> tuple[list[tuple[float, float]], list[tuple[float, float]]]:
    with open(path, "r", encoding="utf-8") as handle:
        data = json.load(handle)
    roads = [tuple(pt) for pt in data.get("roads", []) if len(pt) >= 2]
    grass = [tuple(pt) for pt in data.get("grass", []) if len(pt) >= 2]
    return roads, grass


def _mask_png_points(path: str, w: int, h: int) -> list[tuple[float, float]]:
    if not os.path.isfile(path):
        return []
    mask = Image.open(path).convert("L")
    mw, mh = mask.size
    pix = mask.load()
    points = []
    y0, y1 = world_rect(w, h)[1], world_rect(w, h)[3]
    for y in range(min(mh, y1)):
        if y < y0:
            continue
        for x in range(min(mw, w)):
            if pix[x, y] >= 160:
                points.append((float(x), float(y)))
    return points


def sidecar_points(shot_path: str, w: int, h: int) -> tuple[list[tuple[float, float]], list[tuple[float, float]]]:
    stem, _ext = os.path.splitext(shot_path)
    json_path = stem + ".roads.json"
    if os.path.isfile(json_path):
        return _load_json_points(json_path)
    roads = _mask_png_points(stem + ".roads.png", w, h)
    grass = _mask_png_points(stem + ".grass.png", w, h)
    return roads, grass


def _window_luma(pix, w: int, h: int, cx: float, cy: float) -> list[float]:
    x0, y0, x1, y1 = world_rect(w, h)
    xs = int(round(cx))
    ys = int(round(cy))
    values = []
    for oy in range(-MASK_WINDOW, MASK_WINDOW + 1):
        for ox in range(-MASK_WINDOW, MASK_WINDOW + 1):
            x = xs + ox
            y = ys + oy
            if x < x0 or x >= x1 or y < y0 or y >= y1:
                continue
            r8, g8, b8 = pix[x, y]
            values.append(display_luma(r8 / 255.0, g8 / 255.0, b8 / 255.0))
    return values


def sample(path: str) -> dict:
    im = Image.open(path)
    rgb = im.convert("RGB")
    w, h = rgb.size
    pix = rgb.load()
    x0, y0, x1, y1 = world_rect(w, h)
    ys: list[float] = []
    sats: list[float] = []
    warm = 0
    near_black = 0
    hue_grass_y: list[float] = []
    hue_road_y: list[float] = []
    n = 0
    for y in range(y0, y1):
        for x in range(x0, x1):
            r8, g8, b8 = pix[x, y]
            r, g, b = r8 / 255.0, g8 / 255.0, b8 / 255.0
            yv = display_luma(r, g, b)
            hue, sat, val = hsv(r, g, b)
            ys.append(yv)
            if yv >= SAT_LUMA_MIN:
                sats.append(sat)
            n += 1
            if yv < NEAR_BLACK_Y:
                near_black += 1
            if 8.0 <= hue <= 50.0 and sat >= 0.28 and val >= 0.18:
                warm += 1
            if 55.0 <= hue <= 145.0 and sat >= 0.12 and 0.04 <= yv <= 0.90:
                hue_grass_y.append(yv)
            elif 18.0 <= hue <= 48.0 and 0.12 <= sat <= 0.70 and 0.05 <= yv <= 0.95:
                hue_road_y.append(yv)
    roads, grass = sidecar_points(path, w, h)
    mask_road_y: list[float] = []
    mask_grass_y: list[float] = []
    for cx, cy in roads:
        mask_road_y.extend(_window_luma(pix, w, h, cx, cy))
    for cx, cy in grass:
        mask_grass_y.extend(_window_luma(pix, w, h, cx, cy))
    if mask_road_y and mask_grass_y:
        road_y, grass_y = mask_road_y, mask_grass_y
        mask_used = "sidecar"
    else:
        road_y, grass_y = hue_road_y, hue_grass_y
        mask_used = "hue"
    mean_y = sum(ys) / n if n else 0.0
    var = sum((v - mean_y) ** 2 for v in ys) / n if n else 0.0
    return {
        "pixels": n,
        "luma_mean": mean_y,
        "luma_sigma": math.sqrt(var),
        "sat_mean": sum(sats) / len(sats) if sats else 0.0,
        "warm_share": warm / n if n else 0.0,
        "near_black_share": near_black / n if n else 0.0,
        "road_grass": (sum(road_y) / len(road_y)) / (sum(grass_y) / len(grass_y))
        if grass_y and road_y
        else 0.0,
        "grass_n": len(grass_y),
        "road_n": len(road_y),
        "mask": mask_used,
    }


def classify(name: str) -> str:
    n = name.lower()
    if "night" in n or "raid" in n:
        return "night"
    if "dusk" in n or "sunset" in n or "evening" in n:
        return "dusk"
    if "day" in n or n.startswith("ui_0") or "opening" in n or "settlement" in n or "title" in n:
        return "day"
    return "day"


def gate(kind: str, stats: dict) -> list[str]:
    fails = []
    if kind == "day":
        sig = stats["luma_sigma"]
        if not (DAY_SIGMA_MIN <= sig <= DAY_SIGMA_MAX):
            fails.append(f"day luma σ {sig:.3f} not in {DAY_SIGMA_MIN:.2f}–{DAY_SIGMA_MAX:.2f}")
        if stats["sat_mean"] > SAT_MAX:
            fails.append(f"day sat {stats['sat_mean']:.3f} > {SAT_MAX:.2f}")
    elif kind == "dusk":
        if stats["warm_share"] > DUSK_WARM_MAX:
            fails.append(f"dusk warm share {stats['warm_share']:.3f} > {DUSK_WARM_MAX:.2f}")
        if stats["sat_mean"] > SAT_MAX:
            fails.append(f"dusk sat {stats['sat_mean']:.3f} > {SAT_MAX:.2f}")
    elif kind == "night":
        if stats["near_black_share"] > NIGHT_NEAR_BLACK_MAX:
            fails.append(
                f"night near-black {stats['near_black_share']:.3f} > {NIGHT_NEAR_BLACK_MAX:.2f}"
            )
        if stats["road_n"] < 40 or stats["grass_n"] < 40:
            fails.append(
                f"night road/grass samples too small (road={stats['road_n']} grass={stats['grass_n']})"
            )
        elif stats["road_grass"] < NIGHT_ROAD_GRASS_MIN:
            fails.append(
                f"night road/grass {stats['road_grass']:.3f} < {NIGHT_ROAD_GRASS_MIN:.2f}"
            )
    return fails


def find_shots(root: str) -> list[str]:
    names = []
    for dirpath, _dirs, files in os.walk(root):
        for name in files:
            low = name.lower()
            if not low.endswith(".png"):
                continue
            if name.endswith("_compare.png") or name.endswith(".roads.png") or name.endswith(".grass.png"):
                continue
            names.append(os.path.join(dirpath, name))
    return sorted(names)


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("paths", nargs="+", help="shot files or folders")
    p.add_argument("--period", choices=["day", "dusk", "night", "auto"], default="auto")
    args = p.parse_args()
    shots: list[str] = []
    for path in args.paths:
        if os.path.isdir(path):
            shots.extend(find_shots(path))
        elif os.path.isfile(path):
            shots.append(path)
    if not shots:
        print("gfx_pixel_gates: no PNG shots found")
        return 2
    failed = 0
    for shot in shots:
        kind = args.period if args.period != "auto" else classify(os.path.basename(shot))
        stats = sample(shot)
        fails = gate(kind, stats)
        status = "PASS" if not fails else "FAIL"
        if fails:
            failed += 1
        print(
            f"{status} {os.path.basename(shot)} period={kind} "
            f"σ={stats['luma_sigma']:.3f} sat={stats['sat_mean']:.3f} "
            f"warm={stats['warm_share']:.3f} black={stats['near_black_share']:.3f} "
            f"road/grass={stats['road_grass']:.3f} mask={stats['mask']}"
        )
        for item in fails:
            print(f"    {item}")
    print("GFX_PIXEL_GATES %s" % ("PASS" if failed == 0 else "FAIL"))
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
