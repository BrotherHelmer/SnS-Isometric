"""Paint prototype assets for the 2.5D test. Supersampled x3, soft edges.
Run: python3 art_test/painted25d/paint_assets.py  (writes assets/*.png)"""
import math, random
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
random.seed(25)
OUT = "art_test/painted25d/assets/"
SS = 3

def canvas(w, h):
    return Image.new("RGBA", (w*SS, h*SS), (0, 0, 0, 0))

def finish(img, w, h, name, bright=1.0, sat=1.0):
    img = img.resize((w, h), Image.LANCZOS)
    if bright != 1.0: img = ImageEnhance.Brightness(img).enhance(bright)
    if sat != 1.0: img = ImageEnhance.Color(img).enhance(sat)
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

# ---------------- HERO HOUSE P2 (600x560, contact y~520): dense brush + value modelling ----------------
img = canvas(600, 560); d = ImageDraw.Draw(img, 'RGBA')
shadow(d, 300, 522, 195, 26)
wallp = wob([(150,300),(455,290),(470,505),(135,510)], 5, 1)
roofp = wob([(100,308),(298,106),(510,298),(510,318),(100,324)], 5, 3)
wmask = Image.new("L", img.size, 0); ImageDraw.Draw(wmask).polygon(wallp, fill=255)
rmask = Image.new("L", img.size, 0); ImageDraw.Draw(rmask).polygon(roofp, fill=255)
# walls: plaster base + lit left / shadow right value modelling
d.polygon(wallp, fill=(206, 186, 148, 255))
lay = Image.new("RGBA", img.size, (0,0,0,0)); ld = ImageDraw.Draw(lay)
ld.polygon(wob([(150,300),(300,296),(305,508),(135,510)], 4, 31), fill=(255, 240, 205, 66))   # lit side
ld.polygon(wob([(368,294),(455,290),(470,505),(372,506)], 4, 32), fill=(104, 94, 82, 92))     # shadow side
ld.rectangle([130*SS, 292*SS, 475*SS, 322*SS], fill=(80, 58, 40, 88))                        # under-eave AO
ld.rectangle([130*SS, 470*SS, 475*SS, 512*SS], fill=(86, 66, 46, 70))                        # ground AO
img.paste(Image.alpha_composite(img, lay), (0, 0), wmask); d = ImageDraw.Draw(img, 'RGBA')
lay = Image.new("RGBA", img.size, (0,0,0,0)); ld = ImageDraw.Draw(lay)
strokes(ld, (145, 305, 465, 500), 300, [(238, 222, 182), (188, 164, 122), (168, 150, 118), (226, 204, 158)], 3, seed=41)
for cx, cy in [(210, 360), (390, 330), (250, 450)]:  # plaster patches + cracks
    ld.ellipse([(cx-46)*SS, (cy-20)*SS, (cx+46)*SS, (cy+20)*SS], fill=(196, 172, 128, 60))
    ld.line([(cx*SS, cy*SS), ((cx+16)*SS, (cy+34)*SS), ((cx+8)*SS, (cy+58)*SS)], fill=(110, 92, 70, 110), width=2*SS)
img.paste(Image.alpha_composite(img, lay), (0, 0), wmask); d = ImageDraw.Draw(img, 'RGBA')
# stone foundation: individual shaded stones, 2 offset rows
rndf = random.Random(7)
for row, fy in enumerate([458, 484]):
    for i in range(9):
        x = 142 + i*37 + (18 if row else 0); wdt = rndf.randint(28, 36)
        c = rndf.choice([(148, 138, 122), (132, 122, 106), (160, 148, 130), (120, 112, 98)])
        d.rounded_rectangle([(x*SS, fy*SS), ((x+wdt)*SS, (fy+24)*SS)], 7*SS, fill=c+(255,), outline=(88, 80, 68, 170), width=2*SS)
        d.line([((x+4)*SS, (fy+5)*SS), ((x+wdt-6)*SS, (fy+5)*SS)], fill=(214, 204, 184, 130), width=2*SS)
# timber frame with grain
for x0b, y0b, x1b, y1b, wd in [(158,296,152,506,13),(300,294,300,506,13),(442,292,450,504,13),(150,302,462,294,12),(158,410,458,404,9),(168,310,290,402,8)]:
    d.line([(x0b*SS, y0b*SS), (x1b*SS, y1b*SS)], fill=(84, 58, 32, 255), width=wd*SS)
    d.line([((x0b+2)*SS, y0b*SS), ((x1b+2)*SS, y1b*SS)], fill=(140, 104, 62, 130), width=2*SS)
# roof: muted terracotta base, shadow slope, dense shingles (rows + scallops + strokes), ridge
d.polygon(roofp, fill=(148, 78, 46, 255))
lay = Image.new("RGBA", img.size, (0,0,0,0)); ld = ImageDraw.Draw(lay)
ld.polygon(wob([(298,106),(510,298),(510,318),(298,240)], 4, 33), fill=(70, 36, 26, 96))  # shadow slope
ld.polygon(wob([(100,308),(298,106),(298,240),(100,324)], 4, 34), fill=(255, 186, 130, 46)) # lit slope
strokes(ld, (105, 112, 505, 315), 420, [(196, 118, 74), (122, 60, 36), (214, 146, 96), (104, 52, 32)], 3, seed=55)
rndr = random.Random(9)
for r in range(9):
    tt = r/8.0; y = 302 - tt*172; hw = 200 - tt*182; cx = 302 - tt*3
    ld.line([((cx-hw)*SS, y*SS), ((cx+hw)*SS, y*SS)], fill=(92, 46, 28, 150), width=4*SS)
    x = cx-hw
    while x < cx+hw-14:
        c = rndr.choice([(176, 102, 62), (156, 84, 50), (190, 116, 72), (138, 72, 44)])
        ld.arc([(x*SS, (y-7)*SS), ((x+24)*SS, (y+11)*SS)], 0, 180, fill=c+(210,), width=4*SS)
        x += 24
for i in range(9):  # ridge tiles
    x = 268 + i*8
    ld.rounded_rectangle([(x*SS, (104 - abs(i-4))*SS), ((x+9)*SS, (118 - abs(i-4))*SS)], 3*SS, fill=(186, 110, 68, 255), outline=(100, 52, 30, 160), width=1*SS)
img.paste(Image.alpha_composite(img, lay), (0, 0), rmask); d = ImageDraw.Draw(img, 'RGBA')
d.line([(104*SS, 310*SS), (298*SS, 112*SS), (506*SS, 300*SS)], fill=(228, 158, 104, 170), width=5*SS)
d.rectangle([100*SS, 302*SS, 510*SS, 318*SS], fill=(64, 38, 22, 110))
d.line([(148*SS, 302*SS), (136*SS, 508*SS)], fill=(70, 48, 28, 130), width=3*SS)  # painterly edge
d.line([(456*SS, 294*SS), (468*SS, 504*SS)], fill=(70, 48, 28, 130), width=3*SS)
# chimney: shaded stone + soft smoke
d.polygon(wob([(392,92),(432,88),(436,168),(396,172)], 3, 5), fill=(146, 136, 120, 255))
d.polygon(wob([(414,90),(432,88),(436,168),(416,170)], 3, 35), fill=(110, 102, 90, 255))
strokes(d, (394, 98, 430, 162), 30, [(196, 186, 168), (96, 88, 76)], 2, seed=61)
d.rectangle([388*SS, 82*SS, 440*SS, 96*SS], fill=(104, 96, 84, 255))
for sx, sy, sr, aa in [(420, 62, 15, 30), (436, 42, 19, 24), (458, 18, 24, 18)]:
    d.ellipse([(sx-sr)*SS, (sy-sr)*SS, (sx+sr)*SS, (sy+sr)*SS], fill=(238, 238, 234, aa))
# door: arched, planked, stone surround; windows: warm glow, shutters, flower boxes
d.rounded_rectangle([268*SS, 404*SS, 334*SS, 510*SS], 15*SS, outline=(150, 140, 124, 255), width=6*SS)
d.rounded_rectangle([272*SS, 408*SS, 330*SS, 508*SS], 14*SS, fill=(96, 64, 36, 255))
d.ellipse([272*SS, 388*SS, 330*SS, 432*SS], fill=(96, 64, 36, 255))
for px in [286, 300, 314]: d.line([(px*SS, 402*SS), (px*SS, 504*SS)], fill=(58, 38, 20, 160), width=2*SS)
d.ellipse([318*SS, 458*SS, 326*SS, 466*SS], fill=(216, 178, 92, 255))
for wx in [185, 372]:
    d.rectangle([(wx-14)*SS, 344*SS, (wx-3)*SS, 406*SS], fill=(96, 104, 66, 255))   # shutters
    d.rectangle([((wx+55)*SS), 344*SS, ((wx+66)*SS, 406*SS)], fill=(84, 92, 58, 255))
    d.rounded_rectangle([(wx*SS, 348*SS), ((wx+52)*SS, 402*SS)], 5*SS, fill=(240, 196, 112, 255), outline=(80, 54, 30, 255), width=5*SS)
    d.rectangle([((wx+24)*SS), 348*SS, ((wx+28)*SS, 402*SS)], fill=(80, 54, 30, 255))
    d.rectangle([(wx*SS), 372*SS, ((wx+52)*SS, 376*SS)], fill=(80, 54, 30, 255))
    d.rectangle([((wx+6)*SS), 398*SS, ((wx+46)*SS, 412*SS)], fill=(110, 76, 40, 255))
    rndw = random.Random(wx)
    for i in range(12):
        gx, gy2 = wx+8+rndw.uniform(0, 36), 394+rndw.uniform(0, 8)
        d.ellipse([(gx*SS, gy2*SS), ((gx+7)*SS, (gy2+6)*SS)], fill=(86, 116, 54, 255))
        if i % 3 == 0: d.ellipse([((gx+2)*SS, (gy2-4)*SS), ((gx+7)*SS, (gy2+1)*SS)], fill=(196, 74, 54, 255))
# base grass tufts + vine on lit wall
rndg = random.Random(3)
for i in range(46):
    gx = rndg.uniform(140, 465); gl = rndg.uniform(8, 20)
    d.line([(gx*SS, 512*SS), ((gx+rndg.uniform(-3, 3))*SS, (512-gl)*SS)], fill=rndg.choice([(86, 122, 54), (64, 104, 44), (110, 142, 66)])+(200,), width=2*SS)
for i in range(26):
    vx, vy = 168 + i*3.2, 470 - i*6.4
    d.ellipse([((vx+rndg.uniform(-7, 7))*SS, (vy+rndg.uniform(-5, 5))*SS), ((vx+9)*SS, (vy+7)*SS)], fill=(92, 124, 58, 190))
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
finish(img, 700, 820, "castle.png", bright=0.86, sat=0.82)

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
finish(img, 360, 680, "pine.png", bright=0.82, sat=0.80)

# ---------------- BOULDER (360x260) ----------------
img = canvas(360, 260); d = ImageDraw.Draw(img, 'RGBA')
shadow(d, 180, 232, 140, 18)
d.polygon(wob([(60,210),(80,90),(170,38),(285,70),(315,205),(200,228),(95,226)], 7, 41), fill=(146, 134, 116, 255))
d.polygon(wob([(170,38),(285,70),(315,205),(205,226),(185,120)], 6, 42), fill=(116, 104, 90, 255))
strokes(d, (75, 60, 300, 210), 70, [(196, 184, 162), (96, 86, 72)], 3)
finish(img, 360, 260, "boulder.png", bright=0.88, sat=0.85)

# ---------------- MOUNTAIN BACKDROP (1500x950, contact y~920): layered painted landform ----------------
img = canvas(1500, 950); d = ImageDraw.Draw(img, 'RGBA')
shadow(d, 750, 922, 640, 26)
sil = wob([(70,920),(210,640),(350,390),(505,190),(640,330),(800,110),(965,300),(1110,190),(1265,430),(1405,620),(1460,920)], 14, 71)
mmask = Image.new("L", img.size, 0); ImageDraw.Draw(mmask).polygon(sil, fill=255)
d.polygon(sil, fill=(134, 120, 104, 255))  # muted warm rock base
lay = Image.new("RGBA", img.size, (0,0,0,0)); ld = ImageDraw.Draw(lay)
# facet value modelling: lit planes left / shadow gullies right of each peak
for poly, c in [([(505,190),(640,330),(560,560),(430,420)], (188, 172, 148, 120)),
                ([(800,110),(965,300),(880,600),(730,420)], (196, 182, 158, 110)),
                ([(1110,190),(1265,430),(1150,640),(1020,430)], (186, 170, 146, 110)),
                ([(640,330),(800,110),(880,600),(700,700)], (88, 80, 76, 130)),
                ([(965,300),(1110,190),(1150,640),(950,680)], (92, 84, 80, 125)),
                ([(350,390),(505,190),(560,560),(380,640)], (176, 160, 136, 100)),
                ([(210,640),(350,390),(430,700),(280,880)], (104, 94, 84, 110)),
                ([(1265,430),(1405,620),(1460,920),(1200,760)], (96, 88, 80, 120))]:
    ld.polygon(wob(poly, 10, 72+poly[0][0]), fill=c)
strokes(ld, (80, 120, 1450, 900), 900, [(178, 164, 142), (104, 94, 84), (150, 134, 112), (84, 76, 70), (206, 192, 168)], 3, seed=73)
rndm = random.Random(74)
for i in range(34):  # strata bands
    y = rndm.uniform(240, 860); x0 = rndm.uniform(120, 700)
    ld.line([(x0*SS, y*SS), ((x0+rndm.uniform(180, 420))*SS, (y+rndm.uniform(28, 66))*SS)], fill=(96, 86, 76, 90), width=int(rndm.uniform(3, 7))*SS)
img.paste(Image.alpha_composite(img, lay), (0, 0), mmask); d = ImageDraw.Draw(img, 'RGBA')
# snow: soft irregular patches under peaks (blurred layer, clipped)
snow = Image.new("RGBA", img.size, (0,0,0,0)); snd = ImageDraw.Draw(snow)
for px, py, sw in [(505, 190, 120), (800, 110, 150), (1110, 190, 120), (640, 330, 70), (965, 300, 76)]:
    snd.polygon(wob([(px-sw, py+64),(px-sw*0.35, py+6),(px, py+38),(px+sw*0.4, py+2),(px+sw, py+58),(px+sw*0.3, py+96),(px-sw*0.3, py+92)], 9, px), fill=(236, 233, 224, 235))
snow = snow.filter(ImageFilter.GaussianBlur(3*SS))
img.paste(Image.alpha_composite(img, snow), (0, 0), mmask); d = ImageDraw.Draw(img, 'RGBA')
# scree fans + foothill green + pine specks at base
lay = Image.new("RGBA", img.size, (0,0,0,0)); ld = ImageDraw.Draw(lay)
for bx in [300, 620, 940, 1240]:
    ld.polygon(wob([(bx-190, 922),(bx, 690),(bx+200, 922)], 16, bx), fill=(172, 152, 124, 64))
    for i in range(60):
        sx, sy = bx+rndm.uniform(-165, 165), rndm.uniform(760, 912)
        ld.ellipse([(sx*SS, sy*SS), ((sx+rndm.uniform(4, 12))*SS, (sy+4)*SS)], fill=(120, 106, 88, 120))
ld.polygon(wob([(60,950),(60,852),(420,806),(820,838),(1180,800),(1470,856),(1470,950)], 10, 79), fill=(92, 122, 66, 235))
strokes(ld, (70, 800, 1450, 940), 240, [(112, 142, 78), (72, 104, 50), (140, 160, 92)], 3, seed=80)
for i in range(90):
    tx, ty = rndm.uniform(90, 1420), rndm.uniform(806, 892); th2 = rndm.uniform(12, 30)
    ld.polygon([((tx-7)*SS, ty*SS), (tx*SS, (ty-th2)*SS), ((tx+7)*SS, ty*SS)], fill=(44, 72, 36, 220))
img.paste(Image.alpha_composite(img, lay), (0, 0), mmask); d = ImageDraw.Draw(img, 'RGBA')
finish(img, 1500, 950, "mountain.png", bright=0.94, sat=0.88)

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
img = ImageEnhance.Brightness(img).enhance(0.76)
img = ImageEnhance.Color(img).enhance(0.68)
img.save(OUT + "terrain.png"); print("painted terrain.png", img.size)
