"""Paint prototype assets for the 2.5D test. Supersampled x3, soft edges.
Run: python3 art_test/painted25d/paint_assets.py  (writes assets/*.png)"""
import math, random
from PIL import Image, ImageDraw, ImageFilter
random.seed(25)
OUT = "art_test/painted25d/assets/"
SS = 3

def canvas(w, h):
    return Image.new("RGBA", (w*SS, h*SS), (0, 0, 0, 0))

def finish(img, w, h, name):
    img = img.resize((w, h), Image.LANCZOS)
    img = img.filter(ImageFilter.GaussianBlur(0.5))
    img.save(OUT + name)
    print("painted", name, img.size)

def wob(poly, amt, seed):
    rnd = random.Random(seed); out = []
    for i in range(len(poly)):
        x, y = poly[i]; nx, ny = poly[(i+1) % len(poly)]
        out.append((x + rnd.uniform(-amt, amt), y + rnd.uniform(-amt, amt)))
        mx, my = (x+nx)/2, (y+ny)/2
        out.append((mx + rnd.uniform(-amt, amt), my + rnd.uniform(-amt, amt)))
    return [(x*SS, y*SS) for x, y in out]

def shadow(d, cx, cy, rx, ry):
    for i in range(6):
        d.ellipse([(cx-rx-i*4)*SS, (cy-ry-i*2)*SS, (cx+rx+i*4)*SS, (cy+ry+i*2)*SS], fill=(30, 40, 20, 16))

def strokes(d, box, n, cols, lw, horiz=True, seed=1):
    rnd = random.Random(seed); x0, y0, x1, y1 = box
    for i in range(n):
        x, y = rnd.uniform(x0, x1), rnd.uniform(y0, y1); L = rnd.uniform(18, 60)
        c = rnd.choice(cols) + (rnd.randint(50, 110),)
        if horiz: d.line([(x*SS, y*SS), ((x+L)*SS, (y+rnd.uniform(-3, 3))*SS)], fill=c, width=int(lw*SS))
        else: d.line([(x*SS, y*SS), ((x+rnd.uniform(-3, 3))*SS, (y+L)*SS)], fill=c, width=int(lw*SS))

# ---------------- HOUSE (600x560, ground contact y~520) ----------------
img = canvas(600, 560); d = ImageDraw.Draw(img, 'RGBA')
shadow(d, 300, 522, 190, 26)
# walls: leaning plaster body + stone skirt
d.polygon(wob([(150,300),(455,290),(470,505),(135,510)], 5, 1), fill=(234, 216, 176, 255))
d.polygon(wob([(135,455),(470,450),(472,512),(133,514)], 4, 2), fill=(168, 160, 146, 255))
for i in range(9):  # skirt stones
    x = 150 + i*36
    d.rounded_rectangle([(x*SS, 462*SS), ((x+30)*SS, 505*SS)], 6*SS, fill=(150, 142, 128, 255), outline=(110, 102, 90, 160), width=2*SS)
strokes(d, (160, 310, 450, 440), 90, [(255, 248, 224), (206, 182, 142)], 3)
# timber frame
for x in [158, 300, 442]:
    d.line([(x*SS, 296*SS), ((x-6)*SS, 506*SS)], fill=(88, 60, 34, 255), width=13*SS)
d.line([(150*SS, 302*SS), (462*SS, 294*SS)], fill=(88, 60, 34, 255), width=12*SS)
d.line([(158*SS, 410*SS), (458*SS, 404*SS)], fill=(88, 60, 34, 255), width=9*SS)
d.line([(168*SS, 310*SS), (290*SS, 402*SS)], fill=(88, 60, 34, 255), width=8*SS)
# roof: sagging steep slopes (solid, strokes clipped to roof mask)
d.polygon(wob([(105,305),(300,118),(505,300),(505,318),(105,322)], 5, 3), fill=(172, 84, 48, 255))
d.polygon(wob([(300,118),(505,300),(505,318),(300,238)], 4, 4), fill=(146, 68, 40, 255))
mask = Image.new("L", img.size, 0); md = ImageDraw.Draw(mask)
md.polygon(wob([(105,305),(300,118),(505,300),(505,318),(105,322)], 5, 3), fill=255)
sl = Image.new("RGBA", img.size, (0,0,0,0)); sd = ImageDraw.Draw(sl)
strokes(sd, (110, 125, 490, 310), 170, [(232, 148, 96), (128, 62, 36), (240, 178, 120)], 3)
for r in range(7):
    y = 292 - r*24; inset = r*20
    sd.line([((118+inset)*SS, y*SS), (300*SS, (y-40)*SS), ((492-inset)*SS, y*SS)], fill=(110, 52, 30, 130), width=5*SS)
img.paste(Image.alpha_composite(img, sl), (0, 0), mask); d = ImageDraw.Draw(img, 'RGBA')
d.line([(112*SS, 308*SS), (300*SS, 126*SS), (498*SS, 302*SS)], fill=(236, 168, 112, 200), width=7*SS)
d.rectangle([105*SS, 302*SS, 505*SS, 316*SS], fill=(70, 40, 24, 90))
# chimney + smoke
d.polygon(wob([(392,92),(432,88),(436,168),(396,172)], 3, 5), fill=(158, 150, 136, 255))
d.rectangle([388*SS, 82*SS, 440*SS, 96*SS], fill=(120, 112, 98, 255))
for i, (sx, sy, sr) in enumerate([(420, 62, 17), (438, 40, 23), (462, 14, 29)]):
    d.ellipse([(sx-sr)*SS, (sy-sr)*SS, (sx+sr)*SS, (sy+sr)*SS], fill=(240, 240, 238, 58))
# door + windows
d.rounded_rectangle([272*SS, 408*SS, 330*SS, 508*SS], 14*SS, fill=(104, 70, 40, 255))
d.ellipse([272*SS, 388*SS, 330*SS, 432*SS], fill=(104, 70, 40, 255))
for wx in [185, 372]:
    d.rounded_rectangle([(wx*SS, 348*SS), ((wx+52)*SS, 402*SS)], 5*SS, fill=(255, 214, 130, 255), outline=(88, 60, 34, 255), width=5*SS)
    d.rectangle([(wx+8)*SS, 398*SS, (wx+44)*SS, 410*SS], fill=(122, 84, 44, 255))
    for fx in range(3):
        d.ellipse([((wx+8+fx*14)*SS, 390*SS), ((wx+18+fx*14)*SS, 402*SS)], fill=(224, 84, 62, 255))
finish(img, 600, 560, "house.png")

# ---------------- CASTLE SECTION (700x820, contact y~780) ----------------
img = canvas(700, 820); d = ImageDraw.Draw(img, 'RGBA')
shadow(d, 350, 782, 265, 34)
# main block (two-tone: light left, shadow right)
d.polygon(wob([(190,330),(505,322),(520,775),(175,780)], 6, 11), fill=(178, 170, 156, 255))
d.polygon(wob([(350,326),(505,322),(520,775),(355,778)], 5, 12), fill=(148, 140, 126, 255))
strokes(d, (200, 340, 500, 760), 200, [(210, 202, 186), (128, 120, 106)], 3)
for ry in range(6):
    for cx in range(5):
        if (cx+ry) % 3: d.rounded_rectangle([((205+cx*60)*SS, (360+ry*62)*SS), ((252+cx*60)*SS, (398+ry*62)*SS)], 5*SS, outline=(122, 114, 100, 90), width=2*SS)
# battlements
for i in range(7): d.rectangle([((196+i*46)*SS, 296*SS), ((228+i*46)*SS, 330*SS)], fill=(168, 160, 146, 255))
# towers: tall left, shorter right, conical roofs
for (tx, tw_, th, rh) in [(118, 120, 500, 190), (468, 108, 392, 160)]:
    top = 780 - th
    d.polygon(wob([(tx, top+rh*0.4),(tx+tw_, top+rh*0.4),(tx+tw_-8, 778),(tx+8, 778)], 5, 13+tx), fill=(186, 178, 164, 255))
    d.polygon(wob([(tx+tw_*0.55, top+rh*0.4),(tx+tw_, top+rh*0.4),(tx+tw_-8, 778),(tx+tw_*0.55, 778)], 4, 14+tx), fill=(152, 144, 130, 255))
    d.polygon(wob([(tx-16, top+rh*0.45),(tx+tw_*0.5, top),(tx+tw_+16, top+rh*0.45)], 6, 15+tx), fill=(168, 78, 44, 255))
    for r in range(4): d.line([((tx-8+r*4)*SS, (top+rh*0.42-r*22)*SS), ((tx+tw_+8-r*4)*SS, (top+rh*0.42-r*22)*SS)], fill=(110, 50, 30, 120), width=4*SS)
    d.rounded_rectangle([((tx+tw_*0.32)*SS, (top+rh*0.62)*SS), ((tx+tw_*0.62)*SS, (top+rh*0.88)*SS)], 8*SS, fill=(52, 42, 34, 255))
    d.rectangle([((tx+tw_*0.5-3)*SS, (top-32)*SS), ((tx+tw_*0.5+3)*SS, top*SS)], fill=(92, 64, 36, 255))
    d.polygon([((tx+tw_*0.5+3)*SS, (top-32)*SS), ((tx+tw_*0.5+38)*SS, (top-22)*SS), ((tx+tw_*0.5+3)*SS, (top-12)*SS)], fill=(206, 52, 40, 255))
# gate + windows
d.rounded_rectangle([302*SS, 640*SS, 398*SS, 778*SS], 22*SS, fill=(74, 54, 36, 255))
d.ellipse([302*SS, 606*SS, 398*SS, 672*SS], fill=(74, 54, 36, 255))
for wx, wy in [(255, 470), (415, 455), (335, 520)]:
    d.rounded_rectangle([(wx*SS, wy*SS), ((wx+34)*SS, (wy+52)*SS)], 9*SS, fill=(255, 216, 138, 255), outline=(96, 84, 66, 255), width=4*SS)
finish(img, 700, 820, "castle.png")

# ---------------- PINE (360x680, contact y~650) ----------------
img = canvas(360, 680); d = ImageDraw.Draw(img, 'RGBA')
shadow(d, 180, 652, 105, 16)
d.polygon(wob([(170,300),(190,300),(197,650),(162,650)], 4, 21), fill=(104, 72, 44, 255))
pmask = Image.new("L", img.size, 0); pmd = ImageDraw.Draw(pmask)
tiers = [(58, 74), (128, 104), (202, 128), (282, 148), (368, 162), (458, 168)]
for ti, (ty, halfw) in enumerate(tiers):
    pts = [(180-halfw, ty+44)]
    for s2 in range(7):
        pts.append((180-halfw + (2*halfw)*(s2+0.5)/7, ty+62 + (s2 % 2)*16))
        pts.append((180-halfw + (2*halfw)*(s2+1)/7, ty+40))
    pts += [(180+10, ty+6), (180, ty-16), (180-10, ty+6)]
    base = [(34, 88, 30), (40, 98, 34), (46, 108, 38), (52, 116, 42), (57, 124, 46), (62, 130, 50)][ti]
    d.polygon(wob(pts, 4, 30+ti), fill=base + (255,))
    pmd.polygon(wob(pts, 4, 30+ti), fill=255)
    d.line([(180-halfw)*SS, (ty+48)*SS, (180+halfw)*SS, (ty+48)*SS], fill=(24, 62, 22, 120), width=4*SS)
sl2 = Image.new("RGBA", img.size, (0,0,0,0)); sd2 = ImageDraw.Draw(sl2)
strokes(sd2, (15, 40, 345, 560), 260, [(150, 205, 100), (96, 158, 64), (190, 225, 140)], 3, seed=77)
img.paste(Image.alpha_composite(img, sl2), (0, 0), pmask); d = ImageDraw.Draw(img, 'RGBA')
finish(img, 360, 680, "pine.png")

# ---------------- BOULDER (360x260) ----------------
img = canvas(360, 260); d = ImageDraw.Draw(img, 'RGBA')
shadow(d, 180, 232, 140, 18)
d.polygon(wob([(60,210),(80,90),(170,38),(285,70),(315,205),(200,228),(95,226)], 7, 41), fill=(146, 134, 116, 255))
d.polygon(wob([(170,38),(285,70),(315,205),(205,226),(185,120)], 6, 42), fill=(116, 104, 90, 255))
strokes(d, (75, 60, 300, 210), 70, [(196, 184, 162), (96, 86, 72)], 3)
finish(img, 360, 260, "boulder.png")

# ---------------- TERRAIN (2048x1200, top-down iso ground painting) ----------------
img = Image.new("RGB", (2048, 1200), (96, 158, 62)); d = ImageDraw.Draw(img, 'RGBA')
for i in range(900):  # large meadow strokes/patches
    x, y = random.uniform(0, 2048), random.uniform(0, 1200); r = random.uniform(50, 190)
    c = random.choice([(70, 132, 44), (124, 184, 76), (146, 196, 88), (86, 148, 52), (168, 190, 96)])
    d.ellipse([x-r, y-r*0.55, x+r, y+r*0.55], fill=c + (52,))
img = img.filter(ImageFilter.GaussianBlur(3)); d = ImageDraw.Draw(img, 'RGBA')
# rock section: right slope painted INTO ground (strata/scree, no vertical wall plane)
rockpoly = [(1420, 0), (2048, 0), (2048, 760), (1780, 900), (1520, 620), (1400, 300)]
d.polygon(rockpoly, fill=(148, 118, 88, 255))
for i in range(46):
    y = i*22 + random.uniform(-6, 6)
    d.line([(1430, y), (2048, y + random.uniform(-26, 26))], fill=random.choice([(104, 82, 60), (188, 158, 122), (128, 104, 76)]) + (110,), width=random.randint(5, 12))
for i in range(260):
    x, y = random.uniform(1440, 2030), random.uniform(10, 830); r = random.uniform(4, 20)
    d.ellipse([x-r, y-r*0.6, x+r, y+r*0.6], fill=random.choice([(110, 92, 70), (196, 172, 138), (88, 74, 58)]) + (130,))
for i in range(30):  # green patches in rock
    x, y = random.uniform(1480, 1980), random.uniform(60, 760); r = random.uniform(18, 55)
    d.ellipse([x-r, y-r*0.5, x+r, y+r*0.5], fill=(92, 148, 58, 90))
# winding path (soft worn edges: wide low alpha, then core)
path = [(240, 1180), (520, 900), (430, 660), (760, 470), (1120, 420), (1330, 250), (1560, 190)]
for w, a in [(74, 46), (52, 80), (34, 170)]:
    d.line([(x, y) for x, y in path], fill=(198, 164, 108, a), width=w, joint="curve")
for i in range(240):
    x, y = random.uniform(0, 2048), random.uniform(0, 1200)
    if random.random() < 0.5: d.line([x, y, x+random.uniform(14, 42), y+random.uniform(-6, 6)], fill=(220, 236, 180, 46), width=5)
# worn plots under buildings + flower patches
for (x, y, r) in [(560, 620, 150), (1180, 640, 165), (820, 330, 210), (420, 300, 110)]:
    d.ellipse([x-r, y-r*0.55, x+r, y+r*0.55], fill=(176, 148, 100, 72))
for (x, y) in [(300, 760), (1020, 860), (660, 180)]:
    for i in range(46):
        fx, fy = x + random.uniform(-95, 95), y + random.uniform(-45, 45)
        d.ellipse([fx-7, fy-5, fx+7, fy+5], fill=random.choice([(238, 96, 74), (255, 214, 84), (255, 168, 190)]) + (190,))
img = img.filter(ImageFilter.GaussianBlur(1.2))
img.save(OUT + "terrain.png"); print("painted terrain.png", img.size)
