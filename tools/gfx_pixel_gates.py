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

Thresholds (direction B, trin 1)
--------------------------------
  day   luminance σ in world           0.14 – 0.16
  day   mean HSV saturation            ≤ 0.60
  dusk  warm-pixel share (H 8–50°,
        S ≥ 0.28, V ≥ 0.18)            ≤ 0.70
  night near-black share (Y < 0.05)    ≤ 0.15
  night road/grass luminance ratio     ≥ 1.20
  HUD   not scored here; GFX-1 must
        not change theme/layout/fonts.

Classification
--------------
Grass: hue 55–145°, sat ≥ 0.12, Y 0.08–0.85
Road:  hue 18–48°,  sat 0.12–0.70, Y 0.10–0.90
"""
from __future__ import annotations

import argparse
import math
import os
import sys

try:
    from PIL import Image
except ImportError:
    print("gfx_pixel_gates: Pillow is required (python3 -m pip install pillow)")
    sys.exit(2)


DAY_SIGMA_MIN = 0.14
DAY_SIGMA_MAX = 0.16
SAT_MAX = 0.60
DUSK_WARM_MAX = 0.70
NIGHT_NEAR_BLACK_MAX = 0.15
NIGHT_ROAD_GRASS_MIN = 1.20
NEAR_BLACK_Y = 0.05
TOP_HUD = 90
BOTTOM_CONSOLE = 184


def _srgb_to_lin(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def luminance(r: float, g: float, b: float) -> float:
    return 0.2126 * _srgb_to_lin(r) + 0.7152 * _srgb_to_lin(g) + 0.0722 * _srgb_to_lin(b)


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


def world_pixels(im: Image.Image):
    rgb = im.convert("RGB")
    w, h = rgb.size
    y0 = min(TOP_HUD, h)
    y1 = max(y0 + 1, h - BOTTOM_CONSOLE)
    pix = rgb.load()
    for y in range(y0, y1):
        for x in range(w):
            yield pix[x, y]


def sample(path: str) -> dict:
    im = Image.open(path)
    ys: list[float] = []
    sats: list[float] = []
    warm = 0
    near_black = 0
    grass_y: list[float] = []
    road_y: list[float] = []
    n = 0
    for r8, g8, b8 in world_pixels(im):
        r, g, b = r8 / 255.0, g8 / 255.0, b8 / 255.0
        y = luminance(r, g, b)
        h, s, v = hsv(r, g, b)
        ys.append(y)
        sats.append(s)
        n += 1
        if y < NEAR_BLACK_Y:
            near_black += 1
        if 8.0 <= h <= 50.0 and s >= 0.28 and v >= 0.18:
            warm += 1
        if 55.0 <= h <= 145.0 and s >= 0.12 and 0.08 <= y <= 0.85:
            grass_y.append(y)
        elif 18.0 <= h <= 48.0 and 0.12 <= s <= 0.70 and 0.10 <= y <= 0.90:
            road_y.append(y)
    mean_y = sum(ys) / n if n else 0.0
    var = sum((v - mean_y) ** 2 for v in ys) / n if n else 0.0
    return {
        "pixels": n,
        "luma_mean": mean_y,
        "luma_sigma": math.sqrt(var),
        "sat_mean": sum(sats) / n if n else 0.0,
        "warm_share": warm / n if n else 0.0,
        "near_black_share": near_black / n if n else 0.0,
        "road_grass": (sum(road_y) / len(road_y)) / (sum(grass_y) / len(grass_y))
        if grass_y and road_y
        else 0.0,
        "grass_n": len(grass_y),
        "road_n": len(road_y),
    }


def classify(name: str) -> str:
    n = name.lower()
    if "night" in n or "raid" in n:
        return "night"
    if "dusk" in n or "sunset" in n or "evening" in n:
        return "dusk"
    if "day" in n or n.startswith("ui_0") or "opening" in n or "settlement" in n:
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
            if name.lower().endswith(".png") and not name.endswith("_compare.png"):
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
            f"road/grass={stats['road_grass']:.3f}"
        )
        for item in fails:
            print(f"    {item}")
    print("GFX_PIXEL_GATES %s" % ("PASS" if failed == 0 else "FAIL"))
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
