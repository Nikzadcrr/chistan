extends Control
## بازی جمعی/لیگ — نوبتی روی یک گوشی با تایمر ۳۰ ثانیه
## چیدمان کانتینری — در هر رزولوشنی درست می‌نشیند

var hud: Hud
var wheel: LetterWheel
var score_label: Label
var timer_bar: ProgressBar
var timer_label: Label
var turn_banner: PanelContainer
var turn_name: Label
var avatar: Panel
var avatar_letter: Label
var words_row: HFlowContainer

var time_left := 30.0
var turn_active := false
var turn_score := 0
var turn_words: Array = []
var _last_tick := -1

func _ready() -> void:
        Sound.music("party")
        var bg := ColorRect.new()
        bg.color = UiKit.COL_BG
        bg.set_anchors_preset(Control.PRESET_FULL_RECT)
        add_child(bg)

        var margin := MarginContainer.new()
        margin.set_anchors_preset(Control.PRESET_FULL_RECT)
        margin.add_theme_constant_override("margin_left", 20)
        margin.add_theme_constant_override("margin_right", 20)
        margin.add_theme_constant_override("margin_top", 24)
        margin.add_theme_constant_override("margin_bottom", 16)
        add_child(margin)

        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 10)
        margin.add_child(v)

        hud = Hud.new()
        hud.setup("دور %s از %s" % [UiKit.fa_num(Game.group["round"]), UiKit.fa_num(Game.group["rounds"])], true, _quit_confirm)
        v.add_child(hud)

        # بنر نوبت
        var banner_row := CenterContainer.new()
        banner_row.custom_minimum_size = Vector2(0, 96)
        v.add_child(banner_row)
        turn_banner = PanelContainer.new()
        turn_banner.add_theme_stylebox_override("panel", UiKit.padded(UiKit.pill(UiKit.COL_CREAM, 30, 8), 12, 30))
        banner_row.add_child(turn_banner)
        var hb := HBoxContainer.new()
        hb.alignment = BoxContainer.ALIGNMENT_CENTER
        hb.add_theme_constant_override("separation", 14)
        turn_banner.add_child(hb)
        avatar = Panel.new()
        avatar.custom_minimum_size = Vector2(64, 64)
        hb.add_child(avatar)
        avatar_letter = UiKit.label("", 34, UiKit.COL_CREAM, "black")
        avatar_letter.set_anchors_preset(Control.PRESET_FULL_RECT)
        avatar.add_child(avatar_letter)
        turn_name = UiKit.label("", 38, UiKit.COL_TEXT, "black")
        hb.add_child(turn_name)

        # نوار زمان
        var timer_holder := Control.new()
        timer_holder.custom_minimum_size = Vector2(0, 52)
        v.add_child(timer_holder)
        timer_bar = ProgressBar.new()
        timer_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
        timer_bar.offset_top = 6
        timer_bar.offset_bottom = -6
        timer_bar.show_percentage = false
        timer_bar.add_theme_stylebox_override("background", UiKit.pill(UiKit.COL_BG_SOFT, 14))
        timer_bar.add_theme_stylebox_override("fill", UiKit.pill(UiKit.COL_GREEN, 14))
        timer_bar.max_value = float(Game.group["seconds"])
        timer_bar.value = float(Game.group["seconds"])
        timer_holder.add_child(timer_bar)
        timer_label = UiKit.label("", 26, UiKit.COL_TEXT, "bold")
        timer_label.set_anchors_preset(Control.PRESET_FULL_RECT)
        timer_holder.add_child(timer_label)

        # امتیاز نوبت
        score_label = UiKit.label("امتیاز این نوبت: ۰", 38, UiKit.COL_TEXT, "bold")
        var score_row := CenterContainer.new()
        score_row.custom_minimum_size = Vector2(0, 70)
        score_row.add_child(score_label)
        v.add_child(score_row)

        # کلمات یافت‌شده (چندردیفی)
        words_row = HFlowContainer.new()
        words_row.custom_minimum_size = Vector2(0, 96)
        words_row.alignment = FlowContainer.ALIGNMENT_CENTER
        words_row.add_theme_constant_override("h_separation", 10)
        words_row.add_theme_constant_override("v_separation", 8)
        v.add_child(words_row)

        # فضای انعطاف وسط
        var spacer := Control.new()
        spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
        v.add_child(spacer)

        # چرخ
        var vh := get_viewport_rect().size.y
        var wheel_zone := Control.new()
        wheel_zone.custom_minimum_size = Vector2(0, clampf(vh * 0.32, 340.0, 660.0))
        wheel_zone.offset_left = 40
        v.add_child(wheel_zone)
        wheel = LetterWheel.new()
        wheel.set_anchors_preset(Control.PRESET_FULL_RECT)
        wheel.offset_left = 80
        wheel.offset_right = -80
        wheel_zone.add_child(wheel)
        wheel.word_swiped.connect(_on_swipe)

        # دکمه پایان نوبت
        var done_row := CenterContainer.new()
        done_row.custom_minimum_size = Vector2(0, 100)
        v.add_child(done_row)
        var done_btn := UiKit.button("پایان نوبت", UiKit.COL_WOOD, 36)
        done_btn.custom_minimum_size = Vector2(420, 88)
        done_row.add_child(done_btn)
        done_btn.pressed.connect(func():
                if turn_active:
                        _finish_turn()
        )

        _start_turn()

func _start_turn() -> void:
        var p: Dictionary = Game.current_player()
        time_left = float(Game.group["seconds"])
        turn_score = 0
        turn_words = []
        turn_active = true
        turn_name.text = "نوبت: %s" % p["name"]
        avatar.add_theme_stylebox_override("panel", UiKit.pill(Color(Game.AVATAR_COLORS[p["color"]]), 32, 3))
        avatar_letter.text = p["name"].substr(0, 1)
        wheel.setup(Game.group["letters"])
        for ch in words_row.get_children():
                ch.queue_free()
        _update_score()
        Sound.sfx("medal", 1.2, -6.0)
        UiKit.haptic(20)
        # انیمیشن بنر
        turn_banner.pivot_offset = turn_banner.size / 2.0
        turn_banner.resized.connect(func(): turn_banner.pivot_offset = turn_banner.size / 2.0)
        turn_banner.scale = Vector2(0.6, 0.6)
        var tw := turn_banner.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tw.tween_property(turn_banner, "scale", Vector2.ONE, 0.4)

func _update_score() -> void:
        score_label.text = "امتیاز این نوبت: %s" % UiKit.fa_num(turn_score)

func _on_swipe(w: String) -> void:
        if not turn_active:
                return
        if w.length() < 3:
                return
        if not Data.is_word_valid(w) or not Data.can_form(w, Game.group["letters"]):
                wheel.shake()
                return
        if w in turn_words:
                wheel.shake()
                return
        turn_words.append(w)
        turn_score += w.length()
        _update_score()
        Sound.sfx_combo("word", turn_words.size() - 1)
        UiKit.haptic(15)
        var chip := UiKit.chip(w, "", Color(UiKit.COL_GREEN, 0.9), 26)
        words_row.add_child(chip)
        if words_row.get_child_count() > 12:
                words_row.get_child(0).queue_free()
        # رکورد بلندترین کلمه
        var rec: Dictionary = Save.data["records"]
        if w.length() > int(rec.get("longest_len", 0)):
                rec["longest_word"] = w
                rec["longest_len"] = w.length()
                Save.save_now()

func _process(delta: float) -> void:
        if not turn_active:
                return
        time_left -= delta
        timer_bar.value = maxf(time_left, 0.0)
        var sec := int(ceilf(time_left))
        timer_label.text = "%s ثانیه" % UiKit.fa_num(sec)
        if time_left <= 10.0:
                (timer_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = UiKit.COL_RED
                if sec != _last_tick and sec <= 5:
                        _last_tick = sec
                        Sound.sfx("tick")
        if time_left <= 0:
                _finish_turn()

func _finish_turn() -> void:
        if not turn_active:
                return
        turn_active = false
        wheel.set_locked(true)
        Game.group_turn_done(turn_score, turn_words)
        Sound.sfx("coin")
        if Game.group["finished"]:
                Router.go("party_results")
        else:
                # بنر دور بعد
                hud.title_label.text = "دور %s از %s" % [UiKit.fa_num(Game.group["round"]), UiKit.fa_num(Game.group["rounds"])]
                var veil := ColorRect.new()
                veil.color = Color(UiKit.COL_BG, 0.0)
                veil.set_anchors_preset(Control.PRESET_FULL_RECT)
                veil.z_index = 30
                add_child(veil)
                var tw := create_tween()
                tw.tween_property(veil, "color:a", 1.0, 0.35)
                tw.tween_callback(func():
                        _start_turn()
                        var tw2 := create_tween()
                        tw2.tween_property(veil, "color:a", 0.0, 0.35)
                        tw2.tween_callback(veil.queue_free)
                )

func _quit_confirm() -> void:
        Save.save_now()
        Router.go("menu")
