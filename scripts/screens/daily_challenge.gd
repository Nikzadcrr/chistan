extends Control
## چالش روزانه — صفحه معرفی با آمار استریک

func _ready() -> void:
	Sound.music("menu")
	var bg := TextureRect.new()
	bg.texture = load("res://assets/art/menu_bg.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var veil := ColorRect.new()
	veil.color = Color(UiKit.COL_BG, 0.6)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(veil)

	var hud := Hud.new()
	hud.setup("چالش روزانه", true, func(): Router.go("menu"))
	hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.offset_left = 24; hud.offset_right = -24; hud.offset_top = 24
	add_child(hud)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.padded(UiKit.pill(UiKit.COL_CREAM, 44, 14), 44, 50))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(panel)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 16)
	panel.add_child(v)

	var gf := Grandfather.new("think", Vector2(320, 320))
	var gc := CenterContainer.new(); gc.add_child(gf)
	v.add_child(gc)
	gf.idle_float()
	gf.say("هر روز یک چرخ تازه! کلمه‌ها را در ۳ دقیقه پیدا کن.", 4.0)

	v.add_child(UiKit.label("چالش روزانه", 64, UiKit.COL_ORANGE, "black"))
	var d := Time.get_datetime_dict_from_system()
	v.add_child(UiKit.label("امروز: %s/%s/%s" % [UiKit.fa_num(d.year), UiKit.fa_num(d.month), UiKit.fa_num(d.day)], 34, UiKit.COL_TEXT_SOFT))

	var daily: Dictionary = Save.data["daily"]
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	var st := UiKit.chip("استریک: %s" % UiKit.fa_num(daily.get("streak", 0)), UiKit.icon_path("star"), UiKit.COL_BG_SOFT, 32)
	row.add_child(st)
	var bs := UiKit.chip("رکورد: %s" % UiKit.fa_num(daily.get("best_streak", 0)), "", UiKit.COL_BG_SOFT, 32)
	row.add_child(bs)
	var done := UiKit.chip("انجام‌شده: %s" % UiKit.fa_num(Save.data.get("daily_done", 0)), "", UiKit.COL_BG_SOFT, 32)
	row.add_child(done)

	# قوانین
	var rules := [
		"هر کلمه معتبر ۳ حرفی به بالا امتیاز = تعداد حرفش",
		"اشتباه گویی ۳ ثانیه جریمه دارد (مگر پاک‌کن فعال باشد)",
		"در پایان، نیمی از امتیازت سکه می‌شود",
	]
	for r in rules:
		var l := UiKit.label("•  " + r, 28, UiKit.COL_TEXT_SOFT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		v.add_child(l)

	var start := UiKit.button("شروع چالش", UiKit.COL_TURQ, 48)
	start.custom_minimum_size = Vector2(420, 104)
	var sc := CenterContainer.new(); sc.add_child(start)
	v.add_child(sc)
	start.pressed.connect(func():
		Game.start_daily()
		Router.go("game")
	)

	panel.reset_size()
	panel.position = (get_viewport_rect().size - panel.size) / 2.0
	UiKit.pop_in(panel, 0.15)
