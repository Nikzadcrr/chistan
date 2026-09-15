class_name Grandfather
extends Control
## پدربزرگ — قهرمان بازی؛ شناور بودن ملایم، حالت‌های چهره، حباب گفتار هوشمند

const POSES := {
	"welcome": "res://assets/art/grand_welcome.webp",
	"celebrate": "res://assets/art/grand_celebrate.webp",
	"think": "res://assets/art/grand_think.webp",
}

var img: TextureRect
var bubble: PanelContainer
var bubble_label: Label
var _pose := "welcome"

func _init(pose: String = "welcome", display_size := Vector2(420, 420)) -> void:
	custom_minimum_size = display_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	img = TextureRect.new()
	img.texture = load(POSES.get(pose, POSES.welcome))
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.set_anchors_preset(Control.PRESET_FULL_RECT)
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(img)
	_pose = pose

func set_pose(pose: String) -> void:
	if not POSES.has(pose):
		return
	_pose = pose
	var tw := create_tween()
	tw.tween_property(img, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func(): img.texture = load(POSES[pose]))
	tw.tween_property(img, "modulate:a", 1.0, 0.2)

func celebrate() -> void:
	set_pose("celebrate")
	_jump()

func jump() -> void:
	_jump()

func _jump() -> void:
	## پرش — روی تصویر داخلی (امن برای فرزندِ کانتینر)
	var base := img.position.y
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(img, "position:y", base - 40.0, 0.18)
	tw.tween_property(img, "position:y", base, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func idle_float() -> void:
	var tw := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(img, "position:y", -14.0, 1.8)
	tw.tween_property(img, "position:y", 0.0, 1.8)

func _process(_delta: float) -> void:
	## حباب همیشه درست بالای پدربزرگ می‌نشیند — حتی پس از تغییر چیدمان
	if bubble == null or not is_instance_valid(bubble) or not bubble.visible:
		return
	var vw := get_viewport_rect().size.x
	var gx := global_position.x + (size.x - bubble.size.x) * 0.5
	gx = clampf(gx, 10.0, maxf(10.0, vw - bubble.size.x - 10.0))
	var lx := gx - global_position.x
	var ly := -bubble.size.y - 12.0
	if global_position.y + ly < 10.0:
		ly = size.y + 12.0
	bubble.position = Vector2(lx, ly)

func say(text: String, seconds: float = 3.0) -> void:
	if bubble == null:
		bubble = PanelContainer.new()
		bubble.add_theme_stylebox_override("panel", UiKit.padded(UiKit.pill(UiKit.COL_CREAM, 26, 6, UiKit.COL_GOLD, 3), 16, 24))
		bubble_label = UiKit.label("", 30, UiKit.COL_TEXT, "bold")
		bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bubble_label.custom_minimum_size = Vector2(430, 0)
		bubble.add_child(bubble_label)
	bubble_label.text = text
	if bubble.get_parent() == null:
		bubble.z_index = 45
		bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bubble)
	bubble.visible = true
	bubble.modulate.a = 0.0
	bubble.reset_size()
	# جای‌گذاری محلی: بالای پدربزرگ؛ اگر جا نبود، پایین؛ همیشه داخل کادر صفحه
	var vw := get_viewport_rect().size.x
	var gx := global_position.x + (size.x - bubble.size.x) * 0.5
	gx = clampf(gx, 10.0, maxf(10.0, vw - bubble.size.x - 10.0))
	var lx := gx - global_position.x
	var ly := -bubble.size.y - 12.0
	if global_position.y + ly < 10.0:
		ly = size.y + 12.0
	bubble.position = Vector2(lx, ly)
	bubble.pivot_offset = Vector2(bubble.size.x * 0.5, bubble.size.y)
	bubble.scale = Vector2(0.4, 0.4)
	# موقعیت نهایی پس از چیدمان — در هر فریم بازتنظیم می‌شود
	bubble.set_meta("fresh", true)
	var tw := bubble.create_tween().set_parallel(true)
	tw.tween_property(bubble, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(bubble, "modulate:a", 1.0, 0.2)
	if seconds > 0:
		var t := get_tree().create_timer(seconds)
		t.timeout.connect(func():
			if is_instance_valid(bubble):
				var tw2 := bubble.create_tween()
				tw2.tween_property(bubble, "modulate:a", 0.0, 0.3)
				tw2.tween_callback(func(): bubble.visible = false)
		)
