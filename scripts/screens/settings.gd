extends Control
## تنظیمات — صدا، لرزش، تم، درباره

func _ready() -> void:
	Sound.music("menu")
	var bg := ColorRect.new()
	bg.color = UiKit.COL_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var hud := Hud.new()
	hud.setup("تنظیمات", true, func(): Router.go("menu"))
	hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud.offset_left = 24; hud.offset_right = -24; hud.offset_top = 24
	add_child(hud)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.padded(UiKit.pill(UiKit.COL_CREAM, 40, 10), 40, 46))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	panel.add_child(v)

	v.add_child(UiKit.label("صدا", 42, UiKit.COL_ORANGE, "black"))
	# موسیقی
	var music_row := HBoxContainer.new()
	music_row.add_theme_constant_override("separation", 16)
	v.add_child(music_row)
	music_row.add_child(UiKit.label("موسیقی", 34, UiKit.COL_TEXT))
	var music_slider := HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	music_slider.value = float(Save.data["settings"].get("music", 0.8))
	music_slider.custom_minimum_size = Vector2(400, 60)
	music_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_row.add_child(music_slider)
	music_slider.value_changed.connect(func(val: float):
		Sound.set_music_vol(val)
		Sound.music("menu")
	)
	# افکت
	var sfx_row := HBoxContainer.new()
	sfx_row.add_theme_constant_override("separation", 16)
	v.add_child(sfx_row)
	sfx_row.add_child(UiKit.label("افکت‌ها", 34, UiKit.COL_TEXT))
	var sfx_slider := HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	sfx_slider.value = float(Save.data["settings"].get("sfx", 0.9))
	sfx_slider.custom_minimum_size = Vector2(400, 60)
	sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_row.add_child(sfx_slider)
	sfx_slider.value_changed.connect(func(val: float): Sound.set_sfx_vol(val))
	sfx_slider.drag_ended.connect(func(changed: bool): Sound.sfx("word"))

	# لرزش
	var haptics_row := HBoxContainer.new()
	v.add_child(haptics_row)
	haptics_row.add_child(UiKit.label("لرزش هنگام لمس", 34, UiKit.COL_TEXT))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	haptics_row.add_child(spacer)
	var haptics_check := CheckButton.new()
	haptics_check.button_pressed = bool(Save.data["settings"].get("haptics", true))
	haptics_row.add_child(haptics_check)
	haptics_check.toggled.connect(func(on: bool):
		Save.data["settings"]["haptics"] = on
		Save.save_now()
		UiKit.haptic(30)
	)

	# آمار
	v.add_child(UiKit.label("آمار تو", 42, UiKit.COL_ORANGE, "black"))
	var st := HBoxContainer.new()
	st.add_theme_constant_override("separation", 12)
	v.add_child(st)
	st.add_child(UiKit.chip("کلمه‌ها: %s" % UiKit.fa_num(Save.data.get("words_found", 0)), "", UiKit.COL_BG_SOFT, 26))
	st.add_child(UiKit.chip("بونوس: %s" % UiKit.fa_num(Save.data.get("bonus_found", 0)), "", UiKit.COL_BG_SOFT, 26))
	st.add_child(UiKit.chip("بلندترین: %s" % Save.data["records"].get("longest_word", "—"), "", UiKit.COL_BG_SOFT, 26))

	# درباره
	v.add_child(UiKit.label("درباره چیستان", 42, UiKit.COL_ORANGE, "black"))
	var about := UiKit.label("چیستان، بازی واژه‌بازی ایرانی است که با موتور گودو ساخته شده.\nسفری از شیراز تا مشهد با پدربزرگ مهربان،\nموسیقی زنده سازهای ایرانی و هزار کلمه برای کشف.\nنسخه ۱.۰.۰", 26, UiKit.COL_TEXT_SOFT)
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about.custom_minimum_size = Vector2(700, 0)
	v.add_child(about)

	# شروع دوباره
	var reset := UiKit.button("شروع دوباره سفر (پاک کردن پیشرفت)", UiKit.COL_RED, 30)
	v.add_child(reset)
	reset.pressed.connect(func(): _confirm_reset())

	panel.reset_size()
	panel.position = (get_viewport_rect().size - panel.size) / 2.0
	UiKit.pop_in(panel, 0.1)

func _confirm_reset() -> void:
	var veil := ColorRect.new()
	veil.color = Color(0, 0, 0, 0.4)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.z_index = 40
	add_child(veil)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.padded(UiKit.pill(UiKit.COL_CREAM, 36, 12), 36, 44))
	panel.z_index = 41
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	panel.add_child(v)
	v.add_child(UiKit.label("همه پیشرفتت پاک شود؟", 40, UiKit.COL_RED, "black"))
	v.add_child(UiKit.label("این کار برگشت ندارد!", 28, UiKit.COL_TEXT_SOFT))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	var no := UiKit.button("نه، پشیمونم", UiKit.COL_WOOD, 32)
	no.custom_minimum_size = Vector2(260, 88)
	row.add_child(no)
	var yes := UiKit.button("بله، پاک کن", UiKit.COL_RED, 32)
	yes.custom_minimum_size = Vector2(260, 88)
	row.add_child(yes)
	no.pressed.connect(func():
		veil.queue_free(); panel.queue_free()
	)
	yes.pressed.connect(func():
		Save._default()
		Save.save_now()
		Sound.sfx("lose")
		Router.go("menu")
	)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.reset_size()
	panel.position = (get_viewport_rect().size - panel.size) / 2.0
	UiKit.pop_in(panel, 0.05)
