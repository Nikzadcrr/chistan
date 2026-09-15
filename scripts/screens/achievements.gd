extends Control
## دستاوردها — فهرست با نوار پیشرفت و دکمه دریافت جایزه

var hud: Hud

func _ready() -> void:
	Sound.music("menu")
	var bg := ColorRect.new()
	bg.color = UiKit.COL_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	hud = Hud.new()
	hud.setup("دستاوردها", true, func(): Router.go("menu"))
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
	v.add_theme_constant_override("separation", 16)
	scroll.add_child(v)

	for a in Data.achievements:
		v.add_child(_achievement_card(a))

func _achievement_card(a: Dictionary) -> Control:
	var prog: int = Save._achievement_progress(a)
	var goal: int = int(a["goal"])
	var done: bool = prog >= goal
	var claimed: bool = Save.data["achievements"].get(a["id"], true) == true and Save.data["achievements"].has(a["id"])
	var claimable: bool = done and Save.data["achievements"].get(a["id"], true) == false

	var card := PanelContainer.new()
	var sb := UiKit.pill(UiKit.COL_CREAM if not claimed else UiKit.COL_BG_SOFT, 28, 6)
	if claimable:
		sb.border_color = UiKit.COL_GOLD
		sb.set_border_width_all(4)
	card.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	card.add_child(h)

	# نشان وضعیت
	var badge := Panel.new()
	badge.custom_minimum_size = Vector2(80, 80)
	badge.size = Vector2(80, 80)
	var bcol: Color = UiKit.COL_GREEN if claimed else (UiKit.COL_GOLD if claimable else UiKit.COL_DISABLED)
	badge.add_theme_stylebox_override("panel", UiKit.pill(bcol, 40, 4))
	var bicon := UiKit.label("✓" if claimed else ("!" if claimable else UiKit.fa_num(int(a["reward"]))), 34, UiKit.COL_CREAM if not claimable else UiKit.COL_TEXT, "black")
	bicon.set_anchors_preset(Control.PRESET_FULL_RECT)
	badge.add_child(bicon)
	h.add_child(badge)

	# عنوان + پیشرفت
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 4)
	h.add_child(info)
	var row := HBoxContainer.new()
	info.add_child(row)
	var t1 := UiKit.label(a["title"], 34, UiKit.COL_TEXT, "bold")
	t1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(t1)
	if not claimed:
		row.add_child(UiKit.label("%s / %s" % [UiKit.fa_num(mini(prog, goal)), UiKit.fa_num(goal)], 28, UiKit.COL_TEXT_SOFT))
	var desc := UiKit.label(a["desc"], 24, UiKit.COL_TEXT_SOFT)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info.add_child(desc)
	if not claimed:
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = goal
		bar.value = mini(prog, goal)
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 16)
		bar.add_theme_stylebox_override("background", UiKit.pill(UiKit.COL_BG_SOFT, 8))
		bar.add_theme_stylebox_override("fill", UiKit.pill(UiKit.COL_ORANGE if not done else UiKit.COL_GREEN, 8))
		info.add_child(bar)

	# دکمه دریافت
	if claimable:
		var btn := UiKit.button("+%s" % UiKit.fa_num(int(a["reward"])), UiKit.COL_GOLD, 30, UiKit.COL_TEXT)
		btn.custom_minimum_size = Vector2(170, 80)
		h.add_child(btn)
		btn.pressed.connect(func():
			var reward := Save.claim_achievement(a["id"])
			Sound.sfx("chest")
			Toast.show_msg(self, "دستاورد %s! +%s سکه" % [a["title"], UiKit.fa_num(reward)], UiKit.COL_GOLD)
			hud.refresh()
			Router.go("achievements")
		)

	return card
