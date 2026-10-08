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
# T-SNS-UI Look lift: navy-black panels with a thin gold double hairline
# (measured from the approved mockup: fill ~#0d151b, hairline ~#ba9066).
NAVY_TOP = (19, 29, 36)
NAVY_BOTTOM = (10, 16, 21)
HAIR = (186, 144, 102)
HAIR_HI = (227, 192, 126)
HAIR_DIM = (111, 88, 54)
EDGE = (4, 7, 9)
CREAM = (236, 222, 184)


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


def corner_ornament(d, w, h, inset, arm, colour):
    """Small gold L-brackets with a diamond stud in each corner."""
    lw = SS
    for cx, cy, sx, sy in ((inset, inset, 1, 1), (w - 1 - inset, inset, -1, 1), (inset, h - 1 - inset, 1, -1), (w - 1 - inset, h - 1 - inset, -1, -1)):
        d.line([cx, cy, cx + sx * arm, cy], fill=colour + (255,), width=lw * 2)
        d.line([cx, cy, cx, cy + sy * arm], fill=colour + (255,), width=lw * 2)
        r = 2 * SS
        mx, my = cx + sx * 3 * SS, cy + sy * 3 * SS
        d.polygon([(mx, my - r), (mx + r, my), (mx, my + r), (mx - r, my)], fill=HAIR_HI + (255,))


def navy_frame(name, size, outer_inset, inner_inset, seed, ornaments=True, alpha=236, top=NAVY_TOP, bottom=NAVY_BOTTOM, hair=HAIR, hair_dim=HAIR_DIM, radius=0):
    """Look-lift 9-slice: navy gradient, 1 px dark edge, gold hairline + dim inner hairline."""
    w = h = size * SS
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    fill = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    noise_fill(fill, (0, 0, w, h), top, bottom, seed, 2)
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w - 1, h - 1], radius=radius * SS, fill=255)
    img.paste(fill, (0, 0), mask)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=radius * SS, outline=EDGE + (255,), width=SS)
    o = outer_inset * SS
    d.rounded_rectangle([o, o, w - 1 - o, h - 1 - o], radius=max(0, radius - outer_inset) * SS, outline=hair + (255,), width=2 * SS)
    if inner_inset > 0:
        i = inner_inset * SS
        d.rounded_rectangle([i, i, w - 1 - i, h - 1 - i], radius=max(0, radius - inner_inset) * SS, outline=hair_dim + (255,), width=SS)
    if ornaments:
        corner_ornament(d, w, h, o, 9 * SS, HAIR_HI)
    img = img.resize((size, size), Image.LANCZOS)
    px = img.load()
    inner = (inner_inset if inner_inset > 0 else outer_inset) + 1
    for y in range(inner, size - inner):
        for x in range(inner, size - inner):
            r_, g_, b_, a_ = px[x, y]
            px[x, y] = (r_, g_, b_, min(a_, alpha))
    img.save(OUT / f"{name}.png")


def navy_button(name, fill_top, fill_bottom, edge, seed, glow=False):
    size = 32
    w = h = size * SS
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    rad = 4 * SS
    ImageDraw.Draw(img).rounded_rectangle([0, 0, w - 1, h - 1], radius=rad, fill=EDGE + (255,))
    inner = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    noise_fill(inner, (0, 0, w, h), fill_top, fill_bottom, seed, 2)
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([SS, SS, w - 1 - SS, h - 1 - SS], radius=rad - SS, fill=255)
    img.paste(inner, (0, 0), mask)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([SS, SS, w - 1 - SS, h - 1 - SS], radius=rad - SS, outline=edge + (255,), width=SS)
    d.line([3 * SS, 2 * SS, w - 3 * SS, 2 * SS], fill=tuple(min(255, c + 30) for c in fill_top) + (255,), width=SS)
    if glow:
        d.rounded_rectangle([2 * SS, 2 * SS, w - 1 - 2 * SS, h - 1 - 2 * SS], radius=rad - 2 * SS, outline=edge + (110,), width=SS)
    img.resize((size, size), Image.LANCZOS).save(OUT / f"{name}.png")


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


def glyph_canvas():
    return icon_canvas()


def icon_pause():
    img, s = glyph_canvas(); d = ImageDraw.Draw(img)
    d.rounded_rectangle([S(13), S(10), S(21), S(38)], radius=S(2), fill=CREAM + (255,))
    d.rounded_rectangle([S(27), S(10), S(35), S(38)], radius=S(2), fill=CREAM + (255,))
    finish_icon(img, "pause")


def icon_play():
    img, s = glyph_canvas(); d = ImageDraw.Draw(img)
    d.polygon([(S(15), S(9)), (S(38), S(24)), (S(15), S(39))], fill=CREAM + (255,))
    finish_icon(img, "play")


def icon_fast():
    img, s = glyph_canvas(); d = ImageDraw.Draw(img)
    d.polygon([(S(6), S(11)), (S(24), S(24)), (S(6), S(37))], fill=CREAM + (255,))
    d.polygon([(S(24), S(11)), (S(42), S(24)), (S(24), S(37))], fill=CREAM + (255,))
    finish_icon(img, "fast")


def icon_menu():
    img, s = glyph_canvas(); d = ImageDraw.Draw(img)
    for y in (12, 22, 32):
        d.rounded_rectangle([S(9), S(y), S(39), S(y + 5)], radius=S(2), fill=CREAM + (255,))
    finish_icon(img, "menu")


def icon_hammer():
    img, s = glyph_canvas(); d = ImageDraw.Draw(img)
    d.polygon([(S(20), S(22)), (S(25), S(18)), (S(42), S(38)), (S(37), S(42))], fill=(150, 104, 58, 255), outline=(70, 46, 22, 255))
    d.polygon([(S(8), S(16)), (S(20), S(5)), (S(31), S(16)), (S(26), S(21)), (S(19), S(15)), (S(13), S(21))], fill=(196, 198, 196, 255), outline=(70, 72, 74, 255))
    d.line([S(12), S(15), S(20), S(8)], fill=(240, 240, 236, 255), width=S(1))
    finish_icon(img, "hammer")


def icon_hourglass():
    img, s = glyph_canvas(); d = ImageDraw.Draw(img)
    d.rectangle([S(11), S(6), S(37), S(10)], fill=(214, 90, 70, 255))
    d.rectangle([S(11), S(38), S(37), S(42)], fill=(214, 90, 70, 255))
    d.polygon([(S(14), S(10)), (S(34), S(10)), (S(26), S(24)), (S(34), S(38)), (S(14), S(38)), (S(22), S(24))], outline=(214, 90, 70, 255), width=S(2))
    d.polygon([(S(17), S(13)), (S(31), S(13)), (S(24), S(22))], fill=(236, 150, 110, 255))
    d.polygon([(S(24), S(29)), (S(31), S(36)), (S(17), S(36))], fill=(236, 150, 110, 255))
    finish_icon(img, "hourglass")


def icon_swords():
    img, s = glyph_canvas(); d = ImageDraw.Draw(img)
    red, dark = (226, 74, 58, 255), (110, 22, 18, 255)
    for flip in (1, -1):
        def P(x, y):
            return (S(24 + (x - 24) * flip), S(y))
        d.polygon([P(8, 6), P(12, 6), P(34, 32), P(31, 35)], fill=red, outline=dark)
        d.line([P(26, 36), P(36, 26)], fill=red, width=S(3))
        d.line([P(33, 33), P(41, 41)], fill=red, width=S(4))
    finish_icon(img, "swords")


def icon_quest():
    img, s = glyph_canvas(); d = ImageDraw.Draw(img)
    d.ellipse([S(6), S(6), S(42), S(42)], fill=(58, 44, 24, 255), outline=HAIR_HI + (255,), width=S(2))
    d.polygon([(S(24), S(12)), (S(33), S(24)), (S(24), S(36)), (S(15), S(24))], fill=HAIR_HI + (255,))
    d.polygon([(S(24), S(17)), (S(29), S(24)), (S(24), S(31)), (S(19), S(24))], fill=(120, 88, 42, 255))
    finish_icon(img, "quest")


def icon_house():
    img, s = glyph_canvas(); d = ImageDraw.Draw(img)
    d.polygon([(S(6), S(24)), (S(24), S(8)), (S(42), S(24))], fill=(170, 84, 60, 255), outline=(80, 34, 22, 255))
    d.rectangle([S(11), S(24), S(37), S(42)], fill=(214, 190, 150, 255), outline=(90, 70, 44, 255))
    d.rectangle([S(21), S(30), S(28), S(42)], fill=(110, 72, 40, 255))
    finish_icon(img, "house")


def icon_worker():
    img, s = glyph_canvas(); d = ImageDraw.Draw(img)
    d.ellipse([S(17), S(6), S(31), S(20)], fill=(222, 206, 176, 255), outline=(60, 50, 36, 255))
    d.rounded_rectangle([S(12), S(22), S(36), S(42)], radius=S(7), fill=(150, 124, 86, 255), outline=(60, 50, 36, 255))
    d.line([S(33), S(24), S(42), S(12)], fill=(150, 104, 58, 255), width=S(3))
    d.rectangle([S(38), S(8), S(46), S(13)], fill=(196, 198, 196, 255))
    finish_icon(img, "worker")


def icon_hunger():
    img, s = glyph_canvas(); d = ImageDraw.Draw(img)
    c = (226, 196, 120, 255)
    for x in (12, 16, 20):
        d.line([S(x), S(6), S(x), S(18)], fill=c, width=S(2))
    d.rounded_rectangle([S(11), S(16), S(21), S(22)], radius=S(3), fill=c)
    d.line([S(16), S(20), S(16), S(42)], fill=c, width=S(3))
    d.ellipse([S(28), S(6), S(38), S(26)], fill=c)
    d.line([S(33), S(24), S(33), S(42)], fill=c, width=S(3))
    finish_icon(img, "hunger")


def icon_shield():
    img, s = glyph_canvas(); d = ImageDraw.Draw(img)
    d.polygon([(S(24), S(5)), (S(40), S(11)), (S(38), S(28)), (S(24), S(43)), (S(10), S(28)), (S(8), S(11))], fill=(80, 150, 90, 255), outline=(30, 60, 36, 255))
    d.polygon([(S(24), S(9)), (S(36), S(13)), (S(35), S(27)), (S(24), S(38))], fill=(118, 190, 120, 255))
    finish_icon(img, "shield")


def icon_road():
    img, s = glyph_canvas(); d = ImageDraw.Draw(img)
    d.polygon([(S(18), S(6)), (S(30), S(6)), (S(42), S(42)), (S(6), S(42))], fill=(140, 110, 72, 255), outline=(70, 50, 30, 255))
    for y in (10, 20, 31):
        d.line([S(24), S(y), S(24), S(y + 6)], fill=(230, 210, 160, 255), width=S(2))
    finish_icon(img, "road")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    # T-SNS-UI Look lift (30/9 2026): navy + gold-hairline frames replace the
    # stone set (the stone generators above are kept for reference/rollback).
    navy_frame("frame_panel", 64, 2, 5, 11, alpha=246)
    navy_frame("frame_console", 96, 3, 7, 23, alpha=252)
    navy_frame("frame_bar", 64, 1, 4, 31, ornaments=False, alpha=248)
    navy_frame("frame_slot", 48, 1, 0, 41, ornaments=False, alpha=236, hair=HAIR_DIM)
    navy_frame("frame_toast", 64, 1, 4, 53, ornaments=False, alpha=246)
    navy_frame("frame_capsule", 32, 1, 0, 57, ornaments=False, alpha=232, top=(14, 22, 28), bottom=(8, 13, 17), hair=HAIR_DIM, radius=5)
    navy_frame("frame_alert", 64, 2, 5, 59, alpha=250, top=(92, 22, 18), bottom=(40, 10, 9), hair=(214, 110, 86), hair_dim=(120, 40, 30))
    navy_button("btn_normal", (30, 43, 51), (17, 26, 32), HAIR_DIM, 61)
    navy_button("btn_hover", (44, 60, 70), (25, 36, 44), HAIR_HI, 62, glow=True)
    navy_button("btn_pressed", (12, 19, 24), (22, 32, 39), HAIR, 63)
    navy_button("btn_disabled", (26, 30, 32), (18, 21, 23), (70, 72, 70), 64)
    navy_button("btn_tab_active", (84, 64, 34), (48, 36, 18), HAIR_HI, 65, glow=True)
    for fn in (icon_wood, icon_planks, icon_stone, icon_wheat, icon_bread, icon_wyrd, icon_pop, icon_sun, icon_moon, icon_soldier,
               icon_pause, icon_play, icon_fast, icon_menu, icon_hammer, icon_hourglass, icon_swords, icon_quest, icon_house,
               icon_worker, icon_hunger, icon_shield, icon_road):
        fn()
    print("UI art written to", OUT)


if __name__ == "__main__":
    main()
