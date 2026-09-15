extends Node
## Router — جابه‌جایی بین صفحه‌ها با محو/لغزش نرم

var root: Control
var current: Control = null
var _fader: ColorRect
var _busy := false

const SCREENS := {
	"splash": "res://scripts/screens/splash.gd",
	"menu": "res://scripts/screens/main_menu.gd",
	"city_map": "res://scripts/screens/city_map.gd",
	"game": "res://scripts/screens/game_screen.gd",
	"daily": "res://scripts/screens/daily_challenge.gd",
	"party_setup": "res://scripts/screens/party_setup.gd",
	"party_game": "res://scripts/screens/party_game.gd",
	"party_results": "res://scripts/screens/party_results.gd",
	"league": "res://scripts/screens/family_league.gd",
	"shop": "res://scripts/screens/shop.gd",
	"settings": "res://scripts/screens/settings.gd",
	"achievements": "res://scripts/screens/achievements.gd",
}

func setup(main_root: Control) -> void:
	root = main_root
	root.theme = UiKit.theme()
	_fader = ColorRect.new()
	_fader.color = Color(UiKit.COL_BG, 0.0)
	_fader.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fader.z_index = 100
	root.add_child(_fader)

func go(screen: String, fade: float = 0.28) -> void:
	if _busy or not SCREENS.has(screen):
		return
	_busy = true
	Sound.sfx("whoosh", 1.0, -8.0)
	var tw := create_tween()
	tw.tween_property(_fader, "color:a", 1.0, fade)
	await tw.finished
	if current != null and is_instance_valid(current):
		current.queue_free()
		await current.tree_exited
	var script: GDScript = load(SCREENS[screen])
	current = script.new()
	current.name = screen.to_pascal_case()
	current.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(current)
	root.move_child(_fader, root.get_child_count() - 1)
	var tw2 := create_tween()
	tw2.tween_property(_fader, "color:a", 0.0, fade * 1.2)
	_busy = false

## برگشت هوشمند به نقشه/منو
func back_target_for_mode() -> String:
	match Game.mode:
		Game.Mode.CLASSIC: return "city_map"
		Game.Mode.DAILY: return "daily"
		_: return "menu"
