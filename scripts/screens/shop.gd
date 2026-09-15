extends Control
## فروشگاه — تم‌ها و تبدیل ستاره به سکه

var hud: Hud

func _ready() -> void:
	Sound.music("menu")
	var bg := ColorRect.new()
	bg.color = UiKit.COL_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	hud = Hud.new()
	hud.setup("فروشگاه", true, func(): Router.go("menu"))
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
	v.add_theme_constant_override("separation", 24)
	scroll.add_child(v)

	# ---------- تم‌ها ----------
	v.add_child(UiKit.label("تم‌های بازی", 48, UiKit.COL_ORANGE, "black"))
	var themes: Array = Data.shop.get("themes", [])
	for t in themes:
		v.add_child(_theme_card(t))

	# ---------- صرافی ستاره ----------
	v.add_child(UiKit.label("صرافی ستاره", 48, UiKit.COL_ORANGE, "black"))
	var ex := PanelContainer.new()
	ex.add_theme_stylebox_override("panel", UiKit.padded(UiKit.pill(UiKit.COL_CREAM, 32, 8), 24, 30))
	v.add_child(ex)
	var ev := VBoxContainer.new()
	ev.add_theme_constant_override("separation", 12)
	ex.add_child(ev)
	ev.add_child(UiKit.label("ستاره‌های اضافی‌ات را به سکه تبدیل کن", 30, UiKit.COL_TEXT_SOFT))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	ev.add_child(row)
	row.add_child(UiKit.label("۱۰ ستاره", 36, UiKit.COL_TEXT, "bold"))
	row.add_child(UiKit.label("→", 36, UiKit.COL_TEXT_SOFT, "black"))
	row.add_child(UiKit.label("۱۰۰ سکه", 36, UiKit.COL_GOLD, "bold"))
	var btn := UiKit.button("تبدیل کن", UiKit.COL_GOLD, 34, UiKit.COL_TEXT)
	btn.custom_minimum_size = Vector2(220, 84)
	row.add_child(btn)
	btn.pressed.connect(func():
		if Save.total_stars() < 10:
			Toast.show_msg(self, "حداقل ۱۰ ستاره لازم داری!", UiKit.COL_RED)
			Sound.sfx("error")
			return
		# کم کردن ۱۰ ستاره از کم‌ستاره‌ترین مراحل
		var lvls: Array = []
		for k in Save.data["levels"]:
			lvls.append([int(k), int(Save.data["levels"][k]["stars"])])
		lvls.sort_custom(func(a, b): return a[1] > b[1])
		var removed := 0
		for lv in lvls:
			if removed >= 10: break
			var take := mini(int(Save.data["levels"][str(lv[0])]["stars"]), 10 - removed)
			if take > 0:
				Save.data["levels"][str(lv[0])]["stars"] = int(Save.data["levels"][str(lv[0])]["stars"]) - take
				removed += take
		Save.add_coins(100)
		Save.save_now()
		Sound.sfx("chest")
		hud.refresh()
		Toast.show_msg(self, "۱۰۰ سکه اضافه شد!", UiKit.COL_GOLD)
	)

func _theme_card(t: Dictionary) -> Control:
	var owned: bool = Save.data["themes_owned"].has(t["id"])
	var active: bool = Save.data.get("theme", "cream") == t["id"]
	var card := PanelContainer.new()
	var sb := UiKit.pill(UiKit.COL_CREAM, 32, 8)
	if active:
		sb.border_color = UiKit.COL_GREEN
		sb.set_border_width_all(4)
	card.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	card.add_child(h)
	# نمونه رنگ
	var swatch := Panel.new()
	swatch.custom_minimum_size = Vector2(110, 90)
	swatch.size = Vector2(110, 90)
	var ssb := UiKit.pill(Color(t["bg"] as String), 20)
	ssb.border_color = Color(t["accent"] as String)
	ssb.set_border_width_all(6)
	swatch.add_theme_stylebox_override("panel", ssb)
	h.add_child(swatch)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 2)
	h.add_child(info)
	info.add_child(UiKit.label(t["name"], 36, UiKit.COL_TEXT, "bold"))
	if active:
		info.add_child(UiKit.label("فعال", 28, UiKit.COL_GREEN, "bold"))
	elif owned:
		info.add_child(UiKit.label("خریده‌ای", 26, UiKit.COL_TEXT_SOFT))
	else:
		info.add_child(UiKit.label("%s سکه" % UiKit.fa_num(int(t["price"])), 28, UiKit.COL_ORANGE, "bold"))
	var btn := UiKit.button("فعال کن" if owned else "بخر", UiKit.COL_TURQ if owned else UiKit.COL_ORANGE, 30)
	btn.custom_minimum_size = Vector2(200, 84)
	h.add_child(btn)
	btn.pressed.connect(func():
		if owned:
			Save.set_theme(t["id"])
			Sound.sfx("streak")
			Router.go("shop")  # بازسازی
		else:
			if Save.buy_theme(t["id"], int(t["price"])):
				Save.set_theme(t["id"])
				Sound.sfx("chest")
				Toast.show_msg(self, "تم %s فعال شد!" % t["name"], UiKit.COL_GREEN)
				Router.go("shop")
			else:
				Toast.show_msg(self, "سکه کافی نداری!", UiKit.COL_RED)
				Sound.sfx("error")
	)
	return card
