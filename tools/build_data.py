# -*- coding: utf-8 -*-
"""
چیستان — سازنده داده‌های بازی
خروجی: assets/data/{dictionary,levels,cities,achievements,shop}.json
"""
import json, random, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from words_core import WORDS_CORE, WORDS_FOUR_EXTRA
from words_extra import WORDS_EXTRA
from words_extra2 import WORDS_EXTRA2

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "data")
os.makedirs(OUT, exist_ok=True)

ALPHABET = set("اآبپتثجچحخدذرزژسشصضطظعغفقکگلمهی")
DIACRITICS = "ًٌٍَُِّْٓٔ"
NORM = {"ي": "ی", "ك": "ک", "أ": "ا", "إ": "ا", "ٱ": "ا", "ۀ": "ه", "ة": "ه"}

def normalize(w):
    for k, v in NORM.items():
        w = w.replace(k, v)
    w = "".join(c for c in w if c not in DIACRITICS and c != "\u200c")
    return w.strip()

def valid(w):
    if not (3 <= len(w) <= 7):
        return False
    return all(c in ALPHABET for c in w)

# ---------- ۱) دیکشنری ----------
raw = (WORDS_CORE + " " + WORDS_FOUR_EXTRA + " " + WORDS_EXTRA + " " + WORDS_EXTRA2).split()
words, seen = [], set()
for tok in raw:
    w = normalize(tok)
    if not valid(w) or w in seen:
        continue
    seen.add(w)
    words.append(w)
words.sort()
by_len = {}
for w in words:
    by_len.setdefault(len(w), []).append(w)
print("دیکشنری:", len(words), "کلمه | سبد طول:", {k: len(v) for k, v in sorted(by_len.items())})

# ---------- ۲) شاخص زیرکلمه‌ها ----------
def multiset(w):
    m = {}
    for c in w:
        m[c] = m.get(c, 0) + 1
    return m

def can_form(w, pool):
    for c, n in multiset(w).items():
        if pool.get(c, 0) < n:
            return False
    return True

# ---------- ۳) چیدمان جدول تقاطعی ----------
DIRS = [(0, 1), (1, 0)]  # افقی، عمودی

def try_place(grid, word, r, c, dr, dc):
    """بررسی قابل‌قرارگیری؛ برمی‌گرداند ( crosses, cells ) یا None"""
    # خانه قبل و بعد از کلمه باید خالی باشد
    if (r - dr, c - dc) in grid: return None
    if (r + dr * len(word), c + dc * len(word)) in grid: return None
    cells, crosses = [], 0
    for i, ch in enumerate(word):
        rr, cc = r + dr * i, c + dc * i
        if (rr, cc) in grid:
            if grid[(rr, cc)] != ch: return None
            crosses += 1
            # خانه قبل/بعد از نقطه تقاطع (امتداد لغت قبلی) مجاز است
        else:
            # همسایه‌های عمود بر جهت کلمه باید خالی باشند (جلوگیری از کلمات تصادفی)
            if dr == 0:  # افقی → بالا/پایین
                if (rr - 1, cc) in grid or (rr + 1, cc) in grid: return None
            else:        # عمودی → چپ/راست
                if (rr, cc - 1) in grid or (rr, cc + 1) in grid: return None
        cells.append((rr, cc))
    return (crosses, cells) if crosses >= 1 else None

def build_crossword(words_list, rng):
    """تلاش برای چیدن همه کلمات به‌صورت متقاطع؛ در صورت شکست None"""
    order = sorted(words_list, key=lambda w: -len(w))
    for attempt in range(60):
        grid = {}
        placements = []
        w0 = order[0] if attempt < 30 else rng.choice(order)
        cells = [(0, i) for i in range(len(w0))]
        for (rc, ch) in zip(cells, w0):
            grid[rc] = ch
        placements.append({"w": w0, "cells": cells})
        ok = True
        for w in order[1:]:
            cands = []
            anchors = list(grid.items())
            rng.shuffle(anchors)
            for (ar, ac), ch in anchors:
                if ch not in w: continue
                for dr, dc in DIRS:
                    for i, lch in enumerate(w):
                        if lch != ch: continue
                        r, c = ar - dr * i, ac - dc * i
                        res = try_place(grid, w, r, c, dr, dc)
                        if res:
                            crosses, pcells = res
                            span = max(abs(rc) for rc, cc in pcells) + max(abs(cc) for rc, cc in pcells)
                            cands.append((-crosses, span, rng.random(), r, c, dr, dc, pcells))
            if not cands:
                ok = False
                break
            cands.sort()
            _, _, _, r, c, dr, dc, pcells = cands[0]
            for (rr, cc), ch in zip(pcells, w):
                grid[(rr, cc)] = ch
            placements.append({"w": w, "cells": pcells})
        if ok:
            return grid, placements
    return None, None

# ---------- ۴) ساخت مراحل ----------
rng = random.Random(20260916)
TIERS = [(1, 8, [3]), (9, 16, [4]), (17, 33, [5]), (34, 50, [5, 6]), (51, 66, [6, 7]), (67, 83, [6, 7]), (84, 100, [7, 6])]
MIN_TARGETS = {3: 2, 4: 4, 5: 5, 6: 6, 7: 6}

# استخر مناسب هر طول
root_pool = {}
for L in (3, 4, 5, 6, 7):
    pool = []
    for w in by_len.get(L, []):
        pool_ms = multiset(w)
        subs = [x for x in words if x != w and len(x) >= 3 and can_form(x, pool_ms)]
        if len(subs) + 1 >= MIN_TARGETS[L]:
            pool.append((w, subs))
    pool.sort()
    root_pool[L] = pool
    print(f"ریشه‌های {L} حرفی با حداقل زیرکلمه: {len(pool)}")

used_roots = set()
levels = []
warnings = []
for (start, end, lens) in TIERS:
    for idx in range(start, end + 1):
        levelL = lens[0]
        cand = []
        for LL in lens + [l for l in (3, 4, 5, 6, 7) if l not in lens]:
            c = [r for r in root_pool[LL] if r[0] not in used_roots]
            if c:
                if LL != lens[0]:
                    warnings.append(f"مرحله {idx}: طول {LL} به‌جای {lens[0]}")
                levelL = LL
                cand = c
                break
        if not cand:
            warnings.append(f"مرحله {idx}: ریشه پیدا نشد!")
            continue
        root, subs = cand[rng.randrange(min(len(cand), 8))]
        used_roots.add(root)
        pool_ms = multiset(root)
        all_subs = sorted([x for x in words if x != root and len(x) >= 3 and can_form(x, pool_ms)],
                          key=lambda x: (len(x), x))
        need = MIN_TARGETS[levelL]
        # اول کلمات بلند، بعد پر کردن
        long_first = sorted(all_subs, key=lambda x: (-len(x), x))
        targets = [root] + long_first[:need - 1]
        if len(targets) < need:
            targets += [w for w in long_first if w not in targets][:need - len(targets)]
        targets = targets[:10]
        bonus = [w for w in all_subs if w not in targets][:40]
        # چیدمان جدول
        grid, placements = build_crossword(targets, rng)
        layout = None
        if grid:
            rs = [r for r, c in grid]; cs = [c for r, c in grid]
            layout = {
                "min_r": min(rs), "max_r": max(rs), "min_c": min(cs), "max_c": max(cs),
                "words": [{"w": p["w"], "cells": p["cells"]} for p in placements],
            }
        levels.append({
            "id": idx, "city": None, "root": root, "letters": list(root),
            "layout": layout, "targets": targets, "bonus": bonus,
        })

# تخصیص شهر
for lv in levels:
    i = lv["id"]
    if i <= 16: lv["city"] = 0
    elif i <= 33: lv["city"] = 1
    elif i <= 50: lv["city"] = 2
    elif i <= 66: lv["city"] = 3
    elif i <= 83: lv["city"] = 4
    else: lv["city"] = 5

if warnings:
    print("هشدارها:", len(warnings))
    for w in warnings[:20]: print(" -", w)

placed = sum(1 for l in levels if l["layout"])
print(f"مراحل: {len(levels)} | جدول متقاطع: {placed} | ردیفی: {len(levels)-placed}")

# ---------- ۵) شهرها ----------
cities = [
    {"id": 0, "name": "شیراز", "levels": [1, 16],
     "tagline": "شهر شعر و گلابه؛ حافظ و سعدی اینجا نفس می‌کشند.",
     "color": "#D95A7E", "color2": "#4E9A51", "bg": "city_shiraz", "music": "shiraz",
     "motif": "گل و بلبل"},
    {"id": 1, "name": "اصفهان", "levels": [17, 33],
     "tagline": "نصف جهان؛ گنبدهای فیروزه‌ای زیر آسمان کرم.",
     "color": "#2FA8A0", "color2": "#E8862E", "bg": "city_esfahan", "music": "esfahan",
     "motif": "کاشی و گنبد"},
    {"id": 2, "name": "یزد", "levels": [34, 50],
     "tagline": "شهر بادگیرها و خشت خام؛ آفتابش گرم‌تر از چای است.",
     "color": "#C98A3B", "color2": "#D95A4E", "bg": "city_yazd", "music": "yazd",
     "motif": "بادگیر و آفتاب"},
    {"id": 3, "name": "تبریز", "levels": [51, 66],
     "tagline": "شهر اولین‌ها؛ بازارش دنیا را زیر یک سقف دارد.",
     "color": "#D95A4E", "color2": "#2FA8A0", "bg": "city_tabriz", "music": "tabriz",
     "motif": "گنبد و بازار"},
    {"id": 4, "name": "رشت", "levels": [67, 83],
     "tagline": "دل سبز گیلان؛ بارانش هم میانه و مهربان است.",
     "color": "#4E9A51", "color2": "#E8862E", "bg": "city_rasht", "music": "rasht",
     "motif": "باران و شالیزار"},
    {"id": 5, "name": "مشهد", "levels": [84, 100],
     "tagline": "آرامشِ طواف؛ شهر نذری‌ها و مهمانی‌های بزرگ.",
     "color": "#C9932B", "color2": "#4E9A51", "bg": "city_mashhad", "music": "mashhad",
     "motif": "گنبد طلایی"},
]

# ---------- ۶) دستاوردها ----------
achievements = [
    {"id": "first_word", "title": "اولین کلمه", "desc": "اولین کلمه‌ات را پیدا کن", "type": "words", "goal": 1, "reward": 20},
    {"id": "words_50", "title": "واژه‌باز", "desc": "۵۰ کلمه پیدا کن", "type": "words", "goal": 50, "reward": 60},
    {"id": "words_200", "title": "واژه‌شناس", "desc": "۲۰۰ کلمه پیدا کن", "type": "words", "goal": 200, "reward": 150},
    {"id": "words_500", "title": "فرهنگ‌دوست", "desc": "۵۰۰ کلمه پیدا کن", "type": "words", "goal": 500, "reward": 350},
    {"id": "first_level", "title": "قدم اول", "desc": "اولین مرحله را بگذران", "type": "levels", "goal": 1, "reward": 25},
    {"id": "levels_10", "title": "راه‌رونده", "desc": "۱۰ مرحله را تمام کن", "type": "levels", "goal": 10, "reward": 80},
    {"id": "levels_30", "title": "جهان‌گرد", "desc": "۳۰ مرحله را تمام کن", "type": "levels", "goal": 30, "reward": 200},
    {"id": "levels_60", "title": "راه‌آشنای ایران", "desc": "۶۰ مرحله را تمام کن", "type": "levels", "goal": 60, "reward": 400},
    {"id": "levels_100", "title": "سفر کامل", "desc": "همه ۱۰۰ مرحله را تمام کن", "type": "levels", "goal": 100, "reward": 1000},
    {"id": "stars_30", "title": "ستاره‌باران", "desc": "۳۰ ستاره جمع کن", "type": "stars", "goal": 30, "reward": 120},
    {"id": "stars_100", "title": "آسمان ستاره‌ها", "desc": "۱۰۰ ستاره جمع کن", "type": "stars", "goal": 100, "reward": 300},
    {"id": "bonus_10", "title": "کنجکاو", "desc": "۱۰ کلمه بونوس پیدا کن", "type": "bonus", "goal": 10, "reward": 50},
    {"id": "bonus_50", "title": "گنج‌یاب", "desc": "۵۰ کلمه بونوس پیدا کن", "type": "bonus", "goal": 50, "reward": 200},
    {"id": "word7", "title": "کلمه‌های بلند", "desc": "یک کلمه ۷ حرفی پیدا کن", "type": "word7", "goal": 1, "reward": 100},
    {"id": "coins_2000", "title": "خزانه‌دار", "desc": "در مجموع ۲۰۰۰ سکه جمع کن", "type": "coins", "goal": 2000, "reward": 150},
    {"id": "streak_3", "title": "سه روز پیوسته", "desc": "۳ روز پشت‌سرهم وارد بازی شو", "type": "streak", "goal": 3, "reward": 80},
    {"id": "streak_7", "title": "هفته طلایی", "desc": "۷ روز پشت‌سرهم وارد بازی شو", "type": "streak", "goal": 7, "reward": 250},
    {"id": "daily_5", "title": "چالش‌باز", "desc": "۵ چالش روزانه را بگذران", "type": "daily", "goal": 5, "reward": 150},
    {"id": "party_win", "title": "میزبان محبوب", "desc": "یک بازی حالت جمعی را ببر", "type": "party_win", "goal": 1, "reward": 120},
    {"id": "league_champ", "title": "قهرمان خانواده", "desc": "یک لیگ خانوادگی را ببر", "type": "league_win", "goal": 1, "reward": 200},
]

# ---------- ۷) فروشگاه ----------
shop = {
    "consumables": [
        {"id": "hint", "name": "سرنخ پدربزرگ", "desc": "حرف اول یک کلمه پنهان را نشان می‌دهد", "price": 30, "icon": "bulb"},
        {"id": "reveal", "name": "آشکارساز", "desc": "یک خانه از جدول را کامل آشکار می‌کند", "price": 60, "icon": "reveal"},
        {"id": "time", "name": "چای تازه دم", "desc": "در چالش روزانه ۳۰ ثانیه وقت اضافه می‌دهد", "price": 70, "icon": "tea"},
    ],
    "themes": [
        {"id": "cream", "name": "کرم کلاسیک", "price": 0, "accent": "#E8862E", "accent2": "#4E9A51", "bg": "#FBF3E4"},
        {"id": "turquoise", "name": "فیروزه اصفهان", "price": 300, "accent": "#2FA8A0", "accent2": "#E8862E", "bg": "#F0F7F4"},
        {"id": "wood", "name": "چوب و پارچه", "price": 300, "accent": "#8C5A38", "accent2": "#C9932B", "bg": "#F7EEDD"},
        {"id": "rose", "name": "گل‌محمدی", "price": 400, "accent": "#D95A7E", "accent2": "#4E9A51", "bg": "#FBF0EE"},
    ]
}

# ---------- ۸) خروجی ----------
with open(f"{OUT}/dictionary.json", "w", encoding="utf-8") as f:
    json.dump({"words": words}, f, ensure_ascii=False, separators=(",", ":"))
with open(f"{OUT}/levels.json", "w", encoding="utf-8") as f:
    json.dump({"levels": levels}, f, ensure_ascii=False, separators=(",", ":"))
with open(f"{OUT}/cities.json", "w", encoding="utf-8") as f:
    json.dump({"cities": cities}, f, ensure_ascii=False, indent=1)
with open(f"{OUT}/achievements.json", "w", encoding="utf-8") as f:
    json.dump({"achievements": achievements}, f, ensure_ascii=False, indent=1)
with open(f"{OUT}/shop.json", "w", encoding="utf-8") as f:
    json.dump(shop, f, ensure_ascii=False, indent=1)

print("خروجی‌ها در", OUT)
for lv in levels[:3] + levels[-2:]:
    print("نمونه:", lv["id"], lv["root"], "| هدف‌ها:", " ".join(lv["targets"])[:40])
