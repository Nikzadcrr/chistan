class_name UiKit
## کیت طراحی چیستان — فونت‌ها، رنگ‌ها، استایل‌ها و ابزارهای مشترک

const COL_BG := Color("fbf3e4")          # کرم پس‌زمینه
const COL_BG_SOFT := Color("f6ead2")     # کرم تیره‌تر
const COL_TEXT := Color("3b2a1e")        # قهوه‌ای متن (به‌جای مشکی)
const COL_TEXT_SOFT := Color("7a6650")
const COL_ORANGE := Color("e8862e")      # نارنجی اصلی
const COL_ORANGE_DARK := Color("c96a18")
const COL_GOLD := Color("f2b33d")
const COL_GREEN := Color("4e9a51")
const COL_TURQ := Color("2fa8a0")
const COL_RED := Color("d95a4e")
const COL_WOOD := Color("8c5a38")
const COL_CREAM := Color("fffaf0")
const COL_SHADOW := Color(0.35, 0.22, 0.10, 0.28)
const COL_DISABLED := Color("c9bda8")

const FONTS := {
        "regular": "res://assets/fonts/Vazirmatn-Regular.ttf",
        "medium": "res://assets/fonts/Vazirmatn-Medium.ttf",
        "semibold": "res://assets/fonts/Vazirmatn-SemiBold.ttf",
        "bold": "res://assets/fonts/Vazirmatn-Bold.ttf",
        "black": "res://assets/fonts/Vazirmatn-Black.ttf",
}

static var _font_cache: Dictionary = {}
static var _theme: Theme = null

static func font(weight: String = "regular") -> FontFile:
        if not _font_cache.has(weight):
                _font_cache[weight] = load(FONTS.get(weight, FONTS.regular))
        return _font_cache[weight]

static func fa_num(value) -> String:
        ## تبدیل عدد به رقم فارسی
        var s := str(value)
        var fa := ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"]
        var out := ""
        for c in s:
                out += fa[int(c)] if c >= "0" and c <= "9" else c
        return out

static func money(value: int) -> String:
        return fa_num(value)

# ---------- استایل‌باکس‌ها ----------
static func pill(bg: Color, radius: int = 32, shadow: int = 0, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> StyleBoxFlat:
        var sb := StyleBoxFlat.new()
        sb.bg_color = bg
        sb.set_corner_radius_all(radius)
        if shadow > 0:
                sb.shadow_color = COL_SHADOW
                sb.shadow_size = shadow
                sb.shadow_offset = Vector2(0, shadow * 0.6)
        if border_w > 0:
                sb.set_border_width_all(border_w)
                sb.border_color = border
        sb.set_content_margin_all(0)
        return sb

static func padded(sb: StyleBoxFlat, v: int, h: int = -1) -> StyleBoxFlat:
        if h < 0: h = v
        sb.content_margin_top = v
        sb.content_margin_bottom = v
        sb.content_margin_left = h
        sb.content_margin_right = h
        return sb

# ---------- تم سراسری ----------
static func theme() -> Theme:
        if _theme != null:
                return _theme
        var t := Theme.new()
        var f := font("medium")
        t.default_font = f
        t.default_font_size = 40
        # Label پیش‌فرض
        t.set_color("font_color", "Label", COL_TEXT)
        # Button پایه
        t.set_font("font", "Button", font("semibold"))
        t.set_font_size("font_size", "Button", 44)
        t.set_color("font_color", "Button", COL_CREAM)
        t.set_color("font_hover_color", "Button", COL_CREAM)
        t.set_color("font_pressed_color", "Button", Color(1, 1, 1, 0.9))
        t.set_color("font_disabled_color", "Button", COL_DISABLED)
        t.set_stylebox("normal", "Button", pill(COL_ORANGE, 40, 8))
        t.set_stylebox("hover", "Button", pill(COL_ORANGE, 40, 10))
        t.set_stylebox("pressed", "Button", pill(COL_ORANGE_DARK, 40, 2))
        t.set_stylebox("disabled", "Button", pill(COL_DISABLED, 40, 0))
        t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
        _theme = t
        return t

# ---------- ویجت‌ها ----------
static func label(text: String, size: int = 40, color: Color = COL_TEXT, weight: String = "medium") -> Label:
        var l := Label.new()
        l.text = text
        l.add_theme_font_override("font", font(weight))
        l.add_theme_font_size_override("font_size", size)
        l.add_theme_color_override("font_color", color)
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        return l

static func title_label(text: String, size: int = 64) -> Label:
        return label(text, size, COL_TEXT, "black")

static func button(text: String, bg: Color = COL_ORANGE, font_size: int = 44, text_color: Color = COL_CREAM) -> Button:
        ## دکمه گرد با سایه نرم و انیمیشن فشار
        var b := Button.new()
        b.text = text
        b.add_theme_font_override("font", font("semibold"))
        b.add_theme_font_size_override("font_size", font_size)
        b.add_theme_color_override("font_color", text_color)
        b.add_theme_color_override("font_pressed_color", text_color)
        b.add_theme_color_override("font_hover_color", text_color)
        b.add_theme_color_override("font_focus_color", text_color)
        var sb_n := pill(bg, 44, 10)
        padded(sb_n, 22, 46)
        var sb_p := pill(bg.darkened(0.16), 44, 3)
        padded(sb_p, 20, 46)
        b.add_theme_stylebox_override("normal", sb_n)
        b.add_theme_stylebox_override("hover", pill(bg.lightened(0.06), 44, 12))
        b.add_theme_stylebox_override("pressed", sb_p)
        b.add_theme_stylebox_override("disabled", pill(COL_DISABLED, 44, 0))
        b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
        b.clip_contents = false
        _animate_press(b)
        return b

static func _animate_press(b: Button) -> void:
        b.pivot_offset = b.size / 2.0
        b.resized.connect(func():
                b.pivot_offset = b.size / 2.0
        )
        b.mouse_entered.connect(func():
                if b.disabled: return
                var tw := b.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                tw.tween_property(b, "scale", Vector2(1.04, 1.04), 0.12)
        )
        b.mouse_exited.connect(func():
                var tw := b.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
                tw.tween_property(b, "scale", Vector2.ONE, 0.12)
        )
        b.pressed.connect(func():
                if b.disabled: return
                Sound.sfx("click")
                var tw := b.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                tw.tween_property(b, "scale", Vector2(0.92, 0.92), 0.07)
                tw.tween_property(b, "scale", Vector2.ONE, 0.22)
        )

static func icon_rect(path: String, size: Vector2, cover := false) -> TextureRect:
        var tr := TextureRect.new()
        tr.texture = load(path)
        tr.custom_minimum_size = size
        tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
        return tr

static func chip(text: String, icon_path: String = "", bg: Color = COL_CREAM, text_size: int = 36) -> PanelContainer:
        ## کپسول اطلاعات (سکه/ستاره/...)
        var pc := PanelContainer.new()
        pc.add_theme_stylebox_override("panel", padded(pill(bg, 36, 6), 10, 20))
        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 10)
        h.mouse_filter = Control.MOUSE_FILTER_IGNORE
        if icon_path != "":
                var ic := icon_rect(icon_path, Vector2(36, 36))
                h.add_child(ic)
        var l := label(text, text_size, COL_TEXT, "bold")
        h.add_child(l)
        pc.add_child(h)
        pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        return pc

static func icon_path(name: String) -> String:
        return "res://assets/art/ic_%s.webp" % name

static func haptic(ms: int = 25) -> void:
        if Save.data.get("settings", {}).get("haptics", true):
                Input.vibrate_handheld(ms)

static func stagger_in(items: Array, base_delay: float = 0.06, offset := Vector2(0, 60)) -> void:
        ## ورود پلکانی ویجت‌ها — با مقیاس (برای فرزندان کانتینر هم امن است)
        for i in items.size():
                var c: Control = items[i]
                c.modulate.a = 0.0
                c.scale = Vector2(0.86, 0.86)
                var tw := c.create_tween().set_parallel(true)
                tw.tween_interval(base_delay * i)
                tw.tween_property(c, "modulate:a", 1.0, 0.35).set_delay(base_delay * i)
                tw.tween_property(c, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(base_delay * i)

static func overlay(parent: Control, veil_alpha: float = 0.35, z := 40) -> Dictionary:
        ## لایه مودال تمام‌صفحه: پرده + کانتینر مرکز — بدون هیچ محاسبه دستی
        var layer := Control.new()
        layer.set_anchors_preset(Control.PRESET_FULL_RECT)
        layer.z_index = z
        parent.add_child(layer)
        var veil := ColorRect.new()
        veil.color = Color(0.12, 0.06, 0.0, veil_alpha)
        veil.set_anchors_preset(Control.PRESET_FULL_RECT)
        layer.add_child(veil)
        var center := CenterContainer.new()
        center.set_anchors_preset(Control.PRESET_FULL_RECT)
        layer.add_child(center)
        return {"layer": layer, "center": center, "veil": veil}

static func close_overlay(ov: Dictionary, dur: float = 0.3) -> void:
        ## محو و حذف لایه مودال
        var layer: Control = ov["layer"]
        var tw := layer.create_tween()
        tw.tween_property(layer, "modulate:a", 0.0, dur)
        tw.tween_callback(layer.queue_free)

static func pop_in(c: Control, delay: float = 0.0) -> void:
        c.pivot_offset = c.size / 2.0
        c.resized.connect(func(): c.pivot_offset = c.size / 2.0)
        c.scale = Vector2(0.6, 0.6)
        c.modulate.a = 0.0
        var tw := c.create_tween().set_parallel(true)
        tw.tween_interval(delay)
        tw.tween_property(c, "modulate:a", 1.0, 0.25).set_delay(delay)
        tw.tween_property(c, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)

static func breathe(c: Control, amount: float = 1.035, dur: float = 2.2) -> void:
        c.pivot_offset = c.size / 2.0
        var tw := c.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        tw.tween_property(c, "scale", Vector2(amount, amount), dur)
        tw.tween_property(c, "scale", Vector2.ONE, dur)
