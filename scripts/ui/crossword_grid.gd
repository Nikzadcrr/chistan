class_name CrosswordGrid
extends Control
## جدول تقاطعی مراحل — نمایش خانه‌ها، انیمیشن کشف کلمه، راهنما

signal word_found_anim_done(word: String)
signal cell_revealed(pos: Vector2)

var layout: Dictionary = {}          # min_r,max_r,min_c,max_c,words
var _cell_nodes := {}                # Vector2i -> Panel
var _found := {}                     # word -> true
var _revealed_cells := {}            # Vector2i -> letter (آشکارشده با راهنما)
var _cell_size := 70.0
var _origin := Vector2.ZERO
var accent: Color = UiKit.COL_ORANGE
var accent2: Color = UiKit.COL_GREEN

func setup(level: Dictionary, ac: Color, ac2: Color) -> void:
	accent = ac
	accent2 = ac2
	layout = level.get("layout", {})
	_found = {}
	_revealed_cells = {}
	for ch in get_children():
		ch.queue_free()
	_cell_nodes.clear()
	if layout.is_empty():
		_build_fallback_rows(level)
		return
	var cols := int(layout["max_c"]) - int(layout["min_c"]) + 1
	var rows := int(layout["max_r"]) - int(layout["min_r"]) + 1
	var avail := size - Vector2(24, 24)
	_cell_size = minf(avail.x / cols, avail.y / rows) * 0.92
	_cell_size = clampf(_cell_size, 44.0, 110.0)
	var grid_w := _cell_size * cols
	var grid_h := _cell_size * rows
	_origin = (size - Vector2(grid_w, grid_h)) / 2.0 - Vector2(int(layout["min_c"]), int(layout["min_r"])) * _cell_size
	# خانه‌ها
	for wd in layout["words"]:
		for cell in wd["cells"]:
			var key := Vector2i(cell[0], cell[1])
			if _cell_nodes.has(key):
				continue
			_cell_nodes[key] = _make_cell(Vector2(cell[1], cell[0]))
	# انیمیشن ورود خانه‌ها
	var delay := 0.0
	for key in _cell_nodes:
		var p: Panel = _cell_nodes[key]
		UiKit.pop_in(p, delay)
		delay += 0.02
	# ثبت اتصال کلمه به خانه‌ها برای بازی
	_words_cells = {}
	for wd in layout["words"]:
		var arr: Array = []
		for cell in wd["cells"]:
			arr.append(Vector2i(cell[0], cell[1]))
		_words_cells[wd["w"]] = arr

var _words_cells := {}

func _make_cell(grid_pos: Vector2) -> Panel:
	var p := Panel.new()
	p.size = Vector2(_cell_size - 7, _cell_size - 7)
	p.position = _origin + grid_pos * _cell_size + Vector2(3.5, 3.5)
	p.pivot_offset = p.size / 2.0
	var sb := UiKit.pill(UiKit.COL_CREAM, 14, 5)
	sb.border_color = Color(UiKit.COL_WOOD, 0.18)
	sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	var lab := UiKit.label("", int(_cell_size * 0.52), UiKit.COL_TEXT, "black")
	lab.name = "T"
	lab.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_child(lab)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)
	return p

func _build_fallback_rows(level: Dictionary) -> void:
	## چیدمان ردیفی (بدون جدول تقاطع): کلمات بر اساس طول
	var words: Array = level.get("targets", []).duplicate()
	words.sort_custom(func(a, b): return a.length() > b.length())
	var cols := 7
	var avail := size - Vector2(24, 24)
	_cell_size = clampf(minf(avail.x / cols, avail.y / maxi(1, words.size())) * 0.92, 44.0, 100.0)
	_words_cells = {}
	var y := 0
	for w in words:
		var x := 0
		var arr: Array = []
		for c in w:
			var key := Vector2i(y, x)
			_cell_nodes[key] = _make_cell(Vector2(x, y))
			arr.append(key)
			x += 1
		_words_cells[w] = arr
		y += 1
	var delay := 0.0
	for key in _cell_nodes:
		UiKit.pop_in(_cell_nodes[key], delay)
		delay += 0.015

func is_found(w: String) -> bool:
	return _found.has(w)

func found_count() -> int:
	return _found.size()

func total_words() -> int:
	return _words_cells.size()

func has_word(w: String) -> bool:
	return _words_cells.has(w)

func reveal_word_letter() -> String:
	## سرنخ: حرف اول یک کلمه کشف‌نشده را آشکار می‌کند؛ کلمه را برمی‌گرداند
	for w in _words_cells:
		if _found.has(w):
			continue
		var cells: Array = _words_cells[w]
		# اولین خانه‌ای که هنوز آشکار نشده
		for key in cells:
			if not _revealed_cells.has(key):
				var idx: int = cells.find(key)
				var letter: String = w[idx]
				_revealed_cells[key] = letter
				var p: Panel = _cell_nodes[key]
				var lab: Label = p.get_node("T")
				lab.text = letter
				lab.add_theme_color_override("font_color", accent)
				var tw := p.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				p.scale = Vector2(1.25, 1.25)
				tw.tween_property(p, "scale", Vector2.ONE, 0.35)
				cell_revealed.emit(p.get_global_rect().get_center())
				return w
	return ""

func reveal_cell_hint() -> String:
	## آشکارساز: یک خانه تصادفی از کلمه‌ای ناکشف
	var options: Array = []
	for w in _words_cells:
		if _found.has(w): continue
		var cells: Array = _words_cells[w]
		for i in cells.size():
			if not _revealed_cells.has(cells[i]):
				options.append([w, i])
	if options.is_empty():
		return ""
	var pick: Array = options[randi() % options.size()]
	var w: String = pick[0]
	var idx: int = pick[1]
	var key: Vector2i = _words_cells[w][idx]
	_revealed_cells[key] = w[idx]
	var p: Panel = _cell_nodes[key]
	var lab: Label = p.get_node("T")
	lab.text = w[idx]
	lab.add_theme_color_override("font_color", accent)
	var tw := p.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	p.scale = Vector2(1.3, 1.3)
	tw.tween_property(p, "scale", Vector2.ONE, 0.4)
	cell_revealed.emit(p.get_global_rect().get_center())
	return w

func try_found(word: String) -> bool:
	## اگر کلمه در جدول است و کشف نشده، انیمیشن کشف را اجرا می‌کند
	if not _words_cells.has(word) or _found.has(word):
		return false
	_found[word] = true
	var cells: Array = _words_cells[word]
	var i := 0
	for key in cells:
		var p: Panel = _cell_nodes[key]
		var lab: Label = p.get_node("T")
		var sb := UiKit.pill(accent, 14, 4)
		sb.border_color = Color(1, 1, 1, 0.5)
		sb.set_border_width_all(3)
		var tw := p.create_tween()
		tw.tween_interval(0.06 * i)
		tw.tween_callback(func():
			lab.text = word[cells.find(key)]
			lab.add_theme_color_override("font_color", UiKit.COL_CREAM)
			p.add_theme_stylebox_override("panel", sb)
			Sound.sfx("pop", 1.1 + 0.07 * i, -8.0)
			var t2 := p.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			p.scale = Vector2(1.35, 1.35)
			t2.tween_property(p, "scale", Vector2.ONE, 0.3)
		)
		i += 1
	var done := get_tree().create_timer(0.06 * cells.size() + 0.35)
	done.timeout.connect(func(): word_found_anim_done.emit(word))
	return true

func all_found() -> bool:
	return _found.size() >= _words_cells.size() and _words_cells.size() > 0
