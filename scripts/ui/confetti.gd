class_name Confetti
extends CPUParticles2D
## جشن کانفتی — انفجار ذرات رنگی

const COLORS := [Color("e8862e"), Color("f2b33d"), Color("4e9a51"), Color("2fa8a0"), Color("d95a4e"), Color("fffaf0")]

static func burst(parent: Node, at: Vector2, amount: int = 90) -> void:
        var p := Confetti.new()
        p.position = at
        p.z_index = 60
        p.emitting = false
        p.one_shot = true
        p.amount = amount
        p.lifetime = 1.6
        p.explosiveness = 1.0
        p.direction = Vector2(0, -1)
        p.spread = 70.0
        p.gravity = Vector2(0, 900)
        p.initial_velocity_min = 500.0
        p.initial_velocity_max = 1100.0
        p.angular_velocity_min = -540.0
        p.angular_velocity_max = 540.0
        p.scale_amount_min = 5.0
        p.scale_amount_max = 11.0
        # محو شدن در طول عمر
        var g := Gradient.new()
        g.set_color(0, Color.WHITE)
        g.set_color(1, Color(1, 1, 1, 0))
        p.color_ramp = g
        # رنگ‌های شاد جشن به‌صورت تصادفی برای هر ذره
        var gi := Gradient.new()
        for i in COLORS.size():
                gi.add_point(float(i) / (COLORS.size() - 1), COLORS[i])
        p.color_initial_ramp = gi
        parent.add_child(p)
        p.emitting = true
        var t := p.get_tree().create_timer(2.2)
        t.timeout.connect(p.queue_free)
