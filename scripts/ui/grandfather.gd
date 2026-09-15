class_name Grandfather
extends Control
## پدربزرگ — قهرمان بازی؛ شناور بودن ملایم، حالت‌های چهره، حباب گفتار

const POSES := {
	"welcome": "res://assets/art/grand_welcome.png",
	"celebrate": "res://assets/art/grand_celebrate.png",
	"think": "res://assets/art/grand_think.png",
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
	if not POSES.has(pose): return
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
	var base := position.y
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", base - 40, 0.18)
	tw.tween_property(self, "position:y", base, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func idle_float() -> void:
	var tw := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(img, "position:y", -14.0, 1.8)
	tw.tween_property(img, "position:y", 0.0, 1.8)

func say(text: String, seconds: float = 3.0) -> void:
	if bubble == null:
		bubble = PanelContainer.new()
		bubble.add_theme_stylebox_override("panel", UiKit.padded(UiKit.pill(UiKit.COL_CREAM, 26, 6, UiKit.COL_GOLD, 3), 16, 24))
		bubble_label = UiKit.label("", 30, UiKit.COL_TEXT, "bold")
		bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bubble_label.custom_minimum_size = Vector2(430, 0)
		bubble.add_child(bubble_label)
		add_child(bubble)
	bubble_label.text = text
	bubble.visible = true
	bubble.reset_size()
	bubble.position = Vector2(size.x - bubble.size.x * 0.75, -bubble.size.y - 6)
	bubble.pivot_offset = bubble.size
	bubble.scale = Vector2(0.4, 0.4)
	bubble.modulate.a = 0.0
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
