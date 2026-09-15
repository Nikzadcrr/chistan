class_name Toast
extends Control
## پیام‌های شناور (+سکه، بونوس، راهنما) — سبک آمیرزا اما شیک‌تر

static func show_msg(parent: Control, text: String, color: Color = UiKit.COL_TEXT, size: int = 40, at := Vector2(-1, -1)) -> void:
        var l := UiKit.label(text, size, Color.WHITE, "black")
        var sb := UiKit.pill(color, 30, 8)
        UiKit.padded(sb, 14, 30)
        var pc := PanelContainer.new()
        pc.add_theme_stylebox_override("panel", sb)
        pc.add_child(l)
        pc.z_index = 50
        pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
        parent.add_child(pc)
        pc.reset_size()
        var vp := parent.get_viewport_rect().size
        var target := Vector2(vp.x / 2.0 - pc.size.x / 2.0, vp.y * 0.32)
        if at.x >= 0:
                target = at - pc.size / 2.0
        pc.position = target
        pc.modulate.a = 0.0
        pc.scale = Vector2(0.7, 0.7)
        pc.pivot_offset = pc.size / 2.0
        var tw := pc.create_tween().set_parallel(true)
        tw.tween_property(pc, "modulate:a", 1.0, 0.18)
        tw.tween_property(pc, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tw.chain().tween_interval(0.8)
        tw.chain().tween_property(pc, "position:y", pc.position.y - 70, 0.4)
        tw.parallel().tween_property(pc, "modulate:a", 0.0, 0.4)
        tw.chain().tween_callback(pc.queue_free)

static func coin_pop(parent: Control, amount: int, at: Vector2) -> void:
        show_msg(parent, "+%s" % UiKit.fa_num(amount), UiKit.COL_ORANGE, 38, at)
