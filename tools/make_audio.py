# -*- coding: utf-8 -*-
"""
چیستان — سازنده موسیقی و افکت صوتی
سنتور/تار (Karplus-Strong)، کمانچه (آرشه)، نی، دف — با ربع‌پرده‌های فارسی (کرون/سری)
خروجی: assets/audio/music/*.ogg و assets/audio/sfx/*.wav
"""
import numpy as np, wave, os, subprocess, random

SR = 44100
BASE = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "audio")
MUS = os.path.join(BASE, "music"); SFX = os.path.join(BASE, "sfx")
os.makedirs(MUS, exist_ok=True); os.makedirs(SFX, exist_ok=True)

# ---------- گام‌های فارسی (نیم‌پرده از نت پایه D4؛ ۱.۵ = کرون، ۳.۵ = سری) ----------
D4 = 293.665
SCALES = {
    "shur":       [0, 1.5, 3, 5, 7, 8, 10],
    "homayun":    [0, 2, 3.5, 5, 7, 8, 11],
    "mahur":      [0, 2, 4, 5, 7, 9, 11],
    "dashti":     [0, 1.5, 3, 5, 7, 8, 10],
    "bayat_tork": [0, 1.5, 3, 5, 7, 9, 10],
    "esfahan":    [0, 2, 3, 5, 7, 8, 11],
}
def deg2hz(scale, deg, octv=0):
    """درجه گام (می‌تواند منفی/بیش از ۷ باشد) → فرکانس"""
    n = len(scale)
    idx = deg % n; o = deg // n + octv
    return D4 * (2 ** (o + scale[idx] / 12))

# ---------- سازها ----------
def _ks_note(freq, dur, damp=0.996, bright=0.5, seed=0):
    """Karplus-Strong وکتورایز شده (پردازش پریود‌به‌پریود)"""
    rng = np.random.default_rng(seed)
    N = max(2, int(SR / freq))
    exc = rng.uniform(-1, 1, N)
    b = 0.35 + bright * 0.55
    total = int(dur * SR)
    out = np.empty(total)
    buf = exc.copy()
    pos = 0
    while pos < total:
        n = min(N, total - pos)
        out[pos:pos + n] = buf[:n]
        buf = b * 0.5 * (buf + np.roll(buf, -1))
        buf = buf * damp
        pos += n
    return out

def pluck(freq, dur, amp=0.5, bright=0.6, damp=0.996, detune=0.0015, seed=1):
    """نواختن پلک (سنتور/تار) با دومین رشته کوک‌دار"""
    a = _ks_note(freq, dur, damp, bright, seed=int(seed * 7919 + freq) % 99991)
    b = _ks_note(freq * (1 + detune), dur, damp, bright, seed=int(seed * 104729 + freq) % 99991)
    n = min(len(a), len(b))
    env = np.exp(-np.linspace(0, 4.2, n))
    s = (a[:n] + b[:n]) * 0.5 * env
    m = np.max(np.abs(s)) + 1e-9
    return s / m * amp

def kamancheh(freq, dur, amp=0.4, seed=1):
    """کمانچه — موج اره‌ای با ویبراتو و نرمی آرشه"""
    n = int(dur * SR)
    t = np.arange(n) / SR
    vib = 1 + 0.008 * np.sin(2 * np.pi * 5.2 * t + seed)
    phase = np.cumsum(2 * np.pi * freq * vib / SR)
    raw = ((phase % 1) - 0.5) * 2
    raw += 0.35 * (((phase * 2) % 1) - 0.5)
    # فیلتر پایین‌گذر ساده
    k = 0.12
    out = np.zeros(n); prev = 0.0
    for_noise = np.linspace(0, 1, n)
    env = np.minimum(for_noise * 6, 1) * np.exp(-for_noise * 2.2)
    # پیاده‌سازی فیلتر بدون حلقه (IIR با scipy نداریم → تقریب MA)
    w = 41
    kern = np.hanning(w); kern /= kern.sum()
    out = np.convolve(raw, kern, mode="same")
    return out * env * amp

def ney(freq, dur, amp=0.35, seed=1):
    """نی — سینوس + نفس نویزی"""
    n = int(dur * SR)
    t = np.arange(n) / SR
    rng = np.random.default_rng(int(seed))
    vib = 1 + 0.011 * np.sin(2 * np.pi * 4.6 * t + rng.uniform(0, 6))
    phase = np.cumsum(2 * np.pi * freq * vib / SR)
    tone = np.sin(phase) + 0.18 * np.sin(2 * phase) + 0.06 * np.sin(3 * phase)
    breath = rng.uniform(-1, 1, n) * 0.06
    kern = np.hanning(9); kern /= kern.sum()
    breath = np.convolve(breath, kern, mode="same")
    env = np.minimum(t / 0.09, 1) * np.exp(-t * 1.1)
    s = (tone + breath) * env
    return s / (np.max(np.abs(s)) + 1e-9) * amp

def daf_hit(kind, amp=0.5, seed=1):
    """دف — دم (بم) / تک (زیر) / ریز"""
    n = int(0.28 * SR)
    t = np.arange(n) / SR
    rng = np.random.default_rng(int(seed * 131 + hash(kind) % 97))
    if kind == "dum":
        f = 92 + rng.uniform(-4, 4)
        body = np.sin(2 * np.pi * f * t) * np.exp(-t * 22)
        body += 0.5 * np.sin(2 * np.pi * f * 2.7 * t) * np.exp(-t * 30)
        ring = rng.uniform(-1, 1, n) * np.exp(-t * 45) * 0.25
        s = (body + ring) * amp
    else:  # tek / rim
        noise = rng.uniform(-1, 1, n)
        kern = np.hanning(7); kern /= kern.sum()
        hp = noise - np.convolve(noise, np.ones(23) / 23, mode="same")
        decay = np.exp(-t * (55 if kind == "tek" else 80))
        jingle = rng.uniform(-1, 1, n) * np.exp(-t * 70) * 0.5
        s = (hp * decay + jingle) * amp * (0.8 if kind == "tek" else 0.55)
    return s

def mix_at(canvas, sound, at, gain=1.0):
    i = int(at * SR)
    j = min(len(canvas), i + len(sound))
    if i < 0 or i >= len(canvas): return
    canvas[i:j] += sound[:j - i] * gain

# ---------- ساخت موسیقی هر شهر ----------
def compose_music(name, scale_name, lead, tempo, pattern="6/8", seed=1, dur=34.0, daf_gain=0.5):
    rng = random.Random(seed)
    np.random.seed(seed)
    sc = SCALES[scale_name]
    beat = 60.0 / tempo  # طول نت پنجم (تاخیر الگو)
    n_total = int(dur * SR)
    canvas = np.zeros(n_total)

    # درامبم (نوازچه‌های پیوسته نت پایه و پنجم)
    drone_len = 6.0
    for start in np.arange(0, dur, drone_len - 0.4):
        for f, g in ((D4 / 2, 0.16), (D4 * 3 / 4, 0.09)):
            s = pluck(f, drone_len, amp=g, bright=0.25, damp=0.9985, detune=0.0008,
                      seed=int(start * 13 + f))
            mix_at(canvas, s, start, 1.0)

    # نقش دف
    step = beat / 2 if pattern == "6/8" else beat
    if pattern == "6/8":
        seq = [("dum", 0), ("tek", 2), ("dum", 4), ("dum", 6), ("tek", 8), ("tek", 9), ("dum", 10)]
        bar = 12  # ۱۲ نیم‌ضرب = ۶/۸
    else:
        seq = [("dum", 0), ("tek", 2), ("tek", 4), ("dum", 6), ("tek", 8)]
        bar = 10
    t = 0.0; bi = 0
    while t < dur:
        for kind, pos in seq:
            at = t + pos * step
            if at < dur - 0.3:
                mix_at(canvas, daf_hit(kind, seed=bi), at,
                       daf_gain * (1.0 if kind == "dum" else 0.6))
        t += bar * step; bi += 1

    # ملودی اصلی (راهروی تصادفی روی گام)
    degree = 0
    t = 2.2  # شروع بعد از مقدمه درامبم
    prev_notes = []
    while t < dur - 2.5:
        phrase_len = rng.choice([6, 8, 8, 10])
        for k in range(phrase_len):
            if t >= dur - 2.0: break
            # حرکت گام‌به‌گام با پرش‌های گاه‌به‌گاه
            mv = rng.choices([-2, -1, 1, 2, 3, -3], weights=[2, 4, 4, 2, 1, 1])[0]
            degree = max(-3, min(9, degree + mv))
            # پایان جمله روی درجه‌های آرام
            if k == phrase_len - 1:
                degree = rng.choice([0, 0, 2])
            dur_n = rng.choice([0.5, 1, 1, 1.5, 2]) * beat
            hz = deg2hz(sc, degree)
            if lead == "santur":
                s = pluck(hz, min(dur_n * 3, 2.2), amp=0.30, bright=0.65, damp=0.9965, seed=degree + 5)
            elif lead == "setar":
                s = pluck(hz, min(dur_n * 3, 1.8), amp=0.28, bright=0.42, damp=0.994, seed=degree + 9)
            elif lead == "kamancheh":
                s = kamancheh(hz, max(dur_n * 1.15, 0.35), amp=0.26, seed=degree)
            else:  # ney
                s = ney(hz, max(dur_n * 1.6, 0.5), amp=0.26, seed=degree + 3)
            mix_at(canvas, s, t)
            prev_notes.append((t, hz, dur_n))
            t += dur_n
        # مکث کوچک بین جمله‌ها
        t += rng.choice([0, 0.5, 1]) * beat

    # پاسخ نی (برای شیراز/مشهد) — اکوی آرام یک اکتاو بالا
    if lead in ("setar", "ney"):
        for (tn, hz, dn) in prev_notes[::4]:
            if tn + dn < dur - 1:
                mix_at(canvas, ney(hz * 2, dn * 1.5, amp=0.07, seed=int(tn * 7)), tn + dn * 0.6)

    # نرمال‌سازی و فید حلقه
    canvas = canvas / (np.max(np.abs(canvas)) + 1e-9) * 0.86
    fade = int(0.35 * SR)
    canvas[:fade] *= np.linspace(0, 1, fade)
    canvas[-fade:] *= np.linspace(1, 0, fade)
    wav_path = os.path.join(MUS, name + ".wav")
    ogg_path = os.path.join(MUS, name + ".ogg")
    write_wav(wav_path, canvas)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path, "-c:a", "libvorbis", "-q:a", "4", ogg_path], check=True)
    os.remove(wav_path)
    print("موسیقی:", name + ".ogg")

def write_wav(path, data, sr=SR):
    d16 = (np.clip(data, -1, 1) * 32767).astype(np.int16)
    with wave.open(path, "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr)
        w.writeframes(d16.tobytes())

# ---------- افکت‌ها ----------
def sfx_click():
    return pluck(880, 0.16, amp=0.5, bright=0.7, seed=3)

def sfx_pop():
    n = int(0.09 * SR); t = np.arange(n) / SR
    f = 500 * np.exp(t * 14)
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 55)
    return s * 0.6

def sfx_word(scale="mahur"):
    canvas = np.zeros(int(0.9 * SR))
    for i, d in enumerate([0, 2, 4]):
        mix_at(canvas, pluck(deg2hz(SCALES[scale], d, 1), 0.5, amp=0.4, bright=0.7, seed=i + 11), i * 0.07)
    return canvas

def sfx_bonus():
    canvas = np.zeros(int(1.1 * SR))
    for i, d in enumerate([4, 6, 8, 10]):
        mix_at(canvas, pluck(deg2hz(SCALES["mahur"], d % 7, 1 + d // 7), 0.55, amp=0.34, bright=0.8, seed=i + 21), i * 0.085)
    n = int(1.0 * SR)
    shim = np.random.default_rng(7).uniform(-1, 1, n)
    shim = np.convolve(shim, np.hanning(5) / np.hanning(5).sum(), mode="same") * np.exp(-np.linspace(0, 7, n)) * 0.05
    canvas[:n] += shim
    return canvas

def sfx_error():
    n = int(0.32 * SR); t = np.arange(n) / SR
    f = 190 * np.exp(-t * 2.2)
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 13)
    s += np.sin(2 * np.pi * f * 0.503 * t * SR / SR) * 0.4 * np.exp(-t * 16)
    return s * 0.55

def sfx_coin():
    canvas = np.zeros(int(0.5 * SR))
    for i, f in enumerate([1318, 1760]):
        n = int(0.35 * SR); t = np.arange(n) / SR
        s = (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * f * 2.01 * t)) * np.exp(-t * 11)
        mix_at(canvas, s, i * 0.07, 0.4)
    return canvas

def sfx_star():
    n = int(0.7 * SR); t = np.arange(n) / SR
    f = 1568
    s = (np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * f * 1.5 * t) + 0.2 * np.sin(2 * np.pi * f * 2 * t)) * np.exp(-t * 7)
    return s * 0.42

def sfx_win(scale="mahur"):
    canvas = np.zeros(int(2.2 * SR))
    seq = [(0, 1.0), (2, 0.9), (4, 0.95), (7, 1.4)]
    for i, (d, dn) in enumerate(seq):
        mix_at(canvas, pluck(deg2hz(SCALES[scale], d % 7, 1 + d // 7), 1.2, amp=0.36, bright=0.7, seed=i + 31), i * 0.14)
    mix_at(canvas, daf_hit("dum", 0.7, seed=9), 0.0)
    mix_at(canvas, daf_hit("tek", 0.5, seed=10), 0.42)
    mix_at(canvas, daf_hit("tek", 0.5, seed=11), 0.56)
    n = int(1.6 * SR); t = np.arange(n) / SR
    shimmer = np.random.default_rng(5).uniform(-1, 1, n)
    shimmer = np.convolve(shimmer, np.hanning(6) / np.hanning(6).sum(), mode="same")
    shimmer *= np.exp(-np.linspace(0, 5.5, n)) * 0.06
    canvas[:n] += shimmer
    return canvas

def sfx_lose():
    canvas = np.zeros(int(1.6 * SR))
    for i, d in enumerate([2, 1.5, 0]):
        mix_at(canvas, pluck(deg2hz(SCALES["dashti"], int(d) if d == int(d) else 1, 0), 0.8, amp=0.32, bright=0.4, seed=i + 41), i * 0.22, 0.8)
    return canvas

def sfx_chest():
    n = int(0.9 * SR); t = np.arange(n) / SR
    creak = np.sin(2 * np.pi * (80 + 40 * np.sin(2 * np.pi * 3 * t)) * t) * 0.2 * np.minimum(t * 8, 1)
    canvas = np.zeros(int(1.3 * SR))
    canvas[:n] += creak
    for i, d in enumerate([0, 2, 4]):
        mix_at(canvas, pluck(deg2hz(SCALES["mahur"], d, 1), 0.8, amp=0.3, bright=0.6, seed=i + 51), 0.45 + i * 0.05)
    return canvas

def sfx_whoosh():
    n = int(0.4 * SR)
    noise = np.random.default_rng(3).uniform(-1, 1, n)
    t = np.linspace(0, 1, n)
    sweep = noise * np.sin(np.pi * t) ** 1.5
    sweep = np.convolve(sweep, np.hanning(31) / np.hanning(31).sum(), mode="same")
    return sweep * 0.5

def sfx_tick():
    return daf_hit("tek", 0.45, seed=77)

def sfx_medal():
    canvas = np.zeros(int(1.1 * SR))
    for i, d in enumerate([0, 4]):
        mix_at(canvas, pluck(deg2hz(SCALES["mahur"], d, 1), 0.7, amp=0.36, bright=0.75, seed=i + 61), i * 0.12)
    mix_at(canvas, daf_hit("tek", 0.5, seed=62), 0.24)
    return canvas

def sfx_hint():
    canvas = np.zeros(int(0.8 * SR))
    for i, f in enumerate([988, 1175]):
        n = int(0.5 * SR); t = np.arange(n) / SR
        s = np.sin(2 * np.pi * f * t) * np.exp(-t * 8) * 0.3
        mix_at(canvas, s, i * 0.1)
    return canvas

def sfx_streak():
    canvas = np.zeros(int(0.8 * SR))
    for i, d in enumerate([0, 2, 4]):
        mix_at(canvas, pluck(deg2hz(SCALES["mahur"], d, 1), 0.4, amp=0.32, bright=0.8, seed=i + 71), i * 0.08)
    return canvas

def save_sfx(name, data):
    wav = os.path.join(SFX, name + ".wav")
    write_wav(wav, np.asarray(data) / (np.max(np.abs(data)) + 1e-9) * 0.85)
    print("افکت:", name + ".wav")

if __name__ == "__main__":
    # موسیقی شهرها + منو
    compose_music("menu",    "shur",       "santur",    92, "6/8", seed=101)
    compose_music("shiraz",  "homayun",    "setar",     76, "6/8", seed=102, daf_gain=0.35)
    compose_music("esfahan", "esfahan",    "santur",   100, "6/8", seed=103)
    compose_music("yazd",    "dashti",     "santur",    88, "2/4", seed=104)
    compose_music("tabriz",  "bayat_tork", "kamancheh", 108, "6/8", seed=105)
    compose_music("rasht",   "dashti",     "setar",     96, "6/8", seed=106, daf_gain=0.42)
    compose_music("mashhad", "esfahan",    "ney",       72, "2/4", seed=107, daf_gain=0.3)
    compose_music("party",   "mahur",      "santur",   112, "6/8", seed=108)
    # افکت‌ها
    save_sfx("click", sfx_click())
    save_sfx("pop", sfx_pop())
    save_sfx("word", sfx_word())
    save_sfx("bonus", sfx_bonus())
    save_sfx("error", sfx_error())
    save_sfx("coin", sfx_coin())
    save_sfx("star", sfx_star())
    save_sfx("win", sfx_win())
    save_sfx("lose", sfx_lose())
    save_sfx("chest", sfx_chest())
    save_sfx("whoosh", sfx_whoosh())
    save_sfx("tick", sfx_tick())
    save_sfx("medal", sfx_medal())
    save_sfx("hint", sfx_hint())
    save_sfx("streak", sfx_streak())
    print("همه صداها ساخته شد.")
