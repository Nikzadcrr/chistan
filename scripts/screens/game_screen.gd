extends Control
## صفحه بازی — هسته چیستان: کشیدن حروف، کشف کلمات، راهنماها، برد و چالش روزانه
## چیدمان کاملاً کانتینری — بدون آفست دستی؛ در هر رزولوشنی درست می‌نشیند

var hud: Hud
var grid: CrosswordGrid
var wheel: LetterWheel
var hint_bar: HBoxContainer
var timer_bar: ProgressBar
var timer_label: Label
var gf: Grandfather
var score_chip_label: Label
var daily_words_flow: HFlowContainer

var city: Dictionary
var accent: Color = UiKit.COL_ORANGE
var accent2: Color = UiKit.COL_GREEN

var letters: Array = []
var targets: Array = []
var bonus_pool: Dictionary = {}

var coins_earned := 0
var hints_used := 0
var combo := 0
var extra_words := 0

# چالش روزانه
var daily_active := false
var time_left := 180.0
var daily_score := 0
var daily_found := {}
var eraser_shield := false
var daily_ended := false

func _ready() -> void:
	daily_active = Game.mode == Game.Mode.DAILY
	if daily_active:
		_build_daily()
	else:
		_build_classic()

# ---------- ساخت صحنه ----------
func _base_build(bg_path: String, title: String) -> VBoxContainer:
	accent = Color(city["color"])
	accent2 = Color(city["color2"])

	var bg := TextureRect.new()
	bg.texture = load(bg_path)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var veil := ColorRect.new()
	veil.color = Color(UiKit.COL_BG, 0.62)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(veil)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	margin.add_child(v)

	hud = Hud.new()
	hud.setup(title, true, _on_back)
	v.add_child(hud)
	return v

func _add_wheel_zone(v: VBoxContainer, pose: String, greeting: String) -> void:
	## ناحیه چرخ: ستون پدربزرگ + چرخ حروف — همیشه بدون همپوشانی
	var vh := get_viewport_rect().size.y
	var zone := HBoxContainer.new()
	zone.custom_minimum_size = Vector2(0, clampf(vh * 0.30, 330.0, 640.0))
	zone.add_theme_constant_override("separation", 6)
	v.add_child(zone)

	var gf_col := CenterContainer.new()
	gf_col.custom_minimum_size = Vector2(196, 0)
	zone.add_child(gf_col)
	gf = Grandfather.new(pose, Vector2(190, 190))
	gf_col.add_child(gf)
	gf.idle_float()
	if greeting != "":
		gf.say(greeting, 4.0)

	wheel = LetterWheel.new()
	wheel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wheel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	zone.add_child(wheel)
	wheel.word_swiped.connect(_on_swipe)
	Sound.sfx("whoosh")

func _build_classic() -> void:
	city = Data.city_of_level(Game.level_id)
	var lv := Data.get_level(Game.level_id)
	var v := _base_build("res://assets/art/%s.webp" % city["bg"], "%s — مرحله %s" % [city["name"], UiKit.fa_num(Game.level_id)])
	letters = lv["letters"].duplicate()
	targets = lv["targets"].duplicate()
	bonus_pool = {}
	for w in lv.get("bonus", []):
		bonus_pool[w] = true

	# ناحیه جدول — فضای باقی‌مانده را می‌گیرد
	var grid_slot := MarginContainer.new()
	grid_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_slot.add_theme_constant_override("margin_top", 6)
	v.add_child(grid_slot)
	grid = CrosswordGrid.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_slot.add_child(grid)
	grid.setup(lv, accent, accent2)
	grid.word_found_anim_done.connect(_on_word_found)

	# نوار راهنما
	hint_bar = HBoxContainer.new()
	hint_bar.custom_minimum_size = Vector2(0, 92)
	hint_bar.add_theme_constant_override("separation", 14)
	v.add_child(hint_bar)
	_add_hint_button("سرنخ", UiKit.COL_TURQ, func(): _use_hint("hint", 30))
	_add_hint_button("آشکارساز", UiKit.COL_GREEN, func(): _use_hint("reveal", 60))

	# ناحیه چرخ + پدربزرگ
	_add_wheel_zone(v, "welcome", "")
	wheel.setup(letters)

func _build_daily() -> void:
	city = Data.cities[0]
	var v := _base_build("res://assets/art/menu_bg.webp", "چالش روزانه — %s" % UiKit.fa_num(_fa_date()))
	time_left = Game.daily_time
	daily_score = 0
	daily_found = {}
	letters = Game.daily_letters.duplicate()

	# امتیاز
	var score_row := CenterContainer.new()
	score_row.custom_minimum_size = Vector2(0, 84)
	v.add_child(score_row)
	var score_panel := UiKit.chip("امتیاز: ۰", "", UiKit.COL_CREAM, 36)
	score_panel.name = "ScorePanel"
	score_row.add_child(score_panel)
	score_chip_label = score_panel.get_child(0).get_child(score_panel.get_child(0).get_child_count() - 1)

	# نوار زمان
	var timer_holder := Control.new()
	timer_holder.custom_minimum_size = Vector2(0, 52)
	v.add_child(timer_holder)
	timer_bar = ProgressBar.new()
	timer_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	timer_bar.offset_top = 6
	timer_bar.offset_bottom = -6
	timer_bar.show_percentage = false
	var sb_bg := UiKit.pill(UiKit.COL_BG_SOFT, 14)
	var sb_fill := UiKit.pill(UiKit.COL_TURQ, 14)
	timer_bar.add_theme_stylebox_override("background", sb_bg)
	timer_bar.add_theme_stylebox_override("fill", sb_fill)
	timer_bar.max_value = time_left
	timer_bar.value = time_left
	timer_holder.add_child(timer_bar)
	timer_label = UiKit.label("", 26, UiKit.COL_TEXT, "bold")
	timer_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	timer_holder.add_child(timer_label)

	# ناحیه کلمات یافت‌شده — جای جدول در چالش روزانه
	var mid := VBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 14)
	v.add_child(mid)
	mid.add_child(UiKit.label("کلمه‌های امروز", 34, UiKit.COL_TEXT_SOFT, "bold"))
	daily_words_flow = HFlowContainer.new()
	daily_words_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	daily_words_flow.add_theme_constant_override("h_separation", 10)
	daily_words_flow.add_theme_constant_override("v_separation", 8)
	mid.add_child(daily_words_flow)
	var mid_hint := UiKit.label("هر کلمه معتبر = امتیاز به اندازه حرف‌هایش", 26, Color(UiKit.COL_TEXT_SOFT, 0.7))
	mid.add_child(mid_hint)

	# نوار راهنما (۴ دکمه)
	hint_bar = HBoxContainer.new()
	hint_bar.custom_minimum_size = Vector2(0, 92)
	hint_bar.add_theme_constant_override("separation", 10)
	v.add_child(hint_bar)
	_add_hint_button("سرنخ", UiKit.COL_TURQ, func(): _use_hint("hint", 30))
	_add_hint_button("چای +۳۰ثانیه", UiKit.COL_GOLD, func(): _use_hint("tea", 70), UiKit.COL_TEXT)
	_add_hint_button("پاک‌کن", UiKit.COL_GREEN, func(): _use_hint("eraser", 45))
	_add_hint_button("پایان", UiKit.COL_RED, func(): _end_daily(true))

	# چرخ + پدربزرگ
	_add_wheel_zone(v, "think", "هر کلمه‌ای که از این حروف بسازی امتیاز دارد!")
	wheel.setup(letters)

func _fa_date() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%s/%s/%s" % [UiKit.fa_num(d.year), UiKit.fa_num(d.month), UiKit.fa_num(d.day)]

# ---------- راهنماها ----------
func _add_hint_button(text: String, col: Color, action: Callable, text_col: Color = UiKit.COL_CREAM) -> void:
	var b := UiKit.button(text, col, 30, text_col)
	b.custom_minimum_size = Vector2(0, 84)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_bar.add_child(b)
	b.pressed.connect(action)

func _use_hint(kind: String, price: int) -> void:
	# ابتدا از انبار، سپس خرید با سکه
	if Save.inventory(kind) > 0:
		Save.use_item(kind)
	elif not Save.try_spend(price):
		Toast.show_msg(self, "سکه کافی نداری! سر فروشگاه برو.", UiKit.COL_RED)
		Sound.sfx("error")
		return
	Sound.sfx("hint")
	hints_used += 1
	match kind:
		"hint":
			var w: String = grid.reveal_word_letter()
			if daily_active:
				Toast.show_msg(self, "حرف اول یکی از کلمات را ببین!", UiKit.COL_TURQ)
		"reveal":
			grid.reveal_cell_hint()
		"tea":
			time_left += 30.0
			timer_bar.max_value = maxf(timer_bar.max_value, time_left)
			Toast.show_msg(self, "چای تازه دم! ۳۰ ثانیه اضافه شد", UiKit.COL_GOLD)
		"eraser":
			eraser_shield = true
			Toast.show_msg(self, "پاک‌کن فعال شد — اشتباه‌ها جریمه ندارند", UiKit.COL_GREEN)
	hud.refresh()

# ---------- ورودی کلمه ----------
func _on_swipe(w: String) -> void:
	if daily_active:
		_daily_swipe(w)
	else:
		_classic_swipe(w)

func _classic_swipe(w: String) -> void:
	if targets.has(w) and not grid.is_found(w):
		_found_target(w)
	elif bonus_pool.has(w):
		coins_earned += 15
		Save.add_coins(15)
		Save.add_word_found(w, true)
		Sound.sfx("bonus")
		Toast.show_msg(self, "کلمه بونوس! +۱۵ سکه", UiKit.COL_GOLD)
		UiKit.haptic(20)
		hud.refresh(); hud.coin_bounce()
		_confetti_at_wheel(18)
		Game.daily_score += 1  # شمارش بونوس‌ها برای آمار
	elif Data.is_word_valid(w) and extra_words < 10:
		extra_words += 1
		coins_earned += 1
		Save.add_coins(1)
		Sound.sfx("coin", 1.1, -6.0)
		Toast.show_msg(self, "کلمه معتبره ولی برای این مرحله نیست! +۱", UiKit.COL_TEXT_SOFT, 32)
	else:
		combo = 0
		wheel.shake()
		UiKit.haptic(35)

func _found_target(w: String) -> void:
	var gain := w.length() * 2
	coins_earned += gain
	combo += 1
	Save.add_coins(gain)
	Save.add_word_found(w, false)
	Sound.sfx_combo("word", combo - 1)
	UiKit.haptic(25)
	hud.refresh(); hud.coin_bounce()
	_confetti_at_wheel(26)
	grid.try_found(w)

func _confetti_at_wheel(n: int) -> void:
	var at := wheel.get_global_rect().get_center() - Vector2(0, wheel.size.y * 0.3)
	Confetti.burst(self, at, n)

func _on_word_found(_w: String) -> void:
	if grid.all_found():
		_win_level()

# ---------- چالش روزانه ----------
func _daily_swipe(w: String) -> void:
	if daily_ended:
		return
	if w.length() < 3:
		return
	if not Data.is_word_valid(w) or not Data.can_form(w, letters):
		if not eraser_shield:
			time_left = maxf(time_left - 3.0, 0.0)
			combo = 0
			wheel.shake()
			Toast.show_msg(self, "۳ ثانیه از دست رفت!", UiKit.COL_RED, 32)
		else:
			wheel.shake()
			Toast.show_msg(self, "پاک‌کن نجاتت داد!", UiKit.COL_GREEN, 32)
			eraser_shield = false
		return
	if daily_found.has(w):
		wheel.shake()
		Toast.show_msg(self, "این را قبلاً گفتی!", UiKit.COL_TEXT_SOFT, 32)
		return
	daily_found[w] = true
	var gain := w.length()
	daily_score += gain
	coins_earned += gain
	Save.add_coins(gain)
	Save.add_word_found(w, false)
	combo += 1
	Sound.sfx_combo("word", combo - 1)
	UiKit.haptic(20)
	hud.refresh(); hud.coin_bounce()
	_confetti_at_wheel(20)
	if daily_words_flow != null:
		var wchip := UiKit.chip(w, "", Color(UiKit.COL_GREEN, 0.9), 28)
		daily_words_flow.add_child(wchip)
		if daily_words_flow.get_child_count() > 24:
			daily_words_flow.get_child(0).queue_free()
	if score_chip_label != null:
		score_chip_label.text = "امتیاز: %s" % UiKit.fa_num(daily_score)
		var sp := score_chip_label.get_parent().get_parent()
		sp.pivot_offset = sp.size / 2.0
		var tw := sp.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		sp.scale = Vector2(1.15, 1.15)
		tw.tween_property(sp, "scale", Vector2.ONE, 0.25)

func _process(delta: float) -> void:
	if daily_active and not daily_ended:
		time_left -= delta
		timer_bar.value = maxf(time_left, 0.0)
		var sec := int(ceilf(time_left))
		timer_label.text = "%s:%s" % [UiKit.fa_num(sec / 60), UiKit.fa_num("%02d" % (sec % 60))]
		if time_left <= 20.0 and sec % 2 == 0:
			(timer_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = UiKit.COL_RED
		if time_left <= 0:
			_end_daily(false)

func _end_daily(manual: bool) -> void:
	if daily_ended:
		return
	daily_ended = true
	wheel.set_locked(true)
	var bonus := int(daily_score / 2.0)
	Save.add_coins(bonus)
	Save.add_daily_done()
	coins_earned += bonus
	_show_daily_results()

func _show_daily_results() -> void:
	Sound.sfx("medal")
	var ov := UiKit.overlay(self, 0.4)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.padded(UiKit.pill(UiKit.COL_CREAM, 44, 16), 44, 50))
	ov["center"].add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	v.add_child(UiKit.label("چالش امروز تمام شد!", 56, UiKit.COL_ORANGE, "black"))
	v.add_child(UiKit.label("امتیاز امروز: %s" % UiKit.fa_num(daily_score), 44, UiKit.COL_TEXT, "bold"))
	v.add_child(UiKit.label("کلمات یافت‌شده: %s" % UiKit.fa_num(daily_found.size()), 36, UiKit.COL_TEXT_SOFT))
	v.add_child(UiKit.label("پاداش پایانی: +%s سکه" % UiKit.fa_num(int(daily_score / 2.0)), 36, UiKit.COL_GREEN, "bold"))
	var streak: Dictionary = Save.data["daily"]
	v.add_child(UiKit.label("استریک: %s روز پشت‌سرهم" % UiKit.fa_num(streak.get("streak", 0)), 32, UiKit.COL_TEXT_SOFT))
	var done := UiKit.button("برگشت به منو", UiKit.COL_ORANGE, 42)
	var dc := CenterContainer.new()
	dc.add_child(done)
	v.add_child(dc)
	done.pressed.connect(func(): Router.go("menu"))
	UiKit.pop_in(panel, 0.1)
	var vp := get_viewport_rect().size
	Confetti.burst(self, vp * 0.5, 60)
	hud.refresh()

# ---------- برد مرحله ----------
func _win_level() -> void:
	wheel.set_locked(true)
	gf.celebrate()
	Sound.sfx("win")
	var vp := get_viewport_rect().size
	Confetti.burst(self, vp * Vector2(0.5, 0.38), 120)
	Confetti.burst(self, vp * Vector2(0.28, 0.26), 60)
	Confetti.burst(self, vp * Vector2(0.72, 0.26), 60)
	UiKit.haptic(60)
	# ستاره‌ها
	var stars := 3 if hints_used == 0 else (2 if hints_used <= 2 else 1)
	var star_reward: int = [0, 25, 50, 75][stars]
	Save.add_coins(star_reward)
	coins_earned += star_reward
	var improved: bool = Save.set_level_result(Game.level_id, stars)
	Save.save_now()
	hud.refresh()

	# پنل برد
	var ov := UiKit.overlay(self, 0.35)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.padded(UiKit.pill(UiKit.COL_CREAM, 48, 18), 40, 54))
	ov["center"].add_child(panel)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	v.add_child(UiKit.label("آفرین!", 72, UiKit.COL_ORANGE, "black"))
	v.add_child(UiKit.label("مرحله %s %s تمام شد" % [UiKit.fa_num(Game.level_id), "دوباره" if not improved else ""], 36, UiKit.COL_TEXT_SOFT))

	# ردیف ستاره‌ها
	var star_row := HBoxContainer.new()
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	star_row.add_theme_constant_override("separation", 18)
	v.add_child(star_row)
	for i in 3:
		var st := UiKit.label("★", 110, Color(UiKit.COL_GOLD, 0.25), "black")
		star_row.add_child(st)
		if i < stars:
			var t := get_tree().create_timer(0.5 + i * 0.45)
			t.timeout.connect(func():
				if is_instance_valid(st):
					st.add_theme_color_override("font_color", UiKit.COL_GOLD)
					st.pivot_offset = st.size / 2.0
					var tw := st.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					st.scale = Vector2(1.8, 1.8)
					tw.tween_property(st, "scale", Vector2.ONE, 0.4)
					Sound.sfx("star", 1.0 + i * 0.12)
					Confetti.burst(self, st.get_global_rect().get_center(), 24)
			)

	v.add_child(UiKit.label("سکه‌های این مرحله: %s" % UiKit.fa_num(coins_earned), 40, UiKit.COL_GOLD, "bold"))
	if improved:
		v.add_child(UiKit.label("رکورد جدید!", 32, UiKit.COL_GREEN, "bold"))

	var gf_win := Grandfather.new("celebrate", Vector2(300, 300))
	var gfw := CenterContainer.new()
	gfw.add_child(gf_win)
	v.add_child(gfw)

	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 18)
	v.add_child(btns)
	var map_btn := UiKit.button("نقشه", UiKit.COL_WOOD, 40)
	map_btn.custom_minimum_size = Vector2(220, 92)
	btns.add_child(map_btn)
	map_btn.pressed.connect(func(): Router.go("city_map"))
	var next_btn := UiKit.button("مرحله بعد", UiKit.COL_ORANGE, 40)
	next_btn.custom_minimum_size = Vector2(260, 92)
	btns.add_child(next_btn)
	if Game.level_id >= 100:
		next_btn.disabled = true
		next_btn.text = "پایان سفر!"
	next_btn.pressed.connect(func():
		Game.start_level(mini(Game.level_id + 1, 100))
		Router.go("game")
	)

	UiKit.pop_in(panel, 0.4)
	var t := get_tree().create_timer(1.0)
	t.timeout.connect(func():
		if is_instance_valid(gf_win):
			Confetti.burst(self, gf_win.get_global_rect().get_center(), 40)
			Sound.sfx("streak")
	)

func _on_back() -> void:
	Save.save_now()
	Router.go(Router.back_target_for_mode())
