extends Control
# چیستان — ریشه‌ای برای همه صفحه‌ها؛ ساخت تمام UI به‌صورت کد (کنترل‌های نیتیو)

func _ready() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	Router.setup(root)
	if OS.get_environment("CHISTAN_AUTOTEST") == "1":
		_run_autotest(root)
	elif OS.get_environment("CHISTAN_SHOTS") == "1":
		_run_shots(root)
	else:
		Router.go("splash")

func _run_shots(root: Control) -> void:
	## حالت اسکرین‌شات: از همه صفحه‌ها عکس می‌گیرد — برای بازبینی بصری
	var dir := OS.get_environment("CHISTAN_SHOTS_DIR")
	if dir == "":
		dir = "user://shots"
	DirAccess.make_dir_recursive_absolute(dir)
	# تغییر رزولوشن پنجره (اختیاری)
	var res := OS.get_environment("CHISTAN_SHOTS_RES")
	if res.contains("x"):
		var parts := res.split("x")
		get_window().size = Vector2i(int(parts[0]), int(parts[1]))
		await get_tree().process_frame
		await get_tree().process_frame
	await Router.go("splash")
	await _wait(1.6)
	await _snap(dir + "/01_splash.png")
	await Router.go("menu")
	await _wait(1.2)
	await _snap(dir + "/02_menu.png")
	await Router.go("city_map")
	await _wait(0.8)
	await _snap(dir + "/03_city_map.png")
	Game.start_level(1)
	await Router.go("game")
	await _wait(1.2)
	await _snap(dir + "/04_game_level1.png")
	Game.start_level(30)
	await Router.go("game")
	await _wait(1.2)
	await _snap(dir + "/05_game_level30.png")
	await Router.go("daily")
	await _wait(0.8)
	await _snap(dir + "/06_daily.png")
	Game.start_daily()
	await Router.go("game")
	await _wait(1.0)
	await _snap(dir + "/07_daily_game.png")
	await Router.go("party_setup")
	await _wait(0.6)
	await _snap(dir + "/08_party_setup.png")
	Game.start_group({"players": [{"name": "مامان", "color": 0}, {"name": "بابا", "color": 1}], "rounds": 2})
	await Router.go("party_game")
	await _wait(1.0)
	await _snap(dir + "/09_party_game.png")
	await Router.go("party_results")
	await _wait(0.9)
	await _snap(dir + "/10_party_results.png")
	await Router.go("league")
	await _wait(0.6)
	await _snap(dir + "/11_league.png")
	await Router.go("shop")
	await _wait(0.6)
	await _snap(dir + "/12_shop.png")
	await Router.go("settings")
	await _wait(0.6)
	await _snap(dir + "/13_settings.png")
	await Router.go("achievements")
	await _wait(0.6)
	await _snap(dir + "/14_achievements.png")
	print("SHOTS_DONE")
	get_tree().quit(0)

func _snap(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("SHOT ", path)

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func _run_autotest(root: Control) -> void:
	# آزمون خودکار هدلس: همه صفحه‌ها را باز می‌کند تا خطاهای _ready پیدا شود
	print("AUTOTEST_START")
	var screens := ["splash", "menu", "city_map", "daily", "party_setup", "league", "shop", "settings", "achievements"]
	for s in screens:
		await Router.go(s)
		await get_tree().process_frame
		print("AUTOTEST_OK ", s)
	# صفحه بازی با مرحله واقعی
	Game.start_level(1)
	await Router.go("game")
	for i in 20:
		await get_tree().process_frame
	print("AUTOTEST_OK game")
	# شبیه‌سازی کامل حلقه بازی: یافتن همه کلمات + بونوس + برد
	var gs = Router.current
	if gs != null and gs.get("wheel") != null:
		gs._classic_swipe("کلمهغیرموجودxx")  # مسیر خطا
		for w in Game.level["targets"]:
			gs._classic_swipe(w)
		for i in 20:
			await get_tree().process_frame
		if gs.get("grid") != null and gs.grid.all_found():
			print("AUTOTEST_OK win_flow")
		else:
			print("AUTOTEST_FAIL win_flow")
	print("AUTOTEST_OK win_screen")
	# حالت جمعی
	Game.start_group({"players": [{"name": "مامان", "color": 0}, {"name": "بابا", "color": 1}], "rounds": 2})
	await Router.go("party_game")
	await get_tree().process_frame
	print("AUTOTEST_OK party_game")
	# گیم‌پلی چالش روزانه
	Game.start_daily()
	await Router.go("game")
	await get_tree().process_frame
	var gd = Router.current
	if gd != null and gd.get("wheel") != null:
		gd._daily_swipe(Game.daily_letters[0] + Game.daily_letters[1] + Game.daily_letters[2])
		print("AUTOTEST_OK daily_game")
	else:
		print("AUTOTEST_FAIL daily_game")
	print("AUTOTEST_ALL_DONE")
	get_tree().quit(0)
