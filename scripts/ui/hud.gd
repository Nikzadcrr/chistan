class_name Hud
extends PanelContainer
## نوار بالای صفحه — دکمه بازگشت، عنوان، سکه و ستاره

var back_btn: Button
var title_label: Label
var coin_label: Label
var star_label: Label

func setup(title: String, show_back := true, on_back: Callable = Callable()) -> void:
	add_theme_stylebox_override("panel", UiKit.padded(UiKit.pill(Color(UiKit.COL_CREAM, 0.92), 34, 8), 10, 12))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	add_child(h)

	back_btn = UiKit.button("بازگشت", UiKit.COL_WOOD, 32)
	back_btn.custom_minimum_size = Vector2(150, 72)
	h.add_child(back_btn)
	if show_back and on_back.is_valid():
		back_btn.pressed.connect(on_back)
	elif not show_back:
		back_btn.visible = false

	title_label = UiKit.label(title, 40, UiKit.COL_TEXT, "black")
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(title_label)

	var coin_chip := UiKit.chip("0", UiKit.icon_path("coin"))
	coin_label = coin_chip.get_child(0).get_child(1)
	coin_label.name = "CoinLabel"
	h.add_child(coin_chip)

	var star_chip := UiKit.chip("0", UiKit.icon_path("star"))
	star_label = star_chip.get_child(0).get_child(1)
	star_label.name = "StarLabel"
	h.add_child(star_chip)
	refresh()

func refresh() -> void:
	coin_label.text = UiKit.fa_num(Save.coins())
	star_label.text = UiKit.fa_num(Save.total_stars())

func coin_bounce() -> void:
	var chip := coin_label.get_parent().get_parent()
	chip.pivot_offset = chip.size / 2.0
	var tw := chip.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	chip.scale = Vector2(1.2, 1.2)
	tw.tween_property(chip, "scale", Vector2.ONE, 0.3)
