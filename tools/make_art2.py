#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
چیستان — تولید هنر فلت‌دیزاین سبک و باکیفیت
همه تصاویر با ابرنمونه‌برداری (2x) برای لبه‌های نرم + WebP بهینه
"""
import math, os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "art")
S = 2  # ضریب ابرنمونه‌برداری

# ---------- پالت ----------
CREAM   = (251, 243, 228)
CREAM2  = (246, 234, 210)
ORANGE  = (232, 134, 46)
ORANGE_D= (201, 106, 24)
GOLD    = (242, 179, 61)
GREEN   = (78, 154, 81)
TURQ    = (47, 168, 160)
RED     = (217, 90, 78)
WOOD    = (140, 90, 56)
WOOD_D  = (104, 64, 38)
TEXT    = (59, 42, 30)
SKIN    = (242, 201, 154)
SKIN_D  = (224, 176, 126)
WHITE   = (255, 255, 255)

def canvas(w, h, color=CREAM):
    img = Image.new("RGBA", (w*S, h*S), color if len(color) == 4 else color + (255,))
    return img, ImageDraw.Draw(img)

def save(img, name, q=82):
    img = img.resize((img.width//S, img.height//S), Image.LANCZOS)
    # اگر پس‌زمینه شفاف دارد، آلفا حفظ شود
    alpha = img.getextrema()[3][0] < 250 if img.mode == "RGBA" else False
    if alpha:
        img = img.convert("RGBA")
    else:
        img = img.convert("RGB")
    path = os.path.join(OUT, name)
    if name.endswith(".png"):
        img.save(path, "PNG", optimize=True)
    else:
        img.save(path, "WEBP", quality=q, method=6)
    print(f"  ✓ {name}  {os.path.getsize(path)//1024} KB")

def vgrad(size, top, bottom):
    w, h = size
    g = Image.new("RGBA", (1, h))
    for y in range(h):
        t = y / max(1, h-1)
        c = tuple(int(top[i]+(bottom[i]-top[i])*t) for i in range(3))
        g.putpixel((0, y), c + (255,))
    return g.resize((w, h))

def circle(d, cx, cy, r, fill, outline=None, ow=0):
    d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=fill, outline=outline, width=ow)

def rrect(d, box, r, fill=None, outline=None, width=1):
    d.rounded_rectangle(box, radius=r, fill=fill, outline=outline, width=width)

def poly(d, pts, fill):
    d.polygon(pts, fill=fill)

def star8(d, cx, cy, r_out, r_in, fill, rot=0.0):
    pts = []
    for i in range(16):
        r = r_out if i % 2 == 0 else r_in
        a = rot + math.pi * i / 8
        pts.append((cx + r*math.cos(a), cy + r*math.sin(a)))
    poly(d, pts, fill)

# ============================================================
# پس‌زمینه منو — کرم گرم با نقش گره‌چینی و هاله‌های نرم
# ============================================================
def menu_bg():
    W, H = 1080, 1920
    img = vgrad((W*S, H*S), (253, 248, 238), (244, 228, 198)).convert("RGBA")
    d = ImageDraw.Draw(img)
    # نقش ستاره گره هشت‌پر — بسیار ملایم
    step = 180 * S
    for row, y in enumerate(range(-60*S, H*S + step, step)):
        off = (step // 2) if row % 2 else 0
        for x in range(-60*S + off, W*S + step, step):
            star8(d, x, y, 58*S, 22*S, (WO)) if False else None
            star8(d, x, y, 58*S, 23*S, (222, 196, 152, 40))
    # هاله‌های رنگی نرم
    glow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    dg = ImageDraw.Draw(glow)
    circle(dg, 170*S, 340*S, 300*S, ORANGE + (52,))
    circle(dg, 920*S, 700*S, 260*S, TURQ + (46,))
    circle(dg, 220*S, 1500*S, 330*S, GOLD + (56,))
    circle(dg, 880*S, 1680*S, 240*S, GREEN + (36,))
    glow = glow.filter(ImageFilter.GaussianBlur(90*S))
    img = Image.alpha_composite(img, glow)
    d = ImageDraw.Draw(img)
    # چند ستاره کوچک شادی
    for (x, y, r) in [(880,260,10),(150,830,8),(990,1180,11),(90,1210,7),(640,160,8),(520,1770,9)]:
        star8(d, x*S, y*S, r*S, r*S*0.42, GOLD + (120,))
    save(img, "menu_bg.webp", 80)

# ============================================================
# شهرها — ترکیب‌های فلت با نماد معماری هر شهر
# ============================================================
def _sky(d, W, H, top, mid, bot, horizon):
    """آسمان سه‌نفسه + تپه‌های پس‌زمینه"""
    g = vgrad((W*S, H*S), top, mid)
    img = Image.new("RGBA", (W*S, H*S))
    img.paste(g, (0, 0))
    img2 = vgrad((W*S, H*S), mid, bot)
    # بخش پایین آسمان
    mask = Image.new("L", (W*S, H*S), 0)
    dm = ImageDraw.Draw(mask)
    dm.rectangle([0, horizon*S*0.35, W*S, H*S], fill=255)
    img.paste(img2, (0, 0), mask)
    return img

def _hills(d, W, H, horizon, cols):
    """تپه‌های لایه‌لایه"""
    y0 = horizon * S
    for i, c in enumerate(cols):
        yy = y0 + i * 46 * S
        pts = [(0, H*S), (0, yy + 30*S)]
        n = 5
        for k in range(n+1):
            x = W*S * k / n
            pts.append((x, yy + (18 if k % 2 else -6) * S))
        pts.append((W*S, H*S))
        poly(d, pts, c)

def _cypress(d, x, y, h, col=WOOD_D):
    """سرو — درخت نماد ایرانی"""
    w = h * 0.32
    poly(d, [(x, y), (x - w*0.32, y), (x - w*0.5, y - h*0.28), (x - w*0.24, y - h),
             (x + w*0.24, y - h), (x + w*0.5, y - h*0.28), (x + w*0.32, y)], col)
    poly(d, [(x - w*0.55, y), (x + w*0.55, y), (x + w*0.4, y + h*0.06), (x - w*0.4, y + h*0.06)], (90, 55, 34))

def _dome(d, cx, base_y, r, col, col_d, finial=GOLD):
    """گنبدهای خ defaultdict... گنبدهای خزینه‌ای لطیف"""
    d.pieslice([cx-r, base_y - 2*r, cx + r, base_y], 180, 360, fill=col)
    poly(d, [(cx-r, base_y), (cx+r, base_y), (cx+r*0.92, base_y + r*0.14), (cx-r*0.92, base_y + r*0.14)], col)
    d.pieslice([cx-r*0.55, base_y - r*0.9, cx + r*0.55, base_y + r*0.1], 180, 360, fill=col_d + (70,))
    # میله و گوی
    d.rectangle([cx - 2*S, base_y - 2*r - 26*S, cx + 2*S, base_y - 2*r + 4*S], fill=finial)
    circle(d, cx, base_y - 2*r - 32*S, 9*S, finial)

def _minaret(d, cx, base_y, h, body, body_d, cap_col):
    w = h * 0.075
    rrect(d, [cx-w, base_y-h, cx+w, base_y], w*0.6, fill=body)
    # حلقه‌های تزئینی
    for t in (0.35, 0.55):
        rrect(d, [cx-w*1.25, base_y-h + h*t, cx+w*1.25, base_y-h + h*t + 10*S], 5*S, fill=body_d)
    # بالکن
    rrect(d, [cx-w*1.6, base_y-h*0.72, cx+w*1.6, base_y-h*0.72 + 14*S], 7*S, fill=body_d)
    # کلاهک
    d.pieslice([cx-w*1.5, base_y-h - w*3.2, cx+w*1.5, base_y-h + w*1.8], 180, 360, fill=cap_col)
    d.rectangle([cx - 2*S, base_y - h - w*3.4, cx + 2*S, base_y - h - w*1.2], fill=GOLD)
    circle(d, cx, base_y - h - w*3.4, 8*S, GOLD)

def city_base(name, sky_top, sky_bot, hill_cols, accent=None):
    W, H = 960, 1280
    img, d = canvas(W, H)
    horizon = 780
    # آسمان
    g = vgrad((W*S, H*S), sky_top, sky_bot)
    img.paste(g, (0, 0))
    # خورشید/ماه نرم
    glow = Image.new("RGBA", img.size, (0,0,0,0))
    dg = ImageDraw.Draw(glow)
    circle(dg, W*S*0.76, H*S*0.2, 150*S, (255, 244, 214, 110))
    img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(50*S)))
    d = ImageDraw.Draw(img)
    circle(d, W*S*0.76, H*S*0.2, 88*S, (255, 248, 224, 235))
    _hills(d, W, H, horizon, hill_cols)
    return img, d, W, H, horizon

def city_shiraz():
    # شیراز — حافظیه: گنبد کاشی فیروزه‌ای میان سروها و گل‌ها، آسمان گلبهی
    img, d, W, H, horizon = city_base("shiraz", (247, 205, 205), (238, 168, 158),
                                      [(214, 148, 138), (190, 128, 118), (164, 108, 100)])
    gy = horizon * S
    # سکو و پایه بنا
    rrect(d, [W*S*0.16, gy - 30*S, W*S*0.84, gy + 60*S], 16*S, (206, 152, 138))
    body_top = gy - 420*S
    # بدنه حافظیه — هشت ستون
    rrect(d, [W*S*0.24, body_top + 120*S, W*S*0.76, gy - 20*S], 14*S, (245, 232, 208))
    for i in range(4):
        cx = W*S*(0.30 + 0.133*i)
        rrect(d, [cx - 14*S, body_top + 140*S, cx + 14*S, gy - 40*S], 12*S, (230, 208, 176))
    # گنبد کاشی فیروزه‌ای
    _dome(d, W*S*0.5, body_top + 130*S, 170*S, TURQ, (24, 128, 122))
    # طاق ورودی
    iw = 70*S; ih = 150*S
    d.pieslice([W*S*0.5 - iw, body_top + 150*S, W*S*0.5 + iw, body_top + 150*S + 2*ih], 180, 360, (150, 96, 70))
    d.rectangle([W*S*0.5 - iw, body_top + 150*S + ih, W*S*0.5 + iw, gy - 30*S], (150, 96, 70))
    # سروها دو طرف
    _cypress(d, W*S*0.13, gy - 20*S, 330*S)
    _cypress(d, W*S*0.87, gy - 20*S, 300*S)
    _cypress(d, W*S*0.075, gy + 30*S, 240*S, (86, 118, 74))
    _cypress(d, W*S*0.925, gy + 30*S, 250*S, (86, 118, 74))
    # باغ گل — بوته‌های رز
    for (x, y, c) in [(180, 1080, RED), (320, 1120, (233, 96, 130)), (640, 1100, RED), (790, 1130, (233, 96, 130)), (90, 1170, (233, 96, 130)), (920, 1160, RED)]:
        circle(d, x*S, y*S, 34*S, (74, 132, 70))
        for a in range(6):
            ang = a * math.pi / 3
            circle(d, x*S + 22*S*math.cos(ang), y*S + 14*S*math.sin(ang), 13*S, c)
        circle(d, x*S, y*S - 4*S, 9*S, GOLD)
    save(img, "city_shiraz.webp")

def city_esfahan():
    # اصفهان — گنبد فیروزه‌ای و مناره‌های مسجد، آسمان طلایی
    img, d, W, H, horizon = city_base("esfahan", (250, 214, 160), (244, 190, 130),
                                      [(216, 158, 106), (192, 134, 88), (168, 112, 74)])
    gy = horizon * S
    # سکو
    rrect(d, [W*S*0.1, gy - 26*S, W*S*0.9, gy + 60*S], 16*S, (204, 148, 100))
    body_top = gy - 460*S
    # بدنه
    rrect(d, [W*S*0.22, body_top + 150*S, W*S*0.78, gy - 20*S], 14*S, (248, 236, 210))
    # ایوان — طاق بزرگ
    iw = 120*S; ih = 210*S
    d.pieslice([W*S*0.5 - iw, body_top + 160*S, W*S*0.5 + iw, body_top + 160*S + 2*ih], 180, 360, (60, 150, 142))
    d.rectangle([W*S*0.5 - iw, body_top + 160*S + ih, W*S*0.5 + iw, gy - 26*S], (60, 150, 142))
    # قاب کاشی دور ایوان
    d.arc([W*S*0.5 - iw - 16*S, body_top + 144*S, W*S*0.5 + iw + 16*S, body_top + 160*S + 2*ih + 16*S], 180, 360, fill=GOLD, width=8*S)
    # گنبد بزرگ
    _dome(d, W*S*0.34, body_top + 170*S, 150*S, (36, 156, 148), (22, 118, 112))
    _dome(d, W*S*0.68, body_top + 190*S, 90*S, (36, 156, 148), (22, 118, 112))
    # مناره‌ها
    _minaret(d, W*S*0.16, gy - 20*S, 520*S, (248, 236, 210), (222, 198, 160), GOLD)
    _minaret(d, W*S*0.84, gy - 20*S, 520*S, (248, 236, 210), (222, 198, 160), GOLD)
    save(img, "city_esfahan.webp")

def city_yazd():
    # یزد — بادگیرها و بافت خشتی، آسمان گرم
    img, d, W, H, horizon = city_base("yazd", (250, 196, 130), (240, 164, 100),
                                      [(212, 140, 88), (188, 120, 74), (164, 100, 62)])
    gy = horizon * S
    # دیوار خشتی شهر
    rrect(d, [W*S*0.08, gy - 300*S, W*S*0.92, gy + 50*S], 10*S, (236, 200, 152))
    # بادگیر مرکزی بلند
    bx, bw, bh = W*S*0.5, 150*S, 460*S
    rrect(d, [bx - bw/2, gy - bh - 130*S, bx + bw/2, gy - 40*S], 12*S, (242, 212, 164))
    # شیارهای بادگیر
    for i in range(4):
        xx = bx - bw/2 + bw*(i+0.5)/4
        d.rectangle([xx - 10*S, gy - bh - 120*S, xx + 10*S, gy - bh*0.28], fill=(198, 158, 110))
    # سقف بادگیر
    rrect(d, [bx - bw/2 - 20*S, gy - bh - 160*S, bx + bw/2 + 20*S, gy - bh - 110*S], 14*S, (222, 182, 132))
    # بادگیرهای کوچک
    for sx in (0.24, 0.76):
        sw, sh = 90*S, 240*S
        rrect(d, [W*S*sx - sw/2, gy - sh - 90*S, W*S*sx + sw/2, gy - 60*S], 10*S, (242, 212, 164))
        for i in range(3):
            xx = W*S*sx - sw/2 + sw*(i+0.5)/3
            d.rectangle([xx - 7*S, gy - sh - 82*S, xx + 7*S, gy - sh*0.35], fill=(198, 158, 110))
        rrect(d, [W*S*sx - sw/2 - 14*S, gy - sh - 116*S, W*S*sx + sw/2 + 14*S, gy - sh - 76*S], 10*S, (222, 182, 132))
    # در و پنجره‌های چوبی
    d.pieslice([W*S*0.42, gy - 210*S, W*S*0.58, gy + 10*S], 180, 360, WOOD)
    d.rectangle([W*S*0.42, gy - 110*S, W*S*0.58, gy + 10*S], WOOD)
    for (wx, wy) in [(0.3, 0.86), (0.7, 0.86)]:
        rrect(d, [W*S*wx - 26*S, gy - 210*S + 220*S*wy, W*S*wx + 26*S, gy - 210*S + 220*S*wy + 70*S], 26*S, WOOD)
    # کاهگل روشن جلو
    _hills(d, 960, 1280, 1120, [(226, 172, 116)])
    save(img, "city_yazd.webp")

def city_tabriz():
    # تبریز — عمارت ائل‌گلی: بنای قرمز روی تپه سبز با استخر
    img, d, W, H, horizon = city_base("tabriz", (188, 226, 236), (142, 200, 214),
                                      [(96, 172, 148), (72, 148, 124), (58, 124, 102)])
    gy = horizon * S
    _hills(d, 960, 1280, gy/S + 60, [(96, 172, 148)])
    # استخر
    rrect(d, [W*S*0.14, gy + 240*S, W*S*0.86, gy + 560*S], 30*S, (66, 150, 176))
    d.rectangle([W*S*0.14, gy + 300*S, W*S*0.86, gy + 320*S], (120, 190, 208))
    d.rectangle([W*S*0.14, gy + 400*S, W*S*0.86, gy + 415*S], (120, 190, 208))
    # تپه
    d.ellipse([W*S*0.2, gy - 160*S, W*S*0.8, gy + 420*S], (110, 178, 128))
    # عمارت — سه طاق قرمز کلاسیک
    by = gy - 60*S
    rrect(d, [W*S*0.3, by - 320*S, W*S*0.7, by], 16*S, (214, 106, 84))
    rrect(d, [W*S*0.28, by - 350*S, W*S*0.72, by - 300*S], 14*S, (196, 92, 72))
    for i in range(3):
        ax = W*S*(0.375 + 0.125*i)
        d.pieslice([ax - 44*S, by - 250*S, ax + 44*S, by - 130*S], 180, 360, (248, 236, 210))
        d.rectangle([ax - 44*S, by - 190*S, ax + 44*S, by - 30*S], (248, 236, 210))
    _dome(d, W*S*0.5, by - 330*S, 70*S, (196, 92, 72), (170, 76, 58), GOLD)
    save(img, "city_tabriz.webp")

def city_rasht():
    # رشت — خانه گیلانی با سقف سفالی قرمز در میان برنج‌زارهای سبز و باران نرم
    img, d, W, H, horizon = city_base("rasht", (200, 228, 214), (156, 204, 180),
                                      [(88, 160, 108), (66, 136, 88), (52, 112, 72)])
    gy = horizon * S
    # برنج‌زار — خطوط
    for i in range(6):
        yy = gy + 140*S + i * 90*S
        d.rectangle([0, yy, W*S, yy + 14*S], (96, 172, 112))
    # خانه گیلانی
    hx, hw = W*S*0.5, 480*S
    hy = gy + 120*S
    # بدنه
    rrect(d, [hx - hw/2, hy - 260*S, hx + hw/2, hy], 8*S, (246, 234, 208))
    # سقف شیروانی قرمز
    poly(d, [(hx - hw/2 - 70*S, hy - 250*S), (hx, hy - 470*S), (hx + hw/2 + 70*S, hy - 250*S)], (206, 92, 74))
    poly(d, [(hx - hw/2 - 70*S, hy - 250*S), (hx, hy - 470*S), (hx + hw/2 + 70*S, hy - 250*S), (hx + hw/2 + 70*S, hy - 232*S), (hx, hy - 452*S), (hx - hw/2 - 70*S, hy - 232*S)], (178, 76, 60))
    # در و پنجره
    d.pieslice([hx - 50*S, hy - 190*S, hx + 50*S, hy - 60*S], 180, 360, WOOD)
    d.rectangle([hx - 50*S, hy - 125*S, hx + 50*S, hy - 20*S], WOOD)
    for wx in (-0.3, 0.3):
        rrect(d, [hx + hw*wx - 40*S, hy - 200*S, hx + hw*wx + 40*S, hy - 110*S], 10*S, (150, 196, 208))
        d.rectangle([hx + hw*wx - 4*S, hy - 200*S, hx + hw*wx + 4*S, hy - 110*S], (120, 160, 170))
    # درختان پرپشت
    for (tx, ty, th) in [(0.14, gy/S + 90, 300), (0.86, gy/S + 100, 340), (0.05, gy/S + 260, 260)]:
        circle(d, W*S*tx, (ty - th*0.4)*S, th*0.36*S, (58, 128, 84))
        circle(d, W*S*tx - th*0.18*S, (ty - th*0.2)*S, th*0.3*S, (72, 146, 96))
        circle(d, W*S*tx + th*0.18*S, (ty - th*0.22)*S, th*0.3*S, (66, 138, 90))
        d.rectangle([W*S*tx - 8*S, ty*S, W*S*tx + 8*S, (ty + 40)*S], (92, 62, 40))
    save(img, "city_rasht.webp")

def city_mashhad():
    # مشهد — گنبد طلایی و مناره‌های بلند، کاشی فیروزه‌ای
    img, d, W, H, horizon = city_base("mashhad", (176, 214, 226), (136, 192, 208),
                                      [(148, 150, 190), (120, 122, 162), (98, 100, 138)])
    gy = horizon * S
    rrect(d, [W*S*0.08, gy - 26*S, W*S*0.92, gy + 60*S], 16*S, (180, 152, 176))
    body_top = gy - 480*S
    # صحن
    rrect(d, [W*S*0.2, body_top + 190*S, W*S*0.8, gy - 20*S], 14*S, (248, 240, 220))
    # نوار کاشی فیروزه
    d.rectangle([W*S*0.2, body_top + 260*S, W*S*0.8, body_top + 300*S], (36, 156, 148))
    # گنبد طلایی
    _dome(d, W*S*0.5, body_top + 200*S, 160*S, GOLD, (216, 148, 40), (240, 200, 90))
    # ایوان طلا
    iw = 90*S; ih = 190*S
    d.pieslice([W*S*0.5 - iw, body_top + 220*S, W*S*0.5 + iw, body_top + 220*S + 2*ih], 180, 360, GOLD)
    d.rectangle([W*S*0.5 - iw, body_top + 220*S + ih, W*S*0.5 + iw, gy - 26*S], GOLD)
    # دو مناره بلند طلایی‌کلاه
    _minaret(d, W*S*0.14, gy - 20*S, 560*S, (248, 240, 220), (220, 196, 172), GOLD)
    _minaret(d, W*S*0.86, gy - 20*S, 560*S, (248, 240, 220), (220, 196, 172), GOLD)
    save(img, "city_mashhad.webp")

# ============================================================
# پدربزرگ — کاراکتر فلت سه‌حالته
# ============================================================
def grandfather(pose):
    SZ = 560
    img, d = canvas(SZ, SZ, (0, 0, 0, 0))
    cx = SZ * S // 2
    # — سایه زمین
    d.ellipse([cx - 150*S, 500*S, cx + 150*S, 545*S], (0, 0, 0, 40))
    # — عبا (بدنه)
    body_top = 300*S
    poly(d, [(cx - 185*S, 530*S), (cx - 130*S, body_top), (cx + 130*S, body_top), (cx + 185*S, 530*S)], WOOD)
    poly(d, [(cx - 185*S, 530*S), (cx - 130*S, body_top), (cx - 60*S, body_top), (cx - 95*S, 530*S)], WOOD_D)  # سایه
    # یقه پیراهن کرم
    poly(d, [(cx - 55*S, body_top + 6*S), (cx, body_top + 70*S), (cx + 55*S, body_top + 6*S)], CREAM)
    # — بازوها
    def arm(x1, y1, x2, y2, w=42):
        d.line([(x1, y1), (x2, y2)], fill=WOOD, width=w*S)
        circle(d, x2, y2, w*0.62*S, SKIN)  # دست
    if pose == "celebrate":
        arm(cx - 120*S, body_top + 40*S, cx - 225*S, 150*S)
        arm(cx + 120*S, body_top + 40*S, cx + 225*S, 150*S)
    elif pose == "think":
        arm(cx - 120*S, body_top + 40*S, cx - 170*S, 430*S)
        # دست زیر چانه
        arm(cx + 120*S, body_top + 40*S, cx + 95*S, 300*S, 38)
    else:  # welcome — دست تکان
        arm(cx - 120*S, body_top + 40*S, cx - 190*S, 380*S)
        arm(cx + 120*S, body_top + 40*S, cx + 205*S, 265*S)
    # — استکان چای (welcome و celebrate)
    if pose in ("welcome", "celebrate"):
        tx = cx + (205 if pose == "welcome" else 225) * S
        ty = (265 if pose == "welcome" else 150) * S
        rrect(d, [tx - 30*S, ty - 10*S, tx + 30*S, ty + 62*S], 10*S, (250, 250, 250, 235))
        poly(d, [(tx - 24*S, ty + 6*S), (tx + 24*S, ty + 6*S), (tx + 17*S, ty + 56*S), (tx - 17*S, ty + 56*S)], (206, 120, 40))
        poly(d, [(tx - 24*S, ty + 6*S), (tx + 24*S, ty + 6*S), (tx + 22*S, ty + 20*S), (tx - 22*S, ty + 20*S)], (232, 156, 60))
        d.arc([tx + 26*S, ty + 2*S, tx + 58*S, ty + 40*S], 270, 120, fill=WOOD, width=6*S)
    # — سر
    hy = 170*S
    hr = 128*S
    circle(d, cx, hy, hr, SKIN)
    circle(d, cx - hr*0.92, hy + 10*S, 18*S, SKIN_D)  # گوش
    circle(d, cx + hr*0.92, hy + 10*S, 18*S, SKIN_D)
    # — ریش سفید بزرگ
    beard = [(cx - hr*0.88, hy - 6*S), (cx + hr*0.88, hy - 6*S),
             (cx + hr*0.8, hy + hr*0.55), (cx + hr*0.45, hy + hr*1.12),
             (cx, hy + hr*1.28), (cx - hr*0.45, hy + hr*1.12), (cx - hr*0.8, hy + hr*0.55)]
    poly(d, beard, (244, 246, 248))
    # سبیل
    poly(d, [(cx - 74*S, hy + 34*S), (cx + 74*S, hy + 34*S), (cx + 40*S, hy + 66*S), (cx - 40*S, hy + 66*S)], (255, 255, 255))
    # — کلاه نمدی قهوه‌ای
    d.pieslice([cx - hr*1.02, hy - hr*1.22, cx + hr*1.02, hy - hr*0.1], 180, 360, (110, 76, 52))
    rrect(d, [cx - hr*1.08, hy - hr*0.42, cx + hr*1.08, hy - hr*0.18], 16*S, (92, 62, 42))
    # نوار کلاه
    d.rectangle([cx - hr*1.06, hy - hr*0.44, cx + hr*1.06, hy - hr*0.36], GOLD)
    # — ابروها
    brow_y = hy - 30*S
    if pose == "think":
        rrect(d, [cx - 78*S, brow_y - 16*S, cx - 26*S, brow_y - 2*S], 8*S, (240, 242, 246))
        rrect(d, [cx + 26*S, brow_y - 26*S, cx + 78*S, brow_y - 8*S], 8*S, (240, 242, 246))
    else:
        rrect(d, [cx - 78*S, brow_y - 12*S, cx - 26*S, brow_y], 8*S, (240, 242, 246))
        rrect(d, [cx + 26*S, brow_y - 12*S, cx + 78*S, brow_y], 8*S, (240, 242, 246))
    # — چشم‌ها
    if pose == "celebrate":
        # چشم‌های خندان (کمان)
        d.arc([cx - 62*S, hy - 22*S, cx - 22*S, hy + 18*S], 200, 340, fill=TEXT, width=9*S)
        d.arc([cx + 22*S, hy - 22*S, cx + 62*S, hy + 18*S], 200, 340, fill=TEXT, width=9*S)
    else:
        circle(d, cx - 42*S, hy - 4*S, 11*S, TEXT)
        circle(d, cx + 42*S, hy - 4*S, 11*S, TEXT)
        circle(d, cx - 38*S, hy - 8*S, 4*S, WHITE)
        circle(d, cx + 46*S, hy - 8*S, 4*S, WHITE)
    # — عینک گرد طلایی
    d.ellipse([cx - 74*S, hy - 40*S, cx - 10*S, hy + 24*S], outline=(198, 148, 58), width=7*S)
    d.ellipse([cx + 10*S, hy - 40*S, cx + 74*S, hy + 24*S], outline=(198, 148, 58), width=7*S)
    d.line([(cx - 10*S, hy - 8*S), (cx + 10*S, hy - 8*S)], fill=(198, 148, 58), width=6*S)
    # — لپ‌های گل‌اندازی
    circle(d, cx - 88*S, hy + 26*S, 14*S, (238, 160, 140, 90))
    circle(d, cx + 88*S, hy + 26*S, 14*S, (238, 160, 140, 90))
    # — دهان خندان روی ریش
    if pose in ("welcome", "celebrate"):
        d.arc([cx - 30*S, hy + 30*S, cx + 30*S, hy + 74*S], 20, 160, fill=(150, 120, 110), width=8*S)
    save(img, f"grand_{pose}.webp", 88)

# ============================================================
# آیکون‌ها
# ============================================================
def ic_coin():
    img, d = canvas(192, 192, (0,0,0,0))
    circle(d, 96*S, 100*S, 82*S, (176, 118, 20, 255))       # سایه
    circle(d, 96*S, 92*S, 82*S, GOLD)
    circle(d, 96*S, 92*S, 62*S, (218, 158, 52))
    star8(d, 96*S, 92*S, 34*S, 15*S, (178, 120, 26))
    save(img, "ic_coin.webp", 90)

def ic_star():
    img, d = canvas(192, 192, (0,0,0,0))
    d.regular_polygon((96*S, 100*S, 86*S), 5, rotation=-90, fill=(176, 118, 20))
    d.regular_polygon((96*S, 92*S, 86*S), 5, rotation=-90, fill=GOLD)
    d.regular_polygon((96*S, 86*S, 52*S), 5, rotation=-90, fill=(250, 214, 120))
    save(img, "ic_star.webp", 90)

def ic_trophy():
    img, d = canvas(192, 192, (0,0,0,0))
    circle(d, 96*S, 92*S, 84*S, TURQ + (255,))
    # جام
    poly(d, [(60*S, 52*S), (132*S, 52*S), (124*S, 106*S), (96*S, 120*S), (68*S, 106*S)], GOLD)
    d.rectangle([90*S, 118*S, 102*S, 138*S], (218, 158, 52))
    rrect(d, [68*S, 136*S, 124*S, 150*S], 6*S, (218, 158, 52))
    # دسته‌ها
    d.arc([40*S, 54*S, 72*S, 92*S], 90, 270, fill=(218, 158, 52), width=8*S)
    d.arc([120*S, 54*S, 152*S, 92*S], 270, 90, fill=(218, 158, 52), width=8*S)
    star8(d, 96*S, 78*S, 16*S, 7*S, WHITE + (230,))
    save(img, "ic_trophy.webp", 90)

def ic_chest():
    img, d = canvas(192, 192, (0,0,0,0))
    circle(d, 96*S, 92*S, 84*S, WOOD + (255,))
    rrect(d, [48*S, 78*S, 144*S, 146*S], 12*S, (170, 108, 62))
    d.pieslice([48*S, 56*S, 144*S, 128*S], 180, 360, (192, 126, 74))
    rrect(d, [88*S, 96*S, 104*S, 122*S], 4*S, GOLD)
    circle(d, 96*S, 106*S, 8*S, (218, 158, 52))
    d.rectangle([48*S, 104*S, 60*S, 112*S], GOLD)
    d.rectangle([132*S, 104*S, 144*S, 112*S], GOLD)
    save(img, "ic_chest.webp", 90)

def ic_gift():
    img, d = canvas(192, 192, (0,0,0,0))
    circle(d, 96*S, 92*S, 84*S, RED + (255,))
    rrect(d, [52*S, 84*S, 140*S, 146*S], 8*S, (238, 108, 92))
    rrect(d, [48*S, 68*S, 144*S, 92*S], 8*S, (222, 88, 74))
    d.rectangle([88*S, 68*S, 104*S, 146*S], GOLD)
    d.ellipse([66*S, 44*S, 92*S, 70*S], outline=GOLD, width=9*S)
    d.ellipse([100*S, 44*S, 126*S, 70*S], outline=GOLD, width=9*S)
    save(img, "ic_gift.webp", 90)

def app_icon():
    SZ = 432
    img, d = canvas(SZ, SZ, (0,0,0,0))
    # زمینه گرد با گرادیان نارنجی
    base = vgrad((SZ*S, SZ*S), (244, 152, 62), (208, 112, 30))
    mask = Image.new("L", (SZ*S, SZ*S), 0)
    dm = ImageDraw.Draw(mask)
    dm.rounded_rectangle([0, 0, SZ*S, SZ*S], radius=96*S, fill=255)
    img = Image.composite(base.convert("RGBA"), img, mask)
    d = ImageDraw.Draw(img)
    # نقش گره ملایم
    for row, y in enumerate(range(-40*S, SZ*S + 120*S, 120*S)):
        off = 60*S if row % 2 else 0
        for x in range(-40*S + off, SZ*S + 120*S, 120*S):
            star8(d, x, y, 34*S, 14*S, (255, 255, 255, 16))
    # هاله مرکزی
    glow = Image.new("RGBA", img.size, (0,0,0,0))
    dg = ImageDraw.Draw(glow)
    circle(dg, SZ*S//2, SZ*S//2, 150*S, (255, 236, 200, 90))
    img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(40*S)))
    d = ImageDraw.Draw(img)
    # حرف «چ» با فونت وزیرمتن
    font = ImageFont.truetype(os.path.join(OUT, "..", "fonts", "Vazirmatn-Black.ttf"), 250*S)
    bbox = d.textbbox((0, 0), "چ", font=font)
    tw, th = bbox[2]-bbox[0], bbox[3]-bbox[1]
    d.text((SZ*S//2 - tw/2 - bbox[0], SZ*S//2 - th/2 - bbox[1] - 6*S), "چ", font=font, fill=(255, 252, 244))
    # دو ستاره کوچک
    star8(d, 88*S, 92*S, 22*S, 9*S, (255, 240, 200, 200))
    star8(d, 344*S, 330*S, 26*S, 11*S, (255, 240, 200, 170))
    save(img, "icon.png", 95)

if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    print("تولید هنر چیستان…")
    menu_bg()
    city_shiraz(); city_esfahan(); city_yazd(); city_tabriz(); city_rasht(); city_mashhad()
    grandfather("welcome"); grandfather("think"); grandfather("celebrate")
    ic_coin(); ic_star(); ic_trophy(); ic_chest(); ic_gift()
    app_icon()
    print("تمام شد.")
