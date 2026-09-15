extends Control
## نتایج جمعی/لیگ — رتبه‌بندی، مدال و قهرمانی

func _ready() -> void:
	Sound.music("party")
	var bg := TextureRect.new()
	bg.texture = load("res://assets/art/menu_bg.webp")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var veil := ColorRect.new()
	veil.color = Color(UiKit.COL_BG, 0.6)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(veil)

	var ranking: Array = Game.group_ranking()
	var champion: Dictionary = Game.group_champion()
	var is_league: bool = Game.group.get("is_league", false)

	# ثبت رکوردها
	var round_best: int = 0
	for r in ranking:
		round_best = maxi(round_best, r["score"])
	Save.add_group_result(true, champion.get("name", ""), round_best)

	# اسکرول — در صفحه‌های کوتاه هم جدول کامل دیده می‌شود
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 110
	scroll.offset_bottom = -30
	scroll.offset_left = 50
	scroll.offset_right = -50
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 18)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(v)

	# تاج قهرمان
	var trophy := UiKit.icon_rect("res://assets/art/ic_trophy.webp", Vector2(180, 180))
	var tc := CenterContainer.new(); tc.add_child(trophy)
	v.add_child(tc)
	UiKit.breathe(trophy, 1.08, 1.6)

	v.add_child(UiKit.label("قهرمان: %s" % champion.get("name", "—"), 56, UiKit.COL_ORANGE, "black"))
	v.add_child(UiKit.label("لیگ خانوادگی تمام شد" if is_league else "بازی جمعی تمام شد", 34, UiKit.COL_TEXT_SOFT))

	# ردیف مدال‌ها
	var pod := HBoxContainer.new()
	pod.alignment = BoxContainer.ALIGNMENT_CENTER
	pod.add_theme_constant_override("separation", 20)
	v.add_child(pod)
	var medals := [UiKit.COL_GOLD, Color("c0c0c8"), Color("cd7f32")]
	var medals_fa := ["طلایی", "نقره‌ای", "برنزی"]
	for i in mini(3, ranking.size()):
		var r: Dictionary = ranking[i]
		var card := PanelContainer.new()
		var col: Color = medals[i]
		card.add_theme_stylebox_override("panel", UiKit.padded(UiKit.pill(col, 26, 8), 18, 26))
		var cv := VBoxContainer.new()
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		cv.add_theme_constant_override("separation", 4)
		card.add_child(cv)
		var av := Panel.new()
		av.custom_minimum_size = Vector2(90, 90)
		av.size = Vector2(90, 90)
		av.add_theme_stylebox_override("panel", UiKit.pill(Color(Game.AVATAR_COLORS[r["color"]]), 45, 3))
		var avl := UiKit.label(r["name"].substr(0, 1), 42, UiKit.COL_CREAM, "black")
		avl.set_anchors_preset(Control.PRESET_FULL_RECT)
		av.add_child(avl)
		var avc := CenterContainer.new(); avc.add_child(av)
		cv.add_child(avc)
		cv.add_child(UiKit.label(r["name"], 32, UiKit.COL_TEXT, "bold"))
		cv.add_child(UiKit.label("%s امتیاز" % UiKit.fa_num(r["score"]), 28, UiKit.COL_TEXT_SOFT))
		cv.add_child(UiKit.label("مدال %s" % medals_fa[i], 24, Color(UiKit.COL_TEXT, 0.6)))
		pod.add_child(card)
		UiKit.pop_in(card, 0.3 + i * 0.25)

	# جدول کامل
	var table := VBoxContainer.new()
	table.add_theme_constant_override("separation", 8)
	v.add_child(table)
	for i in ranking.size():
		var r: Dictionary = ranking[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		table.add_child(row)
		row.add_child(UiKit.label("%s." % UiKit.fa_num(i + 1), 34, UiKit.COL_TEXT_SOFT, "bold"))
		var nm := UiKit.label(r["name"], 34, UiKit.COL_TEXT, "bold")
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(nm)
		if r["longest"] != "":
			row.add_child(UiKit.label("بلندترین: %s" % r["longest"], 26, UiKit.COL_TEXT_SOFT))
		row.add_child(UiKit.label(UiKit.fa_num(r["score"]), 38, UiKit.COL_ORANGE, "black"))

	# دکمه‌ها
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 18)
	v.add_child(btns)
	var again := UiKit.button("بازی دوباره", UiKit.COL_GREEN, 40)
	again.custom_minimum_size = Vector2(280, 96)
	btns.add_child(again)
	again.pressed.connect(func():
		Game.start_group({"players": Game.group["players"], "rounds": Game.group["rounds"], "is_league": is_league})
		Router.go("party_game")
	)
	var menu := UiKit.button("منوی اصلی", UiKit.COL_ORANGE, 40)
	menu.custom_minimum_size = Vector2(280, 96)
	btns.add_child(menu)
	menu.pressed.connect(func(): Router.go("menu"))

	# جشن
	Sound.sfx("medal")
	var vp := get_viewport_rect().size
	Confetti.burst(self, vp * Vector2(0.5, 0.3), 130)
	Confetti.burst(self, vp * Vector2(0.28, 0.2), 60)
	Confetti.burst(self, vp * Vector2(0.72, 0.2), 60)
	UiKit.haptic(60)
	var t := get_tree().create_timer(0.9)
	t.timeout.connect(func():
		Confetti.burst(self, vp * Vector2(0.5, 0.45), 80)
		Sound.sfx("win")
	)
