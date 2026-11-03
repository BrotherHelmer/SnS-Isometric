"""Paint prototype assets for the 2.5D test. Supersampled x3, soft edges.
Run: python3 art_test/painted25d/paint_assets.py  (writes assets/*.png)"""
import math, random
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance, ImageChops
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

# ---------------- HOUSE VARIANT A: wide cottage (640x520, contact y~478) ----------------
img = canvas(640, 520); d = ImageDraw.Draw(img, 'RGBA')
shadow(d, 320, 480, 225, 24)
wallp = wob([(122,252),(518,242),(534,462),(108,466)], 5, 101)
roofp = wob([(66,266),(318,104),(578,252),(578,272),(66,282)], 5, 102)
wmask = Image.new("L", img.size, 0); ImageDraw.Draw(wmask).polygon(wallp, fill=255)
rmask = Image.new("L", img.size, 0); ImageDraw.Draw(rmask).polygon(roofp, fill=255)
d.polygon(wallp, fill=(202, 182, 144, 255))
lay = Image.new("RGBA", img.size, (0,0,0,0)); ld = ImageDraw.Draw(lay)
ld.polygon(wob([(122,252),(310,246),(312,464),(108,466)], 4, 103), fill=(255, 240, 205, 60))
ld.polygon(wob([(420,246),(518,242),(534,462),(424,464)], 4, 104), fill=(104, 94, 82, 88))
ld.rectangle([104*SS, 428*SS, 538*SS, 466*SS], fill=(86, 66, 46, 66))
strokes(ld, (112, 256, 530, 460), 260, [(236, 220, 180), (186, 162, 120), (168, 150, 118)], 3, seed=105)
img.paste(Image.alpha_composite(img, lay), (0, 0), wmask); d = ImageDraw.Draw(img, 'RGBA')
rndv = random.Random(107)
for row, fy in enumerate([414, 440]):
    for i in range(11):
        x = 116 + i*39 + (19 if row else 0)
        c = rndv.choice([(146, 136, 120), (130, 120, 104), (158, 146, 128)])
        d.rounded_rectangle([(x*SS, fy*SS), ((x+32)*SS, (fy+23)*SS)], 6*SS, fill=c+(255,), outline=(88, 80, 68, 160), width=2*SS)
for x0b, y0b, x1b, y1b, wd in [(132,250,126,464,12),(318,246,318,464,12),(506,244,516,460,12),(122,256,520,248,11)]:
    d.line([(x0b*SS, y0b*SS), (x1b*SS, y1b*SS)], fill=(82, 56, 31, 255), width=wd*SS)
d.polygon(roofp, fill=(142, 74, 44, 255))
lay = Image.new("RGBA", img.size, (0,0,0,0)); ld = ImageDraw.Draw(lay)
ld.polygon(wob([(318,104),(578,252),(578,272),(318,226)], 4, 108), fill=(70, 36, 26, 92))
strokes(ld, (70, 110, 572, 268), 360, [(192, 114, 72), (118, 58, 35), (210, 142, 94)], 3, seed=109)
for r in range(7):
    tt = r/6.0; y = 258 - tt*138; hw = 238 - tt*214
    ld.line([((318-hw)*SS, y*SS), ((318+hw)*SS, y*SS)], fill=(90, 45, 27, 150), width=4*SS)
    x = 318-hw
    while x < 318+hw-14:
        ld.arc([(x*SS, (y-6)*SS), ((x+22)*SS, (y+10)*SS)], 0, 180, fill=(176, 102, 62, 200), width=4*SS); x += 22
img.paste(Image.alpha_composite(img, lay), (0, 0), rmask); d = ImageDraw.Draw(img, 'RGBA')
d.line([(70*SS, 268*SS), (318*SS, 110*SS), (572*SS, 254*SS)], fill=(224, 154, 100, 160), width=5*SS)
d.rectangle([66*SS, 254*SS, 578*SS, 270*SS], fill=(62, 37, 22, 110))
# chimney left + woodpile lean-to right
d.polygon(wob([(176,84),(214,80),(218,158),(180,162)], 3, 110), fill=(144, 134, 118, 255))
d.rectangle([172*SS, 74*SS, 220*SS, 88*SS], fill=(102, 94, 82, 255))
d.polygon(wob([(520,330),(586,356),(582,462),(528,458)], 4, 111), fill=(122, 88, 54, 255))
d.polygon(wob([(512,332),(592,352),(588,368),(516,352)], 4, 112), fill=(104, 58, 36, 255))
for i in range(8):
    lx, ly = 534 + (i % 4)*13, 420 - (i//4)*16
    d.ellipse([(lx*SS, ly*SS), ((lx+13)*SS, (ly+13)*SS)], fill=(150, 108, 66, 255), outline=(92, 62, 34, 255), width=2*SS)
d.rounded_rectangle([206*SS, 356*SS, 262*SS, 464*SS], 13*SS, fill=(94, 62, 35, 255))
d.ellipse([206*SS, 338*SS, 262*SS, 378*SS], fill=(94, 62, 35, 255))
for wx in [356, 448]:
    d.rounded_rectangle([(wx*SS, 306*SS), ((wx+50)*SS, 358*SS)], 5*SS, fill=(240, 196, 112, 255), outline=(78, 52, 29, 255), width=5*SS)
    d.line([((wx+25)*SS, 306*SS), ((wx+25)*SS, 358*SS)], fill=(78, 52, 29, 255), width=3*SS)
for i in range(38):
    gx = rndv.uniform(112, 530); gl = rndv.uniform(7, 18)
    d.line([(gx*SS, 468*SS), ((gx+rndv.uniform(-3, 3))*SS, (468-gl)*SS)], fill=rndv.choice([(86, 122, 54), (64, 104, 44)])+(200,), width=2*SS)
finish(img, 640, 520, "house2.png")

# ---------------- HOUSE VARIANT B: tall narrow house (520x620, contact y~578) ----------------
img = canvas(520, 620); d = ImageDraw.Draw(img, 'RGBA')
shadow(d, 260, 580, 165, 22)
wallp = wob([(150,332),(370,322),(382,560),(138,564)], 5, 121)
roofp = wob([(92,342),(258,66),(428,330),(428,350),(92,358)], 5, 122)
wmask = Image.new("L", img.size, 0); ImageDraw.Draw(wmask).polygon(wallp, fill=255)
rmask = Image.new("L", img.size, 0); ImageDraw.Draw(rmask).polygon(roofp, fill=255)
d.polygon(wallp, fill=(208, 188, 150, 255))
lay = Image.new("RGBA", img.size, (0,0,0,0)); ld = ImageDraw.Draw(lay)
ld.polygon(wob([(150,332),(258,328),(260,562),(138,564)], 4, 123), fill=(255, 240, 205, 60))
ld.polygon(wob([(316,326),(370,322),(382,560),(318,562)], 4, 124), fill=(104, 94, 82, 88))
strokes(ld, (142, 336, 378, 556), 240, [(238, 222, 182), (188, 164, 122), (170, 150, 118)], 3, seed=125)
img.paste(Image.alpha_composite(img, lay), (0, 0), wmask); d = ImageDraw.Draw(img, 'RGBA')
rndv = random.Random(127)
for row, fy in enumerate([512, 538]):
    for i in range(7):
        x = 146 + i*34 + (16 if row else 0)
        c = rndv.choice([(146, 136, 120), (130, 120, 104), (158, 146, 128)])
        d.rounded_rectangle([(x*SS, fy*SS), ((x+28)*SS, (fy+22)*SS)], 6*SS, fill=c+(255,), outline=(88, 80, 68, 160), width=2*SS)
for x0b, y0b, x1b, y1b, wd in [(158,330,152,560,12),(260,326,260,560,11),(362,324,370,558,12),(150,336,372,328,11),(156,446,368,440,8)]:
    d.line([(x0b*SS, y0b*SS), (x1b*SS, y1b*SS)], fill=(84, 58, 32, 255), width=wd*SS)
d.polygon(roofp, fill=(138, 70, 42, 255))
lay = Image.new("RGBA", img.size, (0,0,0,0)); ld = ImageDraw.Draw(lay)
ld.polygon(wob([(258,66),(428,330),(428,350),(258,220)], 4, 128), fill=(70, 36, 26, 96))
strokes(ld, (96, 72, 424, 344), 380, [(188, 108, 66), (112, 54, 32), (206, 138, 90)], 3, seed=129)
for r in range(10):
    tt = r/9.0; y = 336 - tt*248; hw = 164 - tt*148
    ld.line([((258-hw)*SS, y*SS), ((258+hw)*SS, y*SS)], fill=(88, 44, 26, 150), width=3*SS)
    x = 258-hw
    while x < 258+hw-12:
        ld.arc([(x*SS, (y-6)*SS), ((x+20)*SS, (y+9)*SS)], 0, 180, fill=(172, 98, 60, 200), width=3*SS); x += 20
img.paste(Image.alpha_composite(img, lay), (0, 0), rmask); d = ImageDraw.Draw(img, 'RGBA')
# dormer on roof slope + round attic window
d.polygon(wob([(216,238),(262,204),(306,240),(302,292),(220,292)], 4, 130), fill=(214, 196, 158, 255))
d.polygon(wob([(208,242),(262,196),(314,240),(306,252),(216,254)], 4, 131), fill=(120, 62, 38, 255))
d.rectangle([240*SS, 246*SS, 282*SS, 290*SS], fill=(240, 196, 112, 255), outline=(78, 52, 29, 255), width=4*SS)
d.ellipse([240*SS, 356*SS, 278*SS, 394*SS], fill=(240, 200, 118, 255), outline=(80, 54, 30, 255), width=4*SS)
d.line([(259*SS, 356*SS), (259*SS, 394*SS)], fill=(80, 54, 30, 255), width=3*SS)
d.polygon(wob([(330,150),(364,146),(368,224),(334,228)], 3, 132), fill=(144, 134, 118, 255))
d.rectangle([326*SS, 140*SS, 370*SS, 154*SS], fill=(102, 94, 82, 255))
d.rounded_rectangle([226*SS, 452*SS, 280*SS, 562*SS], 13*SS, fill=(94, 62, 35, 255))
d.ellipse([226*SS, 434*SS, 280*SS, 472*SS], fill=(94, 62, 35, 255))
for wx, wy in [(168, 452), (308, 452)]:
    d.rounded_rectangle([(wx*SS, wy*SS), ((wx+44)*SS, (wy+50)*SS)], 5*SS, fill=(240, 196, 112, 255), outline=(78, 52, 29, 255), width=4*SS)
for i in range(34):
    gx = rndv.uniform(142, 378); gl = rndv.uniform(7, 17)
    d.line([(gx*SS, 566*SS), ((gx+rndv.uniform(-3, 3))*SS, (566-gl)*SS)], fill=rndv.choice([(86, 122, 54), (64, 104, 44)])+(200,), width=2*SS)
finish(img, 520, 620, "house3.png")

# ---------------- HERO CASTLE P3 (700x820, contact y~780): dense stone/value system ----------------
img = canvas(700, 820); d = ImageDraw.Draw(img, 'RGBA')
shadow(d, 350, 782, 268, 34)
cmask = Image.new("L", img.size, 0); cmd = ImageDraw.Draw(cmask)
mainp = wob([(190,330),(505,322),(520,775),(175,780)], 6, 11)
cmd.polygon(mainp, fill=255)
d.polygon(mainp, fill=(168, 158, 142, 255))
towers = [(118, 120, 500, 190), (468, 108, 392, 160)]  # tx, w, h, roof h
for (tx, tw_, th, rh) in towers:
    top = 780 - th
    tp = wob([(tx, top+rh*0.4),(tx+tw_, top+rh*0.4),(tx+tw_-8, 778),(tx+8, 778)], 5, 13+tx)
    cmd.polygon(tp, fill=255); d.polygon(tp, fill=(176, 166, 150, 255))
# stone courses: individual shaded stones in offset rows (clipped to walls)
lay = Image.new("RGBA", img.size, (0,0,0,0)); ld = ImageDraw.Draw(lay)
rndc = random.Random(21)
for ry in range(8):
    y = 348 + ry*56
    for cx in range(8):
        x = 168 + cx*74 + (36 if ry % 2 else 0)
        if x > 512: continue
        c = rndc.choice([(216, 206, 186), (188, 176, 156), (148, 138, 120), (106, 98, 88), (170, 158, 140)])
        ld.rounded_rectangle([(x*SS, y*SS), ((x+rndc.randint(56,72))*SS, (y+46)*SS)], 7*SS, fill=c+(255,), outline=(70, 62, 52, 230), width=3*SS)
        ld.line([((x+6)*SS, (y+8)*SS), ((x+46)*SS, (y+8)*SS)], fill=(240, 232, 210, 150), width=3*SS)
        ld.line([((x+6)*SS, (y+40)*SS), ((x+46)*SS, (y+40)*SS)], fill=(60, 54, 46, 130), width=3*SS)
strokes(ld, (180, 335, 515, 770), 380, [(210, 200, 180), (128, 118, 104), (188, 176, 156)], 3, seed=23)
ld.polygon(wob([(352,326),(505,322),(520,775),(356,778)], 5, 24), fill=(88, 82, 76, 42))       # shadow half
ld.polygon(wob([(190,330),(300,328),(302,778),(175,780)], 5, 25), fill=(255, 244, 214, 52))    # lit edge
ld.rectangle([170*SS, 738*SS, 525*SS, 780*SS], fill=(80, 66, 48, 84))                          # base AO
for i in range(60):  # moss at base
    mx, my = rndc.uniform(185, 510), rndc.uniform(742, 776)
    ld.ellipse([(mx*SS, my*SS), ((mx+12)*SS, (my+8)*SS)], fill=(96, 118, 62, 130))
img.paste(Image.alpha_composite(img, lay), (0, 0), cmask); d = ImageDraw.Draw(img, 'RGBA')
# battlements: shaded merlons
for i in range(7):
    x = 196+i*46
    d.rectangle([(x*SS, 296*SS), ((x+32)*SS, 330*SS)], fill=(172, 162, 148, 255))
    d.rectangle([(x*SS, 296*SS), ((x+32)*SS, 304*SS)], fill=(206, 196, 178, 255))
    d.rectangle([((x+22)*SS, 296*SS), ((x+32)*SS, 330*SS)], fill=(138, 130, 116, 255))
# tower roofs: shingled cones like hero house + tower shading, windows, flags
for (tx, tw_, th, rh) in towers:
    top = 780 - th
    d.polygon(wob([(tx+tw_*0.55, top+rh*0.4),(tx+tw_, top+rh*0.4),(tx+tw_-8, 778),(tx+tw_*0.55, 778)], 4, 14+tx), fill=(140, 130, 116, 38))
    rp = wob([(tx-16, top+rh*0.45),(tx+tw_*0.5, top),(tx+tw_+16, top+rh*0.45)], 6, 15+tx)
    rm2 = Image.new("L", img.size, 0); ImageDraw.Draw(rm2).polygon(rp, fill=255)
    d.polygon(rp, fill=(146, 76, 46, 255))
    lay = Image.new("RGBA", img.size, (0,0,0,0)); ld = ImageDraw.Draw(lay)
    strokes(ld, (tx-14, top, tx+tw_+14, top+rh*0.45), 90, [(196, 118, 74), (110, 54, 32), (214, 146, 96)], 2, seed=tx)
    for r in range(4):
        yy = top+rh*0.42-r*22
        ld.arc([((tx-6)*SS, (yy-9)*SS), ((tx+tw_+6)*SS, (yy+9)*SS)], 0, 180, fill=(92, 46, 28, 160), width=3*SS)
    img.paste(Image.alpha_composite(img, lay), (0, 0), rm2); d = ImageDraw.Draw(img, 'RGBA')
    d.rounded_rectangle([((tx+tw_*0.32)*SS, (top+rh*0.62)*SS), ((tx+tw_*0.62)*SS, (top+rh*0.88)*SS)], 8*SS, fill=(46, 38, 30, 255), outline=(210, 198, 174, 120), width=2*SS)
    d.rectangle([((tx+tw_*0.5-3)*SS, (top-32)*SS), ((tx+tw_*0.5+3)*SS, top*SS)], fill=(92, 64, 36, 255))
    d.polygon([((tx+tw_*0.5+3)*SS, (top-32)*SS), ((tx+tw_*0.5+38)*SS, (top-22)*SS), ((tx+tw_*0.5+3)*SS, (top-12)*SS)], fill=(186, 54, 42, 255))
# gate: stone arch surround + planked door; round window; glow windows
d.rounded_rectangle([296*SS, 634*SS, 404*SS, 780*SS], 24*SS, outline=(196, 186, 168, 255), width=10*SS)
d.rounded_rectangle([304*SS, 642*SS, 396*SS, 778*SS], 20*SS, fill=(82, 60, 38, 255))
d.ellipse([304*SS, 608*SS, 396*SS, 676*SS], fill=(82, 60, 38, 255))
for px in [326, 348, 370]: d.line([(px*SS, 622*SS), (px*SS, 772*SS)], fill=(50, 36, 20, 170), width=3*SS)
for by in [690, 730]: d.line([(306*SS, by*SS), (394*SS, by*SS)], fill=(40, 34, 28, 200), width=4*SS)
d.ellipse([330*SS, 420*SS, 372*SS, 462*SS], fill=(244, 202, 120, 255), outline=(92, 80, 64, 255), width=4*SS)
for wx, wy in [(255, 500), (415, 485), (255, 590), (415, 580)]:
    d.rounded_rectangle([(wx*SS, wy*SS), ((wx+34)*SS, (wy+52)*SS)], 9*SS, fill=(246, 204, 124, 255), outline=(92, 80, 64, 255), width=4*SS)
    d.line([((wx+17)*SS, wy*SS), ((wx+17)*SS, (wy+52)*SS)], fill=(92, 80, 64, 255), width=3*SS)
for i in range(22):  # vine on left tower
    vx, vy = 150 + (i % 3)*9, 700 - i*13
    d.ellipse([(vx*SS, vy*SS), ((vx+11)*SS, (vy+8)*SS)], fill=(92, 120, 60, 180))
for ly in [452, 576, 692]:  # string courses across main wall
    d.line([(182*SS, ly*SS), (514*SS, (ly-6)*SS)], fill=(72, 64, 54, 190), width=5*SS)
    d.line([(182*SS, (ly+6)*SS), (514*SS, ly*SS)], fill=(228, 218, 196, 120), width=2*SS)
d.line([(192*SS, 332*SS), (178*SS, 776*SS)], fill=(60, 52, 44, 200), width=4*SS)
d.line([(503*SS, 326*SS), (517*SS, 772*SS)], fill=(60, 52, 44, 200), width=4*SS)
finish(img, 700, 820, "castle.png", bright=0.92, sat=0.86)

# ---------------- HERO PINE P3 (360x680, contact y~650): dense needle clusters ----------------
img = canvas(360, 680); d = ImageDraw.Draw(img, 'RGBA')
shadow(d, 180, 652, 108, 16)
d.polygon(wob([(170,300),(190,300),(197,650),(162,650)], 4, 21), fill=(96, 66, 40, 255))
strokes(d, (166, 320, 194, 646), 60, [(140, 104, 66), (70, 48, 28)], 2, horiz=False, seed=29)
pmask = Image.new("L", img.size, 0); pmd = ImageDraw.Draw(pmask)
tiers = [(54, 70), (122, 100), (196, 124), (276, 144), (362, 158), (452, 164)]
tierpolys = []
for ti, (ty, halfw) in enumerate(tiers):
    pts = [(180-halfw, ty+44)]
    for s2 in range(8):
        pts.append((180-halfw + (2*halfw)*(s2+0.5)/8, ty+64 + (s2 % 2)*17))
        pts.append((180-halfw + (2*halfw)*(s2+1)/8, ty+40))
    pts += [(180+10, ty+4), (180, ty-18), (180-10, ty+4)]
    wp = wob(pts, 4, 30+ti); tierpolys.append(wp)
    base = [(26, 70, 24), (30, 78, 26), (34, 86, 28), (38, 94, 31), (42, 102, 34), (46, 108, 37)][ti]
    d.polygon(wp, fill=base + (255,)); pmd.polygon(wp, fill=255)
lay = Image.new("RGBA", img.size, (0,0,0,0)); ld = ImageDraw.Draw(lay)
rndp = random.Random(31)
for wp in tierpolys:  # underside shadow band per tier
    pass
for i in range(1500):  # needle strokes: short angled strokes everywhere in tiers
    x, y = rndp.uniform(8, 352), rndp.uniform(30, 580)
    c = rndp.choice([(18, 52, 18), (58, 116, 40), (92, 148, 58), (130, 176, 88), (40, 92, 30)])
    ld.line([(x*SS, y*SS), ((x+rndp.uniform(-16, 16))*SS, (y+rndp.uniform(6, 14))*SS)], fill=c+(rndp.randint(90, 200),), width=2*SS)
for i in range(320):  # needle cluster dabs, light tips lower edges
    x, y = rndp.uniform(10, 350), rndp.uniform(40, 590)
    c = rndp.choice([(22, 60, 20), (70, 126, 46), (150, 190, 100)])
    ld.ellipse([(x*SS, y*SS), ((x+rndp.uniform(6, 15))*SS, (y+5)*SS)], fill=c+(170,))
img.paste(Image.alpha_composite(img, lay), (0, 0), pmask); d = ImageDraw.Draw(img, 'RGBA')
for (ty, halfw) in tiers:  # tier underside shadow + drooping dark tips
    d.line([((180-halfw)*SS, (ty+50)*SS), ((180+halfw)*SS, (ty+50)*SS)], fill=(14, 40, 14, 150), width=5*SS)
finish(img, 360, 680, "pine.png", bright=0.88, sat=0.85)

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
d.polygon(wob([(150,880),(300,560),(470,300),(610,120),(760,300),(900,180),(1060,360),(1240,300),(1380,560),(1420,880)], 16, 69), fill=(172, 178, 180, 255))  # far ridge, paler/hazier
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
lay = Image.new("RGBA", img.size, (0,0,0,0)); ld = ImageDraw.Draw(lay)
for i in range(90):  # small facet polygons breaking the large flat planes
    fx, fy = rndm.uniform(140, 1380), rndm.uniform(130, 860); fr = rndm.uniform(28, 110)
    c = rndm.choice([(188, 174, 152), (104, 96, 88), (160, 146, 124), (84, 78, 74), (206, 194, 170)])
    pts = [(fx+rndm.uniform(-fr, fr), fy+rndm.uniform(-fr*0.6, fr*0.6)) for _ in range(rndm.randint(3, 5))]
    ld.polygon([(x*SS, y*SS) for x, y in pts], fill=c+(rndm.randint(34, 80),))
strokes(ld, (80, 120, 1450, 900), 800, [(186, 172, 148), (96, 88, 80), (150, 134, 112)], 2, seed=83)
for i in range(46):  # gully shadow strokes running downhill
    gx, gy = rndm.uniform(180, 1360), rndm.uniform(160, 620)
    ld.line([(gx*SS, gy*SS), ((gx+rndm.uniform(-24, 24))*SS, (gy+rndm.uniform(60, 150))*SS)], fill=(70, 64, 60, 90), width=4*SS)
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
# painted haze: pale blue-grey bands, strongest at peaks, fading down (in the layer, not post)
lay = Image.new("RGBA", img.size, (0,0,0,0)); ld = ImageDraw.Draw(lay)
for i in range(30):
    yy = 60 + i*15; aa = max(0, 120 - i*5)
    ld.rectangle([0, yy*SS, 1500*SS, (yy+16)*SS], fill=(186, 196, 200, aa))
img.paste(Image.alpha_composite(img, lay), (0, 0), mmask); d = ImageDraw.Draw(img, 'RGBA')
for i in range(26):  # rocks + pines spilling below the base line onto the slope
    bx, by = rndm.uniform(120, 1400), rndm.uniform(896, 934)
    if i % 3: d.polygon([((bx-8)*SS, by*SS), (bx*SS, (by-rndm.uniform(14, 30))*SS), ((bx+8)*SS, by*SS)], fill=(42, 68, 34, 230))
    else: d.ellipse([((bx-13)*SS, (by-8)*SS), ((bx+13)*SS, (by+7)*SS)], fill=(110, 100, 88, 235))
alpha = img.split()[3]  # foot fade: alpha ramps down at the very base so it melts into terrain
grad = Image.new("L", img.size, 255); gd = ImageDraw.Draw(grad)
for yy in range(int(872*SS), img.size[1]):
    gd.line([(0, yy), (img.size[0], yy)], fill=int(255 - 150*(yy-872*SS)/max(1, img.size[1]-872*SS)))
img.putalpha(ImageChops.multiply(alpha, grad))
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
# --- mid-detail: crop fields with row strokes + hedge borders (mid scale, survives mips) ---
fields = [([(560,430),(800,430),(820,600),(580,620)], (168, 140, 88), (140, 116, 70)),
          ([(1180,500),(1500,480),(1520,660),(1200,680)], (128, 100, 70), (104, 80, 54)),
          ([(700,700),(1050,690),(1080,880),(730,900)], (86, 128, 54), (66, 106, 42)),
          ([(1150,300),(1480,290),(1500,450),(1170,460)], (172, 158, 100), (146, 132, 76)),
          ([(1250,760),(1580,740),(1600,920),(1280,940)], (150, 128, 78), (124, 104, 60))]
def broken(poly, seed):
    rndb = random.Random(seed); out = []
    for i in range(len(poly)):
        x0, y0 = poly[i]; x1, y1 = poly[(i+1) % len(poly)]
        for k in range(4):
            tt = k/4.0
            out.append((x0+(x1-x0)*tt + rndb.uniform(-13, 13), y0+(y1-y0)*tt + rndb.uniform(-13, 13)))
    return out
for fi, (poly0, fillc, rowc) in enumerate(fields):
    poly = broken(poly0, 300+fi)
    d.polygon(poly, fill=fillc + (110,))
    fm = Image.new("L", img.size, 0); ImageDraw.Draw(fm).polygon(poly, fill=255)
    fl = Image.new("RGBA", img.size, (0,0,0,0)); fld = ImageDraw.Draw(fl)
    for ry in range(int(min(p[1] for p in poly))+24, int(max(p[1] for p in poly)), 34):
        fld.line([(min(p[0] for p in poly), ry), (max(p[0] for p in poly), ry+14)], fill=rowc + (95,), width=9)
    img.paste(fl, (0, 0), ImageChops.multiply(fm, fl.split()[3])); d = ImageDraw.Draw(img, 'RGBA')
    d.line(poly + [poly[0]], fill=(52, 84, 34, 170), width=10)
# fences: post-and-rail lines along two field edges
for (fx0, fy0, fx1, fy1) in [(560, 600, 960, 620), (1020, 800, 1480, 760), (940, 560, 1020, 800)]:
    d.line([(fx0, fy0-8), (fx1, fy1-8)], fill=(96, 68, 42, 190), width=6)
    d.line([(fx0, fy0+6), (fx1, fy1+6)], fill=(110, 80, 48, 170), width=5)
    steps = int(math.hypot(fx1-fx0, fy1-fy0)//36)
    for i in range(steps+1):
        px, py = fx0+(fx1-fx0)*i/max(steps,1), fy0+(fy1-fy0)*i/max(steps,1)
        d.rectangle([px-4, py-13, px+4, py+9], fill=(74, 52, 30, 230))
# path wear: darker worn edges, ruts, worn patches along route
d.line([(x, y) for x, y in path], fill=(116, 92, 60, 96), width=48, joint="curve")
d.line([(x, y) for x, y in path], fill=(202, 168, 112, 165), width=27, joint="curve")
for i in range(90):
    tt = random.random(); seg = min(int(tt*(len(path)-1)), len(path)-2); ft = tt*(len(path)-1)-seg
    px = path[seg][0]+(path[seg+1][0]-path[seg][0])*ft + random.uniform(-16, 16)
    py = path[seg][1]+(path[seg+1][1]-path[seg][1])*ft + random.uniform(-11, 11)
    r = random.uniform(12, 34)
    d.ellipse([px-r, py-r*0.5, px+r, py+r*0.5], fill=random.choice([(150, 118, 76), (216, 182, 124)]) + (66,))
# --- path network connecting the actual buildings (world->texture mapping) + worn yards ---
def T(x, z): return ((x+70)/148*2048, (z+48)/92*1200)
nets = [[(0,-3.6),(-0.6,0.5),(-1.9,2.3)], [(-1.9,2.3),(-5.2,1.9)], [(-1.9,2.3),(4.7,2.9)],
        [(-1.9,2.3),(-0.9,5.2)], [(-0.6,0.5),(3.2,-1.2),(8.0,-0.3),(11.2,-0.4)],
        [(8.0,-0.3),(11.5,-4.0),(13.2,-8.5)], [(-1.9,2.3),(-7.8,5.2)], [(-5.2,1.9),(-11.0,-1.8)],
        [(-1.9,2.3),(-3.2,6.8),(2.4,8.4)]]
for net in nets:
    pts = [T(x, z) for x, z in net]
    d.line(pts, fill=(116, 92, 60, 88), width=32, joint="curve")
    d.line(pts, fill=(204, 170, 112, 175), width=19, joint="curve")
    for i in range(len(pts)-1):
        for k in range(9):
            tt = k/9.0; px = pts[i][0]+(pts[i+1][0]-pts[i][0])*tt; py = pts[i][1]+(pts[i+1][1]-pts[i][1])*tt
            d.ellipse([px-5, py-3, px+5, py+3], fill=(140, 112, 76, 90))
for (bx, bz) in [(0,-5.5),(-5.5,1.8),(5.0,2.8),(-0.8,5.6),(3.4,-1.6),(-8.2,5.4),(-11.5,-2.2),(8.6,6.4),(11.5,-0.5),(-13.0,2.0),(2.8,8.8),(-4.8,-3.8)]:
    px, py = T(bx, bz+1.4)
    d.ellipse([px-95, py-42, px+95, py+42], fill=(178, 148, 100, 62))
for i in range(110):  # vegetated patches: dark blotch clusters at mid scale
    vx, vy = random.uniform(480, 1720), random.uniform(240, 1060); vr = random.uniform(24, 68)
    d.ellipse([vx-vr, vy-vr*0.55, vx+vr, vy+vr*0.55], fill=random.choice([(58, 104, 38), (72, 118, 46), (48, 92, 34)]) + (58,))
    for k in range(7):
        tx, ty = vx+random.uniform(-vr, vr), vy+random.uniform(-vr*0.4, vr*0.4)
        d.line([tx, ty, tx+random.uniform(-4, 4), ty-random.uniform(8, 18)], fill=(52, 96, 36, 130), width=4)
# worn plots under buildings + flower patches
for (x, y, r) in [(560, 620, 150), (1180, 640, 165), (820, 330, 210), (420, 300, 110)]:
    d.ellipse([x-r, y-r*0.55, x+r, y+r*0.55], fill=(176, 148, 100, 72))
for (x, y) in [(300, 760), (1020, 860), (660, 180)]:
    for i in range(46):
        fx, fy = x + random.uniform(-95, 95), y + random.uniform(-45, 45)
        d.ellipse([fx-7, fy-5, fx+7, fy+5], fill=random.choice([(238, 96, 74), (255, 214, 84), (255, 168, 190)]) + (190,))
for i in range(42):  # distant haze, painted into the texture (not post)
    yy = i*15
    d.rectangle([0, yy, 2048, yy+15], fill=(198, 206, 194, max(0, 66-i*2)))
for i in range(18):  # richer foreground value at bottom
    yy = 950+i*15
    d.rectangle([0, yy, 2048, yy+15], fill=(46, 68, 36, i*2))
img = img.filter(ImageFilter.GaussianBlur(1.2))
img = ImageEnhance.Brightness(img).enhance(0.76)
img = ImageEnhance.Color(img).enhance(0.68)
img.save(OUT + "terrain.png"); print("painted terrain.png", img.size)
