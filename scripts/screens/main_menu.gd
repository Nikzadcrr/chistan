extends Control
## منوی اصلی — قلب خانه بازی

const TIPS := [
        "کلمه‌های بونوس پیدا کن تا سکه بیشتر بگیری!",
        "چایی پدربزرگ مالِ فکر کردن است، مال عجله نیست!",
        "هر چه کلمه بلندتر، سکه بیشتر!",
        "استریک روزانه‌ات را نگه دار تا جایزه هفته طلایی بگیری!",
]

var hud: Hud
var gf: Grandfather
var play_btn: Button

func _ready() -> void:
        Sound.music("menu")
        _build()
        _maybe_daily_gift()
        Save.check_achievements()

func _build() -> void:
        # پس‌زمینه
        var bg := TextureRect.new()
        bg.texture = load("res://assets/art/menu_bg.webp")
        bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        bg.set_anchors_preset(Control.PRESET_FULL_RECT)
        add_child(bg)
        var veil := ColorRect.new()
        veil.color = Color(UiKit.COL_BG, 0.55)
        veil.set_anchors_preset(Control.PRESET_FULL_RECT)
        add_child(veil)

        # HUD
        hud = Hud.new()
        hud.setup("چیستان", false)
        hud.set_anchors_preset(Control.PRESET_TOP_WIDE)
        hud.offset_left = 24
        hud.offset_right = -24
        hud.offset_top = 24
        add_child(hud)

        # ستون اصلی
        var v := VBoxContainer.new()
        v.set_anchors_preset(Control.PRESET_FULL_RECT)
        v.offset_top = 150
        v.offset_bottom = -30
        v.add_theme_constant_override("separation", 18)
        v.alignment = BoxContainer.ALIGNMENT_CENTER
        add_child(v)

        # ردیف پدربزرگ + تیتر
        var top := HBoxContainer.new()
        top.alignment = BoxContainer.ALIGNMENT_CENTER
        top.add_theme_constant_override("separation", 8)
        v.add_child(top)

        gf = Grandfather.new("welcome", Vector2(430, 430))
        top.add_child(gf)
        gf.idle_float()
        gf.say("سلام رفیق! امروز کدام شهر را می‌رویم؟", 4.0)

        var title_col := VBoxContainer.new()
        title_col.alignment = BoxContainer.ALIGNMENT_CENTER
        title_col.add_theme_constant_override("separation", 4)
        top.add_child(title_col)
        var t1 := UiKit.label("چیستان", 96, UiKit.COL_ORANGE, "black")
        title_col.add_child(t1)
        var t2 := UiKit.label("واژه‌بازی ایرانی", 36, UiKit.COL_TEXT_SOFT, "medium")
        title_col.add_child(t2)

        var spacer1 := Control.new(); spacer1.custom_minimum_size = Vector2(0, 8)
        v.add_child(spacer1)

        # دکمه اصلی ادامه بازی
        var next_id: int = Save.current_level()
        var city: Dictionary = Data.city_of_level(mini(next_id, 100))
        play_btn = UiKit.button("ادامه سفر — %s، مرحله %s" % [city["name"], UiKit.fa_num(next_id)], UiKit.COL_ORANGE, 46)
        play_btn.custom_minimum_size = Vector2(640, 110)
        var pc := CenterContainer.new(); pc.add_child(play_btn)
        v.add_child(pc)
        play_btn.pressed.connect(func():
                Game.start_level(next_id)
                Router.go("game")
        )
        UiKit.breathe(play_btn, 1.03, 2.0)

        # ردیف دکمه‌ها
        var row1 := HBoxContainer.new()
        row1.alignment = BoxContainer.ALIGNMENT_CENTER
        row1.add_theme_constant_override("separation", 18)
        v.add_child(row1)
        var daily_btn := UiKit.button("چالش روزانه", UiKit.COL_TURQ, 38)
        daily_btn.custom_minimum_size = Vector2(310, 96)
        row1.add_child(daily_btn)
        daily_btn.pressed.connect(func(): Router.go("daily"))

        var party_btn := UiKit.button("حالت جمعی", UiKit.COL_GREEN, 38)
        party_btn.custom_minimum_size = Vector2(310, 96)
        row1.add_child(party_btn)
        party_btn.pressed.connect(func(): Router.go("party_setup"))

        var row2 := HBoxContainer.new()
        row2.alignment = BoxContainer.ALIGNMENT_CENTER
        row2.add_theme_constant_override("separation", 18)
        v.add_child(row2)
        var league_btn := UiKit.button("لیگ خانوادگی", UiKit.COL_GOLD, 38, UiKit.COL_TEXT)
        league_btn.custom_minimum_size = Vector2(310, 96)
        row2.add_child(league_btn)
        league_btn.pressed.connect(func(): Router.go("league"))

        var map_btn := UiKit.button("نقشه سفر", UiKit.COL_WOOD, 38)
        map_btn.custom_minimum_size = Vector2(310, 96)
        row2.add_child(map_btn)
        map_btn.pressed.connect(func(): Router.go("city_map"))

        # نوار پایین: فروشگاه، دستاوردها، تنظیمات
        var bottom := HBoxContainer.new()
        bottom.alignment = BoxContainer.ALIGNMENT_CENTER
        bottom.add_theme_constant_override("separation", 18)
        v.add_child(bottom)
        var shop_btn := UiKit.button("فروشگاه", UiKit.COL_ORANGE_DARK, 36)
        shop_btn.custom_minimum_size = Vector2(200, 84)
        bottom.add_child(shop_btn)
        shop_btn.pressed.connect(func(): Router.go("shop"))

        var ach_btn := UiKit.button("دستاوردها", UiKit.COL_ORANGE_DARK, 36)
        ach_btn.custom_minimum_size = Vector2(200, 84)
        bottom.add_child(ach_btn)
        ach_btn.pressed.connect(func(): Router.go("achievements"))

        var set_btn := UiKit.button("تنظیمات", UiKit.COL_ORANGE_DARK, 36)
        set_btn.custom_minimum_size = Vector2(200, 84)
        bottom.add_child(set_btn)
        set_btn.pressed.connect(func(): Router.go("settings"))

        # نشانگر دستاورد ادعانشده
        if Save.unclaimed_achievements().size() > 0:
                var dot := Panel.new()
                dot.custom_minimum_size = Vector2(24, 24)
                dot.add_theme_stylebox_override("panel", UiKit.pill(UiKit.COL_RED, 12))
                dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
                dot.offset_left = -30
                dot.offset_top = -10
                dot.offset_right = -6
                dot.offset_bottom = 14
                dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
                ach_btn.add_child(dot)
                var tw := dot.create_tween().set_loops()
                tw.tween_property(dot, "modulate:a", 0.4, 0.5)
                tw.tween_property(dot, "modulate:a", 1.0, 0.5)

        UiKit.stagger_in([top, pc, row1, row2, bottom], 0.08)

        # نکته پدربزرگ هر از گاهی
        var t := get_tree().create_timer(9.0)
        t.timeout.connect(func():
                if is_instance_valid(gf):
                        gf.say(TIPS[randi() % TIPS.size()], 4.0)
        )

func _maybe_daily_gift() -> void:
        ## جایزه ورود روزانه — تقویم ۷ روزه
        var daily: Dictionary = Save.data["daily"]
        if daily.get("last", "") == Save.today_str():
                return
        # لایه مودال — همیشه مرکز، بدون محاسبه دستی
        var ov := UiKit.overlay(self, 0.35, 39)
        var panel := PanelContainer.new()
        panel.add_theme_stylebox_override("panel", UiKit.padded(UiKit.pill(UiKit.COL_CREAM, 40, 14), 40, 46))
        ov["center"].add_child(panel)
        var v := VBoxContainer.new()
        v.add_theme_constant_override("separation", 16)
        panel.add_child(v)
        v.add_child(UiKit.label("هدیه روزانه پدربزرگ", 52, UiKit.COL_ORANGE, "black"))
        var streak: int = daily.get("streak", 0)
        v.add_child(UiKit.label("روز پیوسته: %s   |   رکورد: %s" % [UiKit.fa_num(streak), UiKit.fa_num(daily.get("best_streak", 0))], 32, UiKit.COL_TEXT_SOFT))
        var days := HBoxContainer.new()
        days.add_theme_constant_override("separation", 10)
        v.add_child(days)
        for i in 7:
                var day_panel := PanelContainer.new()
                var claimed := i < streak % 7 or (streak > 0 and streak % 7 == 0)
                var is_today: bool = i == (streak % 7)
                var reward: int = [20, 30, 40, 50, 60, 80, 150][i]
                var col := UiKit.COL_GOLD if is_today else (UiKit.COL_BG_SOFT if not claimed else Color(UiKit.COL_GREEN, 0.25))
                day_panel.add_theme_stylebox_override("panel", UiKit.padded(UiKit.pill(col, 18), 14, 10))
                var dv := VBoxContainer.new()
                dv.add_theme_constant_override("separation", 4)
                dv.add_child(UiKit.label("روز %s" % UiKit.fa_num(i + 1), 24, UiKit.COL_TEXT_SOFT))
                dv.add_child(UiKit.label("%s" % UiKit.fa_num(reward), 34, UiKit.COL_TEXT, "bold"))
                day_panel.add_child(dv)
                days.add_child(day_panel)
        var claim := UiKit.button("دریافت هدیه امروز", UiKit.COL_GREEN, 42)
        var cc := CenterContainer.new()
        cc.add_child(claim)
        v.add_child(cc)
        UiKit.pop_in(panel, 0.3)
        claim.pressed.connect(func():
                var day_idx: int = streak % 7
                var reward: int = [20, 30, 40, 50, 60, 80, 150][day_idx]
                Save.add_coins(reward)
                Sound.sfx("chest")
                Save.save_now()
                hud.refresh()
                UiKit.close_overlay(ov)
                UiKit.haptic(30)
        )
