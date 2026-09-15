extends Control
## حالت جمعی — ساخت اتاق روی یک گوشی

var _players: Array = []
var _rounds := 3

func _ready() -> void:
	Sound.music("menu")
	var bg := ColorRect.new()
	bg.color = UiKit.COL_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var deco := TextureRect.new()
	deco.texture = load("res://assets/art/menu_bg.png")
	deco.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	deco.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	deco.set_anchors_preset(Control.PRESET_FULL_RECT)
	deco.modulate.a = 0.18
	add_child(deco)

	var hud := Hud.new()
	hud.setup("حالت جمعی", true, func(): Router.go("menu"))
	hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.offset_left = 24; hud.offset_right = -24; hud.offset_top = 24
	add_child(hud)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 160
	scroll.offset_bottom = -20
	scroll.offset_left = 40
	scroll.offset_right = -40
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 20)
	scroll.add_child(v)

	v.add_child(UiKit.label("همین حال روی یک گوشی بازی کنید!", 38, UiKit.COL_TEXT, "bold"))
	v.add_child(UiKit.label("نام بازیکن‌ها را بنویسید (۲ تا ۸ نفر)", 30, UiKit.COL_TEXT_SOFT))

	var list := VBoxContainer.new()
	list.name = "PlayerList"
	list.add_theme_constant_override("separation", 12)
	v.add_child(list)
	_players = [{"name": "", "color": 0}, {"name": "", "color": 1}]
	add_player_row(list, 0)
	add_player_row(list, 1)

	# انتخاب دورها
	var rounds_row := HBoxContainer.new()
	rounds_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rounds_row.add_theme_constant_override("separation", 14)
	v.add_child(rounds_row)
	rounds_row.add_child(UiKit.label("تعداد دور:", 34, UiKit.COL_TEXT, "bold"))
	var round_group := HBoxContainer.new()
	round_group.add_theme_constant_override("separation", 10)
	rounds_row.add_child(round_group)
	for r in [3, 5, 7]:
		var rb := UiKit.button(UiKit.fa_num(r), UiKit.COL_TURQ if r == 3 else UiKit.COL_BG_SOFT, 34, UiKit.COL_CREAM if r == 3 else UiKit.COL_TEXT)
		rb.custom_minimum_size = Vector2(110, 76)
		round_group.add_child(rb)
		rb.pressed.connect(func():
			_rounds = r
			Sound.sfx("click")
			for i in round_group.get_child_count():
				var bb: Button = round_group.get_child(i)
				var sel: bool = [3, 5, 7][i] == r
				bb.add_theme_stylebox_override("normal", UiKit.pill(UiKit.COL_TURQ if sel else UiKit.COL_BG_SOFT, 44, 8 if sel else 0))
				bb.add_theme_color_override("font_color", UiKit.COL_CREAM if sel else UiKit.COL_TEXT)
		)

	var start := UiKit.button("شروع بازی جمعی", UiKit.COL_GREEN, 48)
	start.custom_minimum_size = Vector2(520, 110)
	var sc := CenterContainer.new(); sc.add_child(start)
	v.add_child(sc)
	start.pressed.connect(func():
		if _players.size() < 2:
			Toast.show_msg(self, "حداقل دو بازیکن لازم است!", UiKit.COL_RED)
			Sound.sfx("error")
			return
		Game.start_group({"players": _collect_names(), "rounds": _rounds, "is_league": false})
		Router.go("party_game")
	)

	var info := UiKit.label("هر نفر ۳۰ ثانیه وقت دارد؛ هر کلمه = امتیاز حرف‌هایش", 28, UiKit.COL_TEXT_SOFT)
	v.add_child(info)
	UiKit.stagger_in([list, rounds_row, sc, info], 0.08)

func add_player_row(list: VBoxContainer, idx: int) -> void:
	var row := HBoxContainer.new()
	row.name = "Row%d" % idx
	row.add_theme_constant_override("separation", 12)
	list.add_child(row)

	var avatar := Panel.new()
	avatar.custom_minimum_size = Vector2(76, 76)
	avatar.size = Vector2(76, 76)
	avatar.add_theme_stylebox_override("panel", UiKit.pill(Color(Game.AVATAR_COLORS[_players[idx]["color"]]), 38, 4))
	row.add_child(avatar)

	var edit := LineEdit.new()
	edit.placeholder_text = "نام بازیکن %s" % UiKit.fa_num(idx + 1)
	edit.max_length = 12
	edit.add_theme_font_override("font", UiKit.font("semibold"))
	edit.add_theme_font_size_override("font_size", 36)
	edit.custom_minimum_size = Vector2(0, 84)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.add_theme_stylebox_override("normal", UiKit.padded(UiKit.pill(UiKit.COL_CREAM, 24, 4), 12, 20))
	edit.add_theme_stylebox_override("focus", UiKit.padded(UiKit.pill(UiKit.COL_CREAM, 24, 4, UiKit.COL_TURQ, 3), 12, 20))
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(edit)
	edit.text_changed.connect(func(t: String): _players[idx]["name"] = t)

	var color_btn := UiKit.button("رنگ", UiKit.COL_WOOD, 28)
	color_btn.custom_minimum_size = Vector2(110, 76)
	row.add_child(color_btn)
	color_btn.pressed.connect(func():
		_players[idx]["color"] = (_players[idx]["color"] + 1) % Game.AVATAR_COLORS.size()
		avatar.add_theme_stylebox_override("panel", UiKit.pill(Color(Game.AVATAR_COLORS[_players[idx]["color"]]), 38, 4))
		Sound.sfx("pop")
	)

	var del := UiKit.button("×", UiKit.COL_RED, 34)
	del.custom_minimum_size = Vector2(80, 76)
	row.add_child(del)
	del.pressed.connect(func():
		if _players.size() <= 2:
			Toast.show_msg(self, "حداقل دو بازیکن!", UiKit.COL_RED)
			return
		_players.remove_at(idx)
		for ch in list.get_children():
			ch.queue_free()
		for i in _players.size():
			add_player_row(list, i)
		Sound.sfx("error", 1.2, -6.0)
	)

	var add_row := HBoxContainer.new()
	list.add_child(add_row)
	var add := UiKit.button("+ افزودن بازیکن", UiKit.COL_TURQ, 32)
	add.custom_minimum_size = Vector2(320, 80)
	add_row.add_child(add)
	add.pressed.connect(func():
		if _players.size() >= 8:
			Toast.show_msg(self, "حداکثر ۸ بازیکن!", UiKit.COL_RED)
			return
		_players.append({"name": "", "color": _players.size() % Game.AVATAR_COLORS.size()})
		add_player_row(list, _players.size() - 1)
		list.move_child(add_row, list.get_child_count() - 1)
		Sound.sfx("pop")
	)

func _collect_names() -> Array:
	var out: Array = []
	for i in _players.size():
		var nm: String = _players[i]["name"].strip_edges()
		if nm == "":
			nm = "بازیکن %s" % UiKit.fa_num(i + 1)
		out.append({"name": nm, "color": _players[i]["color"]})
	return out
