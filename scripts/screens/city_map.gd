extends Control
## نقشه سفر — گذر از شش شهر ایران، مرحله به مرحله

var hud: Hud

func _ready() -> void:
	Sound.music("menu")
	var bg := ColorRect.new()
	bg.color = UiKit.COL_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	hud = Hud.new()
	hud.setup("نقشه سفر", true, func(): Router.go("menu"))
	hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.offset_left = 24; hud.offset_right = -24; hud.offset_top = 24
	add_child(hud)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 140
	scroll.offset_bottom = -20
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 40)
	scroll.add_child(v)

	var current_level: int = Save.current_level()
	for ci in Data.cities.size():
		var city: Dictionary = Data.cities[ci]
		v.add_child(_city_section(city, ci, current_level))
		if ci < Data.cities.size() - 1:
			var arrow := UiKit.label("⌄", 60, Color(UiKit.COL_TEXT_SOFT, 0.6), "black")
			var ac := CenterContainer.new(); ac.add_child(arrow)
			v.add_child(ac)

func _city_section(city: Dictionary, ci: int, current_level: int) -> Control:
	var unlocked_city: bool = int(city["levels"][0]) <= current_level
	var card := PanelContainer.new()
	var sb := UiKit.pill(UiKit.COL_CREAM, 36, 10)
	card.add_theme_stylebox_override("panel", sb)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 24)
	card.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	margin.add_child(v)

	# سربرگ شهر
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	v.add_child(head)
	var flag := Panel.new()
	flag.custom_minimum_size = Vector2(84, 84)
	flag.size = Vector2(84, 84)
	var fsb := UiKit.pill(Color(city["color"]), 20, 4)
	flag.add_theme_stylebox_override("panel", fsb)
	var flag_lab := UiKit.label(city["name"].substr(0, 1), 44, UiKit.COL_CREAM, "black")
	flag_lab.set_anchors_preset(Control.PRESET_FULL_RECT)
	flag.add_child(flag_lab)
	head.add_child(flag)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.add_theme_constant_override("separation", 2)
	title_col.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(title_col)
	title_col.add_child(UiKit.label("%s  %s" % [city["name"], "قفل است" if not unlocked_city else ""], 46, UiKit.COL_TEXT if unlocked_city else UiKit.COL_DISABLED, "black"))
	title_col.add_child(UiKit.label(city["tagline"], 26, UiKit.COL_TEXT_SOFT))

	var stars_chip := UiKit.chip("%s/%s" % [UiKit.fa_num(_city_stars(ci)), UiKit.fa_num((int(city["levels"][1]) - int(city["levels"][0]) + 1) * 3)], UiKit.icon_path("star"), UiKit.COL_BG_SOFT, 28)
	head.add_child(stars_chip)

	# شبکه مراحل
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	v.add_child(grid)

	for id in range(int(city["levels"][0]), int(city["levels"][1]) + 1):
		grid.add_child(_level_node(id, city, current_level))
	return card

func _city_stars(ci: int) -> int:
	var s := 0
	var city: Dictionary = Data.cities[ci]
	for id in range(int(city["levels"][0]), int(city["levels"][1]) + 1):
		s += Save.level_stars(id)
	return s

func _level_node(id: int, city: Dictionary, current_level: int) -> Control:
	var unlocked: bool = Save.is_level_unlocked(id)
	var stars: int = Save.level_stars(id)
	var is_current := id == current_level

	var b := Button.new()
	b.custom_minimum_size = Vector2(200, 150)
	b.disabled = not unlocked
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var bg_col: Color = Color(city["color"]) if unlocked else UiKit.COL_DISABLED
	var sb := UiKit.pill(bg_col, 24, 8 if unlocked else 0)
	sb.border_color = UiKit.COL_GOLD if is_current else Color(1, 1, 1, 0.3)
	sb.set_border_width_all(5 if is_current else 2)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("disabled", UiKit.pill(UiKit.COL_DISABLED, 24, 0))

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)

	var num := UiKit.label(UiKit.fa_num(id), 52, UiKit.COL_CREAM if unlocked else Color(UiKit.COL_CREAM, 0.7), "black")
	v.add_child(num)

	var star_row := HBoxContainer.new()
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	star_row.add_theme_constant_override("separation", 2)
	star_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(star_row)
	for i in 3:
		var st := UiKit.label("★", 30, UiKit.COL_GOLD if i < stars else Color(1, 1, 1, 0.35), "black")
		star_row.add_child(st)

	if is_current and unlocked:
		UiKit.breathe(b, 1.06, 1.4)

	b.pressed.connect(func():
		Game.start_level(id)
		Router.go("game")
	)
	return b
