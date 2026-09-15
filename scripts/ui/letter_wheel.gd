class_name LetterWheel
extends Control
## چرخ حروف — ورودی کشیدن انگشت، رسم زنجیره انتخاب، چیدمان واکنش‌گرا

signal word_swiped(word: String)
signal letter_tapped(letter: String, pos: Vector2)

var letters: Array = []
var _centers: Array = []      # Vector2
var _selected: Array = []     # اندیس‌های زنجیره
var _dragging := false
var _last_pos := Vector2.INF
var _can_input := true
var _wheel_r := 220.0
var _panel_d := 104.0
var _entered := false

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_relayout)

func setup(ls: Array) -> void:
	letters = ls
	_selected = []
	_can_input = true
	_dragging = false
	_entered = false
	for ch in get_children():
		ch.queue_free()
	for k in letters.size():
		var p := Panel.new()
		p.name = "L%d" % k
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := UiKit.pill(UiKit.COL_ORANGE, 40, 8)
		sb.border_color = Color(1, 1, 1, 0.25)
		sb.set_border_width_all(3)
		p.add_theme_stylebox_override("panel", sb)
		var lab := UiKit.label("", 40, UiKit.COL_CREAM, "black")
		lab.name = "T%d" % k
		lab.set_anchors_preset(Control.PRESET_FULL_RECT)
		p.add_child(lab)
		add_child(p)
	if size.x > 10.0 and size.y > 10.0:
		_relayout()

func _relayout() -> void:
	## بازچینی چرخ بر اساس اندازه فعلی
	if letters.is_empty() or size.x < 10.0 or size.y < 10.0:
		return
	_wheel_r = clampf(minf(size.x * 0.34, size.y * 0.30), 130.0, 300.0)
	_panel_d = clampf(_wheel_r * 0.5, 62.0, 112.0)
	var c := size / 2.0
	_centers.clear()
	var n := letters.size()
	for i in n:
		var ang := -PI / 2.0 + TAU * i / float(n)
		_centers.append(c + Vector2(cos(ang), sin(ang)) * _wheel_r)
	for i in mini(get_child_count(), n):
		var p: Panel = get_child(i)
		p.size = Vector2(_panel_d, _panel_d)
		p.position = _centers[i] - p.size / 2.0
		p.pivot_offset = p.size / 2.0
		var sb: StyleBoxFlat = p.get_theme_stylebox("panel")
		if sb != null:
			sb = sb.duplicate()
			sb.set_corner_radius_all(int(_panel_d / 2.0))
			p.add_theme_stylebox_override("panel", sb)
		var lab: Label = p.get_node("T%d" % i)
		lab.text = letters[i]
		lab.add_theme_font_size_override("font_size", int(_panel_d * 0.5))
		if not _entered:
			_entered = true
			for k in n:
				var pn: Panel = get_child(k)
				pn.scale = Vector2(0.3, 0.3)
				var tw := pn.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_interval(0.05 * k)
				tw.tween_property(pn, "scale", Vector2.ONE, 0.4)
	queue_redraw()

func _gui_input(ev: InputEvent) -> void:
	if not _can_input:
		return
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_dragging = true
			_last_pos = ev.position
			_try_add(ev.position)
		elif _dragging:
			_dragging = false
			_commit()
	elif ev is InputEventMouseMotion and _dragging:
		# نمونه‌برداری مسیر برای رد شدن از روی حرف‌ها
		var from: Vector2 = _last_pos
		var to: Vector2 = ev.position
		var d := from.distance_to(to)
		var steps := maxi(1, int(d / 16.0))
		for s in steps:
			var p: Vector2 = from.lerp(to, float(s + 1) / steps)
			_try_add(p)
		_last_pos = to

func _try_add(pos: Vector2) -> void:
	for i in letters.size():
		if _centers[i].distance_to(pos) <= _panel_d * 0.58:
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
	if get_child_count() <= i:
		return
	var p: Panel = get_child(i)
	var tw := p.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if sel:
		p.z_index = 2
		tw.tween_property(p, "scale", Vector2(1.22, 1.22), 0.12)
	else:
		tw.tween_property(p, "scale", Vector2.ONE, 0.25)
		p.z_index = 0
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
	## لرزش خطا — با مقیاس (امن برای فرزندِ کانتینر)
	var tw := create_tween().set_trans(Tween.TRANS_SINE)
	pivot_offset = size / 2.0
	for off in [0.05, -0.04, 0.03, -0.02, 0.0]:
		tw.tween_property(self, "scale:x", 1.0 + off, 0.05)
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
			var lw := clampf(_panel_d * 0.11, 8.0, 16.0)
			draw_polyline(pts, Color(UiKit.COL_GOLD, 0.85), lw, true)
			for p in pts:
				draw_circle(p, lw * 0.72, Color(UiKit.COL_GOLD, 0.85))
