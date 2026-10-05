"""Render the T-SNS-UI interface art (frames, buttons, resource icons).

Self-made, deterministic, PIL only. Palette taken from the title art
(title_settlement_v1: slate dusk, weathered stone, lantern gold, Wyrd teal).
Run: python tools/generate_ui_art.py
"""
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "settlement3d" / "runtime" / "interface" / "ui"
SS = 4  # supersampling

SLATE_TOP = (27, 36, 40)
SLATE_BOTTOM = (15, 21, 24)
STONE = (92, 92, 84)
STONE_HI = (138, 135, 120)
STONE_LO = (44, 44, 40)
GOLD = (196, 150, 84)
GOLD_HI = (240, 200, 128)
GOLD_LO = (112, 80, 42)


def rng(seed: int) -> random.Random:
    return random.Random(seed)


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(len(a)))


def noise_fill(img: Image.Image, box, top, bottom, seed, amount=6):
    r = rng(seed)
    x0, y0, x1, y1 = box
    px = img.load()
    for y in range(y0, y1):
        t = (y - y0) / max(1, (y1 - y0 - 1))
        base = lerp(top, bottom, t)
        for x in range(x0, x1):
            n = r.randint(-amount, amount)
            px[x, y] = (max(0, min(255, base[0] + n)), max(0, min(255, base[1] + n)), max(0, min(255, base[2] + n)), 255)


def stone_border(draw: ImageDraw.ImageDraw, w, h, t, seed):
    """Weathered stone blocks around the edge, bevel lit from the top-left."""
    r = rng(seed)
    # base band
    draw.rectangle([0, 0, w - 1, h - 1], outline=None, fill=None)
    for side in range(4):
        pos = 0
        length = w if side in (0, 2) else h
        while pos < length:
            block = r.randint(int(t * 1.6), int(t * 3.0))
            shade = r.randint(-10, 10)
            col = tuple(max(0, min(255, c + shade)) for c in STONE) + (255,)
            if side == 0:
                rect = [pos, 0, min(w - 1, pos + block), t - 1]
            elif side == 2:
                rect = [pos, h - t, min(w - 1, pos + block), h - 1]
            elif side == 1:
                rect = [w - t, pos, w - 1, min(h - 1, pos + block)]
            else:
                rect = [0, pos, t - 1, min(h - 1, pos + block)]
            draw.rectangle(rect, fill=col)
            # mortar line
            if side in (0, 2):
                draw.line([rect[2], rect[1], rect[2], rect[3]], fill=STONE_LO + (255,), width=max(1, SS // 2))
            else:
                draw.line([rect[0], rect[3], rect[2], rect[3]], fill=STONE_LO + (255,), width=max(1, SS // 2))
            pos += block
    # bevel: highlight top/left outer edge, shadow bottom/right
    lw = max(1, SS)
    draw.line([0, 0, w - 1, 0], fill=STONE_HI + (255,), width=lw)
    draw.line([0, 0, 0, h - 1], fill=STONE_HI + (255,), width=lw)
    draw.line([0, h - 1, w - 1, h - 1], fill=(20, 20, 18, 255), width=lw)
    draw.line([w - 1, 0, w - 1, h - 1], fill=(20, 20, 18, 255), width=lw)
    # inner shadow edge next to the slate
    draw.rectangle([t, t, w - t - 1, h - t - 1], outline=(10, 12, 12, 255), width=lw)


def gold_trim(draw, w, h, inset, width):
    draw.rectangle([inset, inset, w - inset - 1, h - inset - 1], outline=GOLD_LO + (255,), width=width + SS // 2)
    draw.rectangle([inset, inset, w - inset - 1, h - inset - 1], outline=GOLD + (255,), width=width)
    draw.line([inset, inset, w - inset - 1, inset], fill=GOLD_HI + (255,), width=max(1, width // 2))


def rivet(draw, cx, cy, rad):
    draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=GOLD_LO + (255,))
    draw.ellipse([cx - rad * 0.75, cy - rad * 0.75, cx + rad * 0.55, cy + rad * 0.55], fill=GOLD + (255,))
    draw.ellipse([cx - rad * 0.45, cy - rad * 0.5, cx - rad * 0.05, cy - rad * 0.1], fill=GOLD_HI + (255,))


def frame(name, size, border, trim_inset, seed, rivets=True, alpha=235, top=SLATE_TOP, bottom=SLATE_BOTTOM):
    w = h = size * SS
    t = border * SS
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    noise_fill(img, (0, 0, w, h), top, bottom, seed, 5)
    d = ImageDraw.Draw(img)
    stone_border(d, w, h, t, seed + 1)
    gold_trim(d, w, h, t + trim_inset * SS, max(1, SS))
    if rivets:
        for cx, cy in ((t // 2, t // 2), (w - t // 2, t // 2), (t // 2, h - t // 2), (w - t // 2, h - t // 2)):
            rivet(d, cx, cy, t * 0.42)
    img = img.resize((size, size), Image.LANCZOS)
    # interior alpha (slate) slightly translucent, border opaque
    px = img.load()
    inner = border + trim_inset + 1
    for y in range(inner, size - inner):
        for x in range(inner, size - inner):
            r_, g_, b_, a_ = px[x, y]
            px[x, y] = (r_, g_, b_, alpha)
    img.save(OUT / f"{name}.png")


def button(name, fill_top, fill_bottom, edge, seed):
    size = 32
    w = h = size * SS
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rad = 5 * SS
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=rad, fill=(12, 12, 10, 255))
    inner = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    noise_fill(inner, (0, 0, w, h), fill_top, fill_bottom, seed, 4)
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([2 * SS, 2 * SS, w - 1 - 2 * SS, h - 1 - 2 * SS], radius=rad - SS, fill=255)
    img.paste(inner, (0, 0), mask)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([2 * SS, 2 * SS, w - 1 - 2 * SS, h - 1 - 2 * SS], radius=rad - SS, outline=edge + (255,), width=SS)
    d.line([4 * SS, 3 * SS, w - 4 * SS, 3 * SS], fill=tuple(min(255, c + 40) for c in edge) + (200,), width=SS)
    img.resize((size, size), Image.LANCZOS).save(OUT / f"{name}.png")


def icon_canvas():
    s = 48 * SS
    return Image.new("RGBA", (s, s), (0, 0, 0, 0)), s


def finish_icon(img, name):
    # soft dark outline for legibility on any panel
    alpha = img.split()[3]
    halo = alpha.filter(ImageFilter.MaxFilter(3 * SS + 1)).filter(ImageFilter.GaussianBlur(SS))
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.putalpha(halo.point(lambda v: int(v * 0.85)))
    out = Image.alpha_composite(out, img)
    out.resize((48, 48), Image.LANCZOS).save(OUT / f"icon_{name}.png")


def S(v):
    return v * SS


def icon_wood():
    img, s = icon_canvas(); d = ImageDraw.Draw(img)
    for i, (y, x0) in enumerate(((30, 6), (21, 10), (12, 8))):
        d.rounded_rectangle([S(x0), S(y), S(x0 + 30), S(y + 9)], radius=S(4), fill=(126, 82, 44, 255), outline=(62, 38, 20, 255), width=S(1))
        d.ellipse([S(x0 + 26), S(y), S(x0 + 35), S(y + 9)], fill=(214, 170, 110, 255), outline=(98, 62, 30, 255), width=S(1))
        d.ellipse([S(x0 + 29), S(y + 3), S(x0 + 32), S(y + 6)], outline=(150, 105, 60, 255), width=S(1))
    finish_icon(img, "wood")


def icon_planks():
    img, s = icon_canvas(); d = ImageDraw.Draw(img)
    for i, y in enumerate((10, 20, 30)):
        d.polygon([(S(6), S(y + 4)), (S(38), S(y)), (S(42), S(y + 5)), (S(10), S(y + 9))], fill=(206, 160, 98, 255) if i % 2 == 0 else (184, 138, 80, 255), outline=(98, 66, 34, 255))
        d.line([S(12), S(y + 6), S(36), S(y + 3)], fill=(150, 108, 60, 255), width=S(1))
    finish_icon(img, "planks")


def icon_stone():
    img, s = icon_canvas(); d = ImageDraw.Draw(img)
    d.polygon([(S(6), S(38)), (S(10), S(22)), (S(22), S(14)), (S(30), S(20)), (S(28), S(38))], fill=(150, 150, 142, 255), outline=(62, 62, 58, 255))
    d.polygon([(S(22), S(38)), (S(26), S(24)), (S(36), S(18)), (S(44), S(28)), (S(42), S(38))], fill=(122, 124, 118, 255), outline=(52, 52, 50, 255))
    d.line([S(12), S(24), S(22), S(17)], fill=(206, 204, 192, 255), width=S(2))
    d.line([S(28), S(25), S(36), S(20)], fill=(180, 180, 170, 255), width=S(2))
    finish_icon(img, "stone")


def icon_wheat():
    img, s = icon_canvas(); d = ImageDraw.Draw(img)
    for ang in (-18, 0, 18):
        a = math.radians(ang)
        bx, by = S(24), S(42)
        tx, ty = bx + math.sin(a) * S(34), by - math.cos(a) * S(34)
        d.line([bx, by, tx, ty], fill=(150, 118, 48, 255), width=S(2))
        for k in range(5):
            t = 0.45 + k * 0.12
            cx, cy = bx + (tx - bx) * t, by + (ty - by) * t
            for side in (-1, 1):
                ox = math.cos(a) * S(4) * side
                oy = math.sin(a) * S(4) * side
                d.ellipse([cx + ox - S(3), cy + oy - S(4.5), cx + ox + S(3), cy + oy + S(4.5)], fill=(236, 196, 92, 255), outline=(150, 112, 40, 255))
    finish_icon(img, "wheat")


def icon_bread():
    img, s = icon_canvas(); d = ImageDraw.Draw(img)
    d.ellipse([S(5), S(14), S(43), S(40)], fill=(196, 128, 62, 255), outline=(98, 58, 24, 255), width=S(1))
    d.ellipse([S(9), S(15), S(39), S(30)], fill=(222, 160, 86, 255))
    for x in (15, 23, 31):
        d.line([S(x), S(18), S(x + 5), S(27)], fill=(246, 214, 150, 255), width=S(2))
    finish_icon(img, "bread")


def icon_wyrd():
    img, s = icon_canvas(); d = ImageDraw.Draw(img)
    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([S(6), S(8), S(42), S(44)], fill=(80, 210, 230, 110))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(S(4))))
    d = ImageDraw.Draw(img)
    d.polygon([(S(24), S(4)), (S(34), S(20)), (S(28), S(44)), (S(18), S(44)), (S(13), S(20))], fill=(88, 196, 220, 255), outline=(26, 80, 104, 255))
    d.polygon([(S(24), S(4)), (S(34), S(20)), (S(24), S(24))], fill=(170, 238, 250, 255))
    d.line([S(24), S(24), S(23), S(44)], fill=(40, 120, 150, 255), width=S(1))
    finish_icon(img, "wyrd")


def icon_pop():
    img, s = icon_canvas(); d = ImageDraw.Draw(img)
    for ox, col in ((-8, (120, 150, 160, 255)), (8, (120, 150, 160, 255)), (0, (206, 214, 200, 255))):
        d.ellipse([S(19 + ox), S(8 + (0 if ox == 0 else 4)), S(29 + ox), S(18 + (0 if ox == 0 else 4))], fill=col, outline=(30, 40, 44, 255))
        d.rounded_rectangle([S(15 + ox), S(20 + (0 if ox == 0 else 4)), S(33 + ox), S(42)], radius=S(6), fill=col, outline=(30, 40, 44, 255))
    finish_icon(img, "pop")


def icon_sun():
    img, s = icon_canvas(); d = ImageDraw.Draw(img)
    for k in range(8):
        a = k * math.pi / 4
        d.line([S(24) + math.cos(a) * S(12), S(24) + math.sin(a) * S(12), S(24) + math.cos(a) * S(20), S(24) + math.sin(a) * S(20)], fill=(250, 196, 96, 255), width=S(3))
    d.ellipse([S(13), S(13), S(35), S(35)], fill=(255, 212, 110, 255), outline=(170, 110, 30, 255), width=S(1))
    finish_icon(img, "sun")


def icon_moon():
    img, s = icon_canvas(); d = ImageDraw.Draw(img)
    d.ellipse([S(8), S(8), S(40), S(40)], fill=(190, 206, 232, 255))
    d.ellipse([S(17), S(4), S(45), S(34)], fill=(0, 0, 0, 0))
    finish_icon(img, "moon")


def icon_soldier():
    img, s = icon_canvas(); d = ImageDraw.Draw(img)
    d.polygon([(S(10), S(8)), (S(38), S(8)), (S(38), S(24)), (S(24), S(42)), (S(10), S(24))], fill=(63, 115, 128, 255), outline=(200, 170, 100, 255))
    # Upright sword: blade, crossguard, grip and pommel (reads as "soldier", not a cross).
    d.polygon([(S(22.5), S(28)), (S(25.5), S(28)), (S(25.5), S(14)), (S(24), S(10)), (S(22.5), S(14))], fill=(226, 228, 222, 255))
    d.line([S(24), S(12), S(24), S(27)], fill=(160, 166, 170, 255), width=S(1))
    d.rectangle([S(17), S(28), S(31), S(30.5)], fill=(230, 190, 110, 255))
    d.rectangle([S(22.8), S(30.5), S(25.2), S(35)], fill=(110, 72, 40, 255))
    d.ellipse([S(22), S(34.5), S(26), S(38)], fill=(230, 190, 110, 255))
    finish_icon(img, "soldier")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    frame("frame_panel", 64, 5, 3, 11)
    frame("frame_console", 96, 8, 4, 23, alpha=242)
    frame("frame_bar", 64, 4, 2, 31, rivets=False, alpha=238)
    frame("frame_slot", 48, 3, 1, 41, rivets=False, alpha=225, top=(22, 28, 30), bottom=(12, 16, 18))
    frame("frame_toast", 64, 4, 2, 53, alpha=245, top=(58, 34, 24), bottom=(34, 20, 14))
    button("btn_normal", (58, 56, 48), (38, 37, 32), (150, 116, 66), 61)
    button("btn_hover", (82, 76, 60), (52, 49, 40), (226, 184, 112), 62)
    button("btn_pressed", (30, 29, 26), (46, 44, 38), (240, 200, 128), 63)
    button("btn_disabled", (40, 40, 38), (30, 30, 28), (80, 78, 70), 64)
    button("btn_tab_active", (92, 70, 38), (62, 46, 24), (240, 200, 128), 65)
    for fn in (icon_wood, icon_planks, icon_stone, icon_wheat, icon_bread, icon_wyrd, icon_pop, icon_sun, icon_moon, icon_soldier):
        fn()
    print("UI art written to", OUT)


if __name__ == "__main__":
    main()
