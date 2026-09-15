extends Control
## صفحه ورود — لوگو، عنوان و پدربزرگ

var _done := false

func _ready() -> void:
        Sound.music("menu")
        # پس‌زمینه کرم با هاله گرم
        var bg := ColorRect.new()
        bg.color = UiKit.COL_BG
        bg.set_anchors_preset(Control.PRESET_FULL_RECT)
        add_child(bg)
        var glow := TextureRect.new()
        glow.texture = load("res://assets/art/menu_bg.png")
        glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        glow.set_anchors_preset(Control.PRESET_FULL_RECT)
        glow.modulate = Color(1, 1, 1, 0.25)
        add_child(glow)

        var v := VBoxContainer.new()
        v.set_anchors_preset(Control.PRESET_FULL_RECT)
        v.alignment = BoxContainer.ALIGNMENT_CENTER
        v.add_theme_constant_override("separation", 10)
        add_child(v)

        var icon := UiKit.icon_rect("res://assets/art/icon.png", Vector2(360, 360))
        var icon_wrap := CenterContainer.new()
        icon_wrap.add_child(icon)
        v.add_child(icon_wrap)

        var title := UiKit.label("چیستان", 150, UiKit.COL_ORANGE, "black")
        var t2 := CenterContainer.new(); t2.add_child(title)
        v.add_child(t2)

        var sub := UiKit.label("سفری واژه‌بازی میان شهرهای ایران", 40, UiKit.COL_TEXT_SOFT, "medium")
        var s2 := CenterContainer.new(); s2.add_child(sub)
        v.add_child(s2)

        var vspacer := Control.new()
        vspacer.custom_minimum_size = Vector2(0, 60)
        v.add_child(vspacer)

        var gf := Grandfather.new("welcome", Vector2(520, 520))
        var g2 := CenterContainer.new(); g2.add_child(gf)
        v.add_child(g2)

        var hint := UiKit.label("برای شروع لمس کنید", 30, Color(UiKit.COL_TEXT_SOFT, 0.7), "medium")
        var h2 := CenterContainer.new(); h2.add_child(hint)
        v.add_child(h2)

        # انیمیشن ورود
        icon.pivot_offset = Vector2(180, 180)
        icon.scale = Vector2(0.2, 0.2)
        title.modulate.a = 0.0
        sub.modulate.a = 0.0
        gf.modulate.a = 0.0
        gf.position.y += 80
        var tw := create_tween().set_parallel(true)
        tw.tween_property(icon, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
        tw.tween_property(title, "modulate:a", 1.0, 0.5).set_delay(0.35)
        tw.tween_property(sub, "modulate:a", 1.0, 0.5).set_delay(0.55)
        tw.tween_property(gf, "modulate:a", 1.0, 0.5).set_delay(0.7)
        tw.tween_property(gf, "position:y", gf.position.y - 80, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.7)
        UiKit.breathe(icon, 1.05, 2.4)
        gf.idle_float()

        # ورود خودکار (در حالت تست خودکار غیرفعال)
        if OS.get_environment("CHISTAN_AUTOTEST") != "1":
                var t := get_tree().create_timer(3.0)
                t.timeout.connect(_go_next)
        Sound.sfx("streak")

func _gui_input(ev: InputEvent) -> void:
        if ev is InputEventMouseButton and ev.pressed:
                _go_next()

func _go_next() -> void:
        if _done: return
        _done = true
        Router.go("menu")
