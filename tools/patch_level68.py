# -*- coding: utf-8 -*-
"""پچ مرحله ۶۸ — ساخت چیدمان متقاطع برای ریشه «قلمکار» با زیرمجموعه قابل‌چیدن"""
import json, random, os

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "..", "assets", "data")

DIRS = [(0, 1), (1, 0)]

def try_place(grid, word, r, c, dr, dc):
    if (r - dr, c - dc) in grid: return None
    if (r + dr * len(word), c + dc * len(word)) in grid: return None
    cells, crosses = [], 0
    for i, ch in enumerate(word):
        rr, cc = r + dr * i, c + dc * i
        if (rr, cc) in grid:
            if grid[(rr, cc)] != ch: return None
            crosses += 1
        else:
            if dr == 0:
                if (rr - 1, cc) in grid or (rr + 1, cc) in grid: return None
            else:
                if (rr, cc - 1) in grid or (rr, cc + 1) in grid: return None
        cells.append((rr, cc))
    return (crosses, cells) if crosses >= 1 else None

def build_crossword(words_list, rng, attempts=400):
    order = sorted(words_list, key=lambda w: -len(w))
    for _ in range(attempts):
        grid = {}
        placements = []
        w0 = order[0]
        for i, ch in enumerate(w0):
            grid[(0, i)] = ch
        placements.append({"w": w0, "cells": [[0, i] for i in range(len(w0))]})
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
                            cands.append((-crosses, span, rng.random(), pcells))
            if not cands:
                ok = False
                break
            cands.sort()
            _, _, _, pcells = cands[0]
            for (rr, cc), ch in zip(pcells, w):
                grid[(rr, cc)] = ch
            placements.append({"w": w, "cells": [list(x) for x in pcells]})
        if ok:
            return grid, placements
    return None, None

def main():
    with open(f"{DATA}/levels.json", encoding="utf-8") as f:
        doc = json.load(f)
    lv = next(l for l in doc["levels"] if l["id"] == 68)
    root = lv["root"]                     # قلمکار
    pool = [w for w in lv["targets"] if w != root]
    rng = random.Random(682026)
    placed_combo = None
    # از کامل‌ترین ترکیب شروع کن؛ اگر نشد کلمات سخت‌چین را کم کن
    for keep in range(len(pool), 1, -1):
        for trial in range(80):
            combo = [root] + rng.sample(pool, keep)
            grid, placements = build_crossword(combo, rng)
            if grid:
                placed_combo = (combo, grid, placements)
                break
        if placed_combo:
            break
    assert placed_combo, "هیچ ترکیبی چیده نشد!"
    combo, grid, placements = placed_combo
    rs = [r for r, c in grid]; cs = [c for r, c in grid]
    lv["layout"] = {
        "min_r": min(rs), "max_r": max(rs), "min_c": min(cs), "max_c": max(cs),
        "words": [{"w": p["w"], "cells": p["cells"]} for p in placements],
    }
    lv["targets"] = combo
    dropped = [w for w in [root] + pool if w not in combo]
    lv["bonus"] = dropped + [w for w in lv["bonus"] if w not in combo and w not in dropped]
    with open(f"{DATA}/levels.json", "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, separators=(",", ":"))
    print("مرحله ۶۸ اصلاح شد | هدف‌ها:", " ".join(combo))
    print("به بونوس منتقل شد:", " ".join(dropped))

if __name__ == "__main__":
    main()
