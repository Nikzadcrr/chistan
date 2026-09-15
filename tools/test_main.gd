extends Node
## تست جامع هدلس چیستان — صحت داده‌ها، منطق بازی و بارگذاری همه صحنه‌ها
## اجرا: godot --headless --path . res://tools/test_main.tscn

var fails: int = 0
var checks: int = 0

func check(cond: bool, msg: String) -> void:
        checks += 1
        if cond:
                print("  OK  " + msg)
        else:
                fails += 1
                printerr("  XX FAIL: " + msg)

func _ready() -> void:
        print("=== تست جامع چیستان ===")
        await test_data_integrity()
        await test_daily()
        await test_group_logic()
        await test_save()
        await test_screens()
        print("=========================================")
        print("نتیجه: %d بررسی، %d خطا" % [checks, fails])
        print("ALL TESTS PASSED" if fails == 0 else "TESTS FAILED")
        get_tree().quit(1 if fails > 0 else 0)

func _can_form(w: String, letters: Array) -> bool:
        return Data.can_form(w, letters)

## ---------------------------------------- داده‌ها
func test_data_integrity() -> void:
        print("--- دیکشنری و شهرها ---")
        check(Data.words.size() >= 500, "دیکشنری ≥ ۵۰۰ کلمه (فعلی: %d)" % Data.words.size())
        check(Data.levels.size() == 100, "تعداد مراحل = ۱۰۰ (فعلی: %d)" % Data.levels.size())
        check(Data.cities.size() == 6, "تعداد شهرها = ۶")
        var ids := {}
        for c in Data.cities:
                ids[c["id"]] = true
                check(c.has("name") and c.has("color") and c.has("music"), "شهر %s کامل است" % str(c.get("name")))
        # پوشش مراحل شهرها
        var covered := 0
        for c in Data.cities:
                var a: int = c["levels"][0]
                var b: int = c["levels"][1]
                covered += (b - a + 1)
        check(covered == 100, "پوشش بازه‌های شهرها = ۱۰۰ (فعلی: %d)" % covered)

        print("--- صحت ۱۰۰ مرحله ---")
        for lv in Data.levels:
                var sid: String = "مرحله %d" % int(lv["id"])
                var letters: Array = lv["letters"]
                # ۱) حروف چرخ = دقیقاً حروف ریشه (تکرار مجاز است، مثل کاشی‌های واقعی)
                var pool := {}
                for l in letters:
                        pool[l] = pool.get(l, 0) + 1
                var root_ms := {}
                for ch in lv["root"]:
                        root_ms[ch] = root_ms.get(ch, 0) + 1
                check(pool == root_ms, sid + ": حروف چرخ با ریشه هم‌خوان")
                # ۲) همه هدف‌ها قابل ساخت و در دیکشنری
                for t in lv["targets"]:
                        check(Data.is_word_valid(t), sid + ": «" + t + "» در دیکشنری")
                        check(_can_form(t, letters), sid + ": «" + t + "» از حروف قابل ساخت")
                # ۳) چیدمان جدول
                var layout: Dictionary = lv["layout"]
                var cell_owner: Dictionary = {}
                var min_r: int = layout["min_r"]
                var max_r: int = layout["max_r"]
                var min_c: int = layout["min_c"]
                var max_c: int = layout["max_c"]
                var word_count: int = layout["words"].size()
                check(word_count >= 2, sid + ": حداقل ۲ کلمه در جدول")
                for wd in layout["words"]:
                        var w: String = wd["w"]
                        var cells: Array = wd["cells"]
                        check(w.length() == cells.size(), sid + ": «" + w + "» طول سلول‌ها هم‌خوان")
                        for i in w.length():
                                var p: Vector2i = Vector2i(cells[i][0], cells[i][1])
                                check(p.x >= min_r and p.x <= max_r and p.y >= min_c and p.y <= max_c, sid + ": سلول «" + w + "» داخل محدوده")
                                if cell_owner.has(p):
                                        check(cell_owner[p]["ch"] == w[i], sid + ": تداخل هم‌خوان در " + str(p))
                                        cell_owner[p]["n"] += 1
                                else:
                                        cell_owner[p] = {"ch": w[i], "n": 1}
                # ۴) اتصال کامل اجزا (یک قطعه واحد)
                var adj: Dictionary = {}
                for p in cell_owner:
                        adj[p] = []
                for p in cell_owner:
                        for d in [Vector2i(1, 0), Vector2i(0, 1)]:
                                var q: Vector2i = p + d
                                if adj.has(q):
                                        adj[p].append(q)
                                        adj[q].append(p)
                if adj.size() > 0:
                        var seen := {adj.keys()[0]: true}
                        var stack: Array = [adj.keys()[0]]
                        while stack.size() > 0:
                                var cur: Vector2i = stack.pop_back()
                                for nb in adj[cur]:
                                        if not seen.has(nb):
                                                seen[nb] = true
                                                stack.append(nb)
                        check(seen.size() == adj.size(), sid + ": جدول به‌هم‌پیوسته")
                # ۵) همه کلمات چیدمان در هدف‌ها
                for wd in layout["words"]:
                        check(lv["targets"].has(wd["w"]), sid + ": «" + wd["w"] + "» جزو هدف‌ها")
                # ۶) کلمات پنهان
                for b in lv["bonus"]:
                        check(Data.is_word_valid(b), sid + ": بنوس «" + b + "» معتبر")
                        check(_can_form(b, letters), sid + ": بنوس «" + b + "» قابل ساخت")
                        check(not lv["targets"].has(b), sid + ": بنوس «" + b + "» تکراری نیست")

## ---------------------------------------- چالش روزانه
func test_daily() -> void:
        print("--- چالش روزانه ---")
        var ds := Save.today_str()
        var letters: Array = Data.daily_letters(ds)
        check(letters.size() >= 5 and letters.size() <= 7, "حروف روزانه ۵ تا ۷ حرف")
        var best: Array = Data.daily_best_words(letters)
        check(best.size() >= 3, "کلمات قابل ساخت روزانه ≥ ۳ (فعلی: %d)" % best.size())
        Game.start_daily()
        check(Game.mode == Game.Mode.DAILY, "حالت روزانه فعال شد")
        check(Game.daily_letters.size() == letters.size(), "حروف روزانه در Game ذخیره شد")

## ---------------------------------------- حالت جمعی / لیگ
func test_group_logic() -> void:
        print("--- حالت جمعی و لیگ ---")
        var players := [
                {"name": "مامان", "color": "#e8862e"},
                {"name": "بابا", "color": "#4e9a51"},
        ]
        Game.start_group({"players": players, "rounds": 2, "seconds_per_turn": 30, "is_league": false})
        check(Game.group["rounds"] == 2, "دورهای گروه = ۲")
        check(Game.group["scores"].size() == 2, "امتیاز دو بازیکن ساخته شد")
        check(Game.group["letters"].size() >= 4, "حروف نوبت ساخته شد")
        Game.group_turn_done(120, ["کتاب", "کوه"])
        check(Game.group["scores"][0] == 120, "امتیاز بازیکن اول ثبت شد")
        var rk: Array = Game.group_ranking()
        check(rk.size() == 2, "رتبه‌بندی ساخته شد")
        check(rk[0]["name"] == "مامان", "صدر جدول درست است")
        # پایان مسابقه
        for i in 4:
                Game.group_turn_done(10, [])
        check(Game.group["finished"] == true, "مسابقه پایان یافت")
        var champ: Dictionary = Game.group_champion()
        check(champ.get("name", "") == "مامان", "قهرمان درست است")

## ---------------------------------------- ذخیره‌سازی
func test_save() -> void:
        print("--- ذخیره‌سازی ---")
        var before: int = Save.data.get("coins", 0)
        Save.add_coins(50)
        check(Save.data.get("coins", 0) == before + 50, "سکه اضافه شد")
        check(Save.try_spend(20), "خرید موفق")
        check(not Save.try_spend(99999999), "خرید گران ناموفق")
        Save.save_now()
        check(FileAccess.file_exists(Save.PATH), "فایل ذخیره ساخته شد")
        # ثبت نتیجه مرحله
        Save.set_level_result(1, 3)
        check(Save.level_stars(1) == 3, "ستاره مرحله ثبت شد")
        check(Save.is_level_unlocked(2), "مرحله بعد باز شد")

## ---------------------------------------- بارگذاری صحنه‌ها
func test_screens() -> void:
        print("--- بارگذاری ۱۲ صحنه ---")
        var ui_root: Control = Control.new()
        ui_root.name = "TestUIRoot"
        ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
        get_tree().root.add_child(ui_root)
        Router.setup(ui_root)
        check(Router.root == ui_root, "راه‌انداز Router آماده شد")
        Game.start_level(1)
        for screen in Router.SCREENS.keys():
                await _test_screen(screen)
        ui_root.queue_free()

func _test_screen(screen: String) -> void:
        var script: GDScript = load(Router.SCREENS[screen])
        if script == null:
                check(false, "صحنه " + screen + " لود نشد")
                return
        var node: Control = script.new()
        node.name = "Test_" + screen
        Router.root.add_child(node)
        await get_tree().process_frame
        await get_tree().process_frame
        var alive := is_instance_valid(node)
        check(alive, "صحنه " + screen + " بدون خطا بارگذاری شد")
        if alive:
                node.queue_free()
        await get_tree().process_frame
