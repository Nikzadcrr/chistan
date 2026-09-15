class_name CrosswordGrid
extends Control
## جدول تقاطعی مراحل — چیدمان واکنش‌گرا: هر بار اندازه عوض شود، خانه‌ها بازچینی می‌شوند

signal word_found_anim_done(word: String)
signal cell_revealed(pos: Vector2)

var layout: Dictionary = {}          # min_r,max_r,min_c,max_c,words
var _cell_nodes := {}                # Vector2i -> Panel
var _found := {}                     # word -> true
var _revealed_cells := {}            # Vector2i -> letter
var _cell_size := 70.0
var _origin := Vector2.ZERO
var _words_cells := {}
var _accent: Color = UiKit.COL_ORANGE
var _accent2: Color = UiKit.COL_GREEN
var _entered := false                # انیمیشن ورود فقط یک‌بار

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_relayout)

func setup(level: Dictionary, ac: Color, ac2: Color) -> void:
	_accent = ac
	_accent2 = ac2
	layout = level.get("layout", {})
	_found = {}
	_revealed_cells = {}
	_words_cells = {}
	for ch in get_children():
		ch.queue_free()
	_cell_nodes.clear()
	_entered = false
	if layout.is_empty():
		_build_fallback_words(level.get("targets", []))
	else:
		for wd in layout["words"]:
			var arr: Array = []
			for cell in wd["cells"]:
				arr.append(Vector2i(cell[0], cell[1]))
			_words_cells[wd["w"]] = arr
		_build_cells()
	# اگر اندازه همین حالا معلوم است بچین، وگرنه هنگام resized خودکار می‌چینیم
	if size.x > 10.0 and size.y > 10.0:
		_relayout()

func _build_cells() -> void:
	for wd in layout["words"]:
		for cell in wd["cells"]:
			var key := Vector2i(cell[0], cell[1])
			if _cell_nodes.has(key):
				continue
			_cell_nodes[key] = _make_cell()

func _build_fallback_words(words: Array) -> void:
	## چیدمان ردیفی ساده (وقتی جدول تقاطع نداریم) — کلیدها بر پایه ردیف/ستون
	var ws: Array = words.duplicate()
	ws.sort_custom(func(a, b): return a.length() > b.length())
	var y := 0
	for w in ws:
		var arr: Array = []
		for x in w.length():
			var key := Vector2i(y, x)
			_cell_nodes[key] = _make_cell()
			arr.append(key)
		_words_cells[w] = arr
		y += 1

func _make_cell() -> Panel:
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UiKit.pill(UiKit.COL_CREAM, 14, 5)
	sb.border_color = Color(UiKit.COL_WOOD, 0.18)
	sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	var lab := UiKit.label("", 40, UiKit.COL_TEXT, "black")
	lab.name = "T"
	lab.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_child(lab)
	add_child(p)
	return p

func _relayout() -> void:
	## چیدمان کامل بر اساس اندازه فعلی — با هر تغییر اندازه صدا می‌شود
	if _cell_nodes.is_empty() or size.x < 10.0 or size.y < 10.0:
		return
	var cols := 0
	var rows := 0
	var min_c := 0
	var min_r := 0
	if layout.is_empty():
		# حالت ردیفی
		var max_len := 1
		for w in _words_cells:
			max_len = maxi(max_len, w.length())
		cols = max_len
		rows = _words_cells.size()
		min_c = 0
		min_r = 0
	else:
		cols = int(layout["max_c"]) - int(layout["min_c"]) + 1
		rows = int(layout["max_r"]) - int(layout["min_r"]) + 1
		min_c = int(layout["min_c"])
		min_r = int(layout["min_r"])
	cols = maxi(cols, 1)
	rows = maxi(rows, 1)
	_cell_size = minf((size.x - 28.0) / cols, (size.y - 28.0) / rows) * 0.96
	_cell_size = clampf(_cell_size, 40.0, 118.0)
	var grid_w := _cell_size * cols
	var grid_h := _cell_size * rows
	_origin = Vector2((size.x - grid_w) / 2.0, (size.y - grid_h) / 2.0) - Vector2(min_c, min_r) * _cell_size
	for key in _cell_nodes:
		var p: Panel = _cell_nodes[key]
		p.size = Vector2(_cell_size - 6, _cell_size - 6)
		p.position = _origin + Vector2(key.y, key.x) * _cell_size + Vector2(3, 3)
		p.pivot_offset = p.size / 2.0
		var lab: Label = p.get_node("T")
		lab.add_theme_font_size_override("font_size", int(_cell_size * 0.5))
	# انیمیشن ورود — فقط بار اول که واقعاً جای کافی داریم
	if not _entered:
		_entered = true
		var delay := 0.0
		for key in _cell_nodes:
			UiKit.pop_in(_cell_nodes[key], delay)
			delay += 0.02
	queue_redraw()

func is_found(w: String) -> bool:
	return _found.has(w)

func found_count() -> int:
	return _found.size()

func total_words() -> int:
	return _words_cells.size()

func has_word(w: String) -> bool:
	return _words_cells.has(w)

func _reveal_cell(key: Vector2i, letter: String, word: String) -> void:
	_revealed_cells[key] = letter
	if not _cell_nodes.has(key):
		return
	var p: Panel = _cell_nodes[key]
	var lab: Label = p.get_node("T")
	lab.text = letter
	lab.add_theme_color_override("font_color", _accent)
	var tw := p.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	p.scale = Vector2(1.3, 1.3)
	tw.tween_property(p, "scale", Vector2.ONE, 0.38)
	cell_revealed.emit(p.get_global_rect().get_center())

func reveal_word_letter() -> String:
	## سرنخ: حرف اول یک کلمه کشف‌نشده را آشکار می‌کند
	for w in _words_cells:
		if _found.has(w):
			continue
		var cells: Array = _words_cells[w]
		for idx in cells.size():
			if not _revealed_cells.has(cells[idx]):
				_reveal_cell(cells[idx], w[idx], w)
				return w
	return ""

func reveal_cell_hint() -> String:
	## آشکارساز: یک خانه تصادفی از کلمه‌ای ناکشف
	var options: Array = []
	for w in _words_cells:
		if _found.has(w):
			continue
		var cells: Array = _words_cells[w]
		for i in cells.size():
			if not _revealed_cells.has(cells[i]):
				options.append([w, cells[i]])
	if options.is_empty():
		return ""
	var pick: Array = options[randi() % options.size()]
	_reveal_cell(pick[1], pick[0][0], pick[0])
	return pick[0]

func try_found(word: String) -> bool:
	## اگر کلمه در جدول است و کشف نشده، انیمیشن کشف را اجرا می‌کند
	if not _words_cells.has(word) or _found.has(word):
		return false
	_found[word] = true
	var cells: Array = _words_cells[word]
	var i := 0
	for key in cells:
		if not _cell_nodes.has(key):
			i += 1
			continue
		var p: Panel = _cell_nodes[key]
		var lab: Label = p.get_node("T")
		var idx := i
		var tw := p.create_tween()
		tw.tween_interval(0.06 * i)
		tw.tween_callback(func():
			if not is_instance_valid(p):
				return
			lab.text = word[idx]
			lab.add_theme_color_override("font_color", UiKit.COL_CREAM)
			var sb := UiKit.pill(_accent, 14, 4)
			sb.border_color = Color(1, 1, 1, 0.5)
			sb.set_border_width_all(3)
			p.add_theme_stylebox_override("panel", sb)
			Sound.sfx("pop", 1.1 + 0.07 * idx, -8.0)
			var t2 := p.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			p.scale = Vector2(1.35, 1.35)
			t2.tween_property(p, "scale", Vector2.ONE, 0.3)
		)
		i += 1
	var done := get_tree().create_timer(0.06 * cells.size() + 0.35)
	done.timeout.connect(func(): word_found_anim_done.emit(word))
	return true

func all_found() -> bool:
	return _words_cells.size() > 0 and _found.size() >= _words_cells.size()
