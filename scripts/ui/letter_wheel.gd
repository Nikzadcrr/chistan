class_name LetterWheel
extends Control
## چرخ حروف — ورودی کشیدن انگشت، رسم زنجیره انتخاب، انیمیشن‌ها

signal word_swiped(word: String)
signal letter_tapped(letter: String, pos: Vector2)

const LETTER_R := 52.0        # شعاع دکمه حرف
var letters: Array = []
var _centers: Array = []      # Vector2
var _selected: Array = []     # اندیس‌های زنجیره
var _dragging := false
var _last_pos := Vector2.INF
var _can_input := true
var _wheel_r := 220.0

func setup(ls: Array) -> void:
        letters = ls
        _selected = []
        _can_input = true
        _layout_wheel()
        queue_redraw()

func _layout_wheel() -> void:
        var n := letters.size()
        if n == 0: return
        _wheel_r = minf(size.x, size.y) * 0.36
        _wheel_r = maxf(_wheel_r, 150.0)
        _centers.clear()
        var c := size / 2.0
        for i in n:
                var ang := -PI / 2.0 + TAU * i / float(n)
                # لرزش طبیعی ظاهری جزئی برای ریتم بصری
                var jitter := 0.0
                _centers.append(c + Vector2(cos(ang), sin(ang)) * (_wheel_r + jitter))
        for i in n:
                _make_letter_node(i)

func _make_letter_node(i: int) -> void:
        # حرف‌ها به‌صورت پنل‌های گرد ساخته می‌شوند (یک‌بار)
        if get_child_count() != letters.size():
                for ch in get_children():
                        ch.queue_free()
                for k in letters.size():
                        var p := Panel.new()
                        p.name = "L%d" % k
                        add_child(p)
                        var lab := UiKit.label("", int(LETTER_R * 0.95), UiKit.COL_CREAM, "black")
                        lab.name = "T%d" % k
                        lab.set_anchors_preset(Control.PRESET_FULL_RECT)
                        p.add_child(lab)
        var c := size / 2.0
        for k in minf(get_child_count(), letters.size()):
                var p: Panel = get_child(k)
                p.size = Vector2(LETTER_R, LETTER_R) * 2.0
                p.position = _centers[k] - p.size / 2.0
                p.pivot_offset = p.size / 2.0
                var sb := UiKit.pill(UiKit.COL_ORANGE, int(LETTER_R), 8)
                sb.border_color = Color(1, 1, 1, 0.25)
                sb.set_border_width_all(3)
                p.add_theme_stylebox_override("panel", sb)
                var lab: Label = p.get_node("T%d" % k)
                lab.text = letters[k]
                lab.add_theme_font_size_override("font_size", int(LETTER_R * 0.95))
        # چرخش ورود حرف‌ها
        for k in get_child_count():
                var p: Panel = get_child(k)
                p.scale = Vector2(0.3, 0.3)
                var tw := p.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
                tw.tween_interval(0.05 * k)
                tw.tween_property(p, "scale", Vector2.ONE, 0.4)

func _gui_input(ev: InputEvent) -> void:
        if not _can_input: return
        if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
                if ev.pressed:
                        _dragging = true
                        _last_pos = ev.position
                        _try_add(ev.position)
                elif _dragging:
                        _dragging = false
                        _commit()
        elif ev is InputEventMouseMotion and _dragging:
                _last_pos = ev.position
                # نمونه‌برداری مسیر برای رد شدن از روی حرف‌ها
                var from := _last_pos
                var to: Vector2 = ev.position
                var d := from.distance_to(to)
                var steps := maxi(1, int(d / 18.0))
                for s in steps:
                        var p: Vector2 = from.lerp(to, float(s + 1) / steps)
                        _try_add(p)
                _last_pos = to

func _try_add(pos: Vector2) -> void:
        for i in letters.size():
                if _centers[i].distance_to(pos) <= LETTER_R * 1.15:
                        if not _selected.has(i):
                                _selected.append(i)
                                Sound.sfx("pop", 1.0 + 0.05 * _selected.size(), -6.0)
                                _bounce_letter(i, true)
                                UiKit.haptic(12)
                                queue_redraw()
                        return

func _commit() -> void:
        var w := ""
        for i in _selected:
                w += letters[i]
        var had := _selected.size() > 0
        _selected = []
        queue_redraw()
        if had and w.length() >= 2:
                word_swiped.emit(w)

func current_word() -> String:
        var w := ""
        for i in _selected:
                w += letters[i]
        return w

func _bounce_letter(i: int, sel: bool) -> void:
        if get_child_count() <= i: return
        var p: Panel = get_child(i)
        var tw := p.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        if sel:
                p.z_index = 2
                tw.tween_property(p, "scale", Vector2(1.22, 1.22), 0.12)
        else:
                tw.tween_property(p, "scale", Vector2.ONE, 0.25)
                p.z_index = 0
        # رنگ انتخاب
        var sb: StyleBoxFlat = p.get_theme_stylebox("panel").duplicate()
        sb.bg_color = UiKit.COL_GOLD if sel else UiKit.COL_ORANGE
        p.add_theme_stylebox_override("panel", sb)

func set_locked(locked: bool) -> void:
        _can_input = not locked
        if locked:
                _dragging = false
                for i in _selected:
                        _bounce_letter(i, false)
                _selected = []
                queue_redraw()

func shake() -> void:
        ## لرزش خطا
        var base := position
        var tw := create_tween().set_trans(Tween.TRANS_SINE)
        for off in [14, -12, 9, -6, 0]:
                tw.tween_property(self, "position:x", base.x + off, 0.05)
        Sound.sfx("error")

func pulse_selected() -> void:
        for i in _selected:
                _bounce_letter(i, false)

func _draw() -> void:
        # خط زنجیره انتخاب
        if _selected.size() > 0:
                var pts := PackedVector2Array()
                for i in _selected:
                        pts.append(_centers[i])
                if _dragging and _last_pos != Vector2.INF:
                        pts.append(_last_pos)
                if pts.size() >= 1:
                        draw_polyline(pts, Color(UiKit.COL_GOLD, 0.85), 12.0, true)
                        for p in pts:
                                draw_circle(p, 9.0, Color(UiKit.COL_GOLD, 0.85))
