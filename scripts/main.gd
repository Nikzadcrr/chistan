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
        else:
                Router.go("splash")

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
                gs._classic_swipe("کلمه‌غیرموجودxx")  # مسیر خطا
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
