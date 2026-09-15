extends Control
## لیگ خانوادگی — ۵/۱۰/۲۰ دور و جدول رکوردها

var _players: Array = []
var _rounds := 5

func _ready() -> void:
        Sound.music("menu")
        var bg := ColorRect.new()
        bg.color = UiKit.COL_BG
        bg.set_anchors_preset(Control.PRESET_FULL_RECT)
        add_child(bg)

        var hud := Hud.new()
        hud.setup("لیگ خانوادگی", true, func(): Router.go("menu"))
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
        v.add_theme_constant_override("separation", 18)
        scroll.add_child(v)

        v.add_child(UiKit.label("رقابت جدی با خانواده!", 44, UiKit.COL_ORANGE, "black"))
        v.add_child(UiKit.label("دورهای بیشتر = رکوردهای بزرگ‌تر", 28, UiKit.COL_TEXT_SOFT))

        # انتخاب دورها
        var rr := HBoxContainer.new()
        rr.alignment = BoxContainer.ALIGNMENT_CENTER
        rr.add_theme_constant_override("separation", 14)
        v.add_child(rr)
        rr.add_child(UiKit.label("دورها:", 34, UiKit.COL_TEXT, "bold"))
        var group := HBoxContainer.new()
        group.add_theme_constant_override("separation", 10)
        rr.add_child(group)
        for r in [5, 10, 20]:
                var rb := UiKit.button(UiKit.fa_num(r), UiKit.COL_GOLD if r == 5 else UiKit.COL_BG_SOFT, 34, UiKit.COL_TEXT if r == 5 else UiKit.COL_TEXT)
                rb.custom_minimum_size = Vector2(120, 80)
                group.add_child(rb)
                rb.pressed.connect(func():
                        _rounds = r
                        Sound.sfx("click")
                        for i in group.get_child_count():
                                var bb: Button = group.get_child(i)
                                var sel: bool = [5, 10, 20][i] == r
                                bb.add_theme_stylebox_override("normal", UiKit.pill(UiKit.COL_GOLD if sel else UiKit.COL_BG_SOFT, 44, 8 if sel else 0))
                )

        # بازیکن‌ها (همان موتور حالت جمعی)
        v.add_child(UiKit.label("بازیکن‌ها (۲ تا ۸ نفر)", 34, UiKit.COL_TEXT, "bold"))
        var list := VBoxContainer.new()
        list.add_theme_constant_override("separation", 12)
        v.add_child(list)
        _players = [{"name": "", "color": 0}, {"name": "", "color": 1}]
        _add_row(list, 0)
        _add_row(list, 1)

        # جدول رکوردها
        var rec: Dictionary = Save.data["records"]
        var rec_panel := PanelContainer.new()
        rec_panel.add_theme_stylebox_override("panel", UiKit.padded(UiKit.pill(UiKit.COL_CREAM, 30, 8), 24, 30))
        v.add_child(rec_panel)
        var rv := VBoxContainer.new()
        rv.add_theme_constant_override("separation", 8)
        rec_panel.add_child(rv)
        rv.add_child(UiKit.label("رکوردهای خانوادگی", 38, UiKit.COL_TEXT, "black"))
        var rows := [
                ["بلندترین کلمه", rec.get("longest_word", "—") + (" (%s حرف)" % UiKit.fa_num(rec.get("longest_len", 0)) if rec.get("longest_len", 0) > 0 else "")],
                ["بیشترین امتیاز یک بازی", UiKit.fa_num(rec.get("high_score", 0))],
                ["بیشترین قهرمانی", "%s (%s بار)" % [rec.get("most_wins", "—"), UiKit.fa_num(rec.get("wins", 0))]],
                ["بهترین نوبت", UiKit.fa_num(rec.get("best_round", 0))],
        ]
        for pair in rows:
                var h := HBoxContainer.new()
                rv.add_child(h)
                var l1 := UiKit.label(pair[0], 28, UiKit.COL_TEXT_SOFT)
                l1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
                h.add_child(l1)
                h.add_child(UiKit.label(pair[1], 30, UiKit.COL_TEXT, "bold"))

        var start := UiKit.button("شروع لیگ", UiKit.COL_GOLD, 48, UiKit.COL_TEXT)
        start.custom_minimum_size = Vector2(480, 110)
        var sc := CenterContainer.new(); sc.add_child(start)
        v.add_child(sc)
        start.pressed.connect(func():
                Game.start_group({"players": _collect_names(), "rounds": _rounds, "is_league": true, "seconds_per_turn": 30})
                Router.go("party_game")
        )

func _add_row(list: VBoxContainer, idx: int) -> void:
        var row := HBoxContainer.new()
        row.name = "Row%d" % idx
        row.add_theme_constant_override("separation", 12)
        list.add_child(row)
        var avatar := Panel.new()
        avatar.custom_minimum_size = Vector2(70, 70)
        avatar.size = Vector2(70, 70)
        avatar.add_theme_stylebox_override("panel", UiKit.pill(Color(Game.AVATAR_COLORS[_players[idx]["color"]]), 35, 3))
        row.add_child(avatar)
        var edit := LineEdit.new()
        edit.placeholder_text = "نام بازیکن %s" % UiKit.fa_num(idx + 1)
        edit.max_length = 12
        edit.add_theme_font_override("font", UiKit.font("semibold"))
        edit.add_theme_font_size_override("font_size", 34)
        edit.custom_minimum_size = Vector2(0, 80)
        edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        edit.add_theme_stylebox_override("normal", UiKit.padded(UiKit.pill(UiKit.COL_CREAM, 24, 4), 12, 20))
        edit.add_theme_stylebox_override("focus", UiKit.padded(UiKit.pill(UiKit.COL_CREAM, 24, 4, UiKit.COL_GOLD, 3), 12, 20))
        edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
        row.add_child(edit)
        edit.text_changed.connect(func(t: String): _players[idx]["name"] = t)
        var color_btn := UiKit.button("رنگ", UiKit.COL_WOOD, 26)
        color_btn.custom_minimum_size = Vector2(100, 72)
        row.add_child(color_btn)
        color_btn.pressed.connect(func():
                _players[idx]["color"] = (_players[idx]["color"] + 1) % Game.AVATAR_COLORS.size()
                avatar.add_theme_stylebox_override("panel", UiKit.pill(Color(Game.AVATAR_COLORS[_players[idx]["color"]]), 35, 3))
                Sound.sfx("pop")
        )
        var del := UiKit.button("×", UiKit.COL_RED, 32)
        del.custom_minimum_size = Vector2(76, 72)
        row.add_child(del)
        del.pressed.connect(func():
                if _players.size() <= 2:
                        Toast.show_msg(self, "حداقل دو بازیکن!", UiKit.COL_RED)
                        return
                _players.remove_at(idx)
                for ch in list.get_children():
                        ch.queue_free()
                for i in _players.size():
                        _add_row(list, i)
                Sound.sfx("error", 1.2, -6.0)
        )
        var add_row := HBoxContainer.new()
        list.add_child(add_row)
        var add := UiKit.button("+ افزودن بازیکن", UiKit.COL_TURQ, 30)
        add.custom_minimum_size = Vector2(320, 76)
        add_row.add_child(add)
        add.pressed.connect(func():
                if _players.size() >= 8:
                        Toast.show_msg(self, "حداکثر ۸ بازیکن!", UiKit.COL_RED)
                        return
                _players.append({"name": "", "color": _players.size() % Game.AVATAR_COLORS.size()})
                _add_row(list, _players.size() - 1)
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
