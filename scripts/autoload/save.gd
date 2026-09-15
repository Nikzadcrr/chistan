extends Node
## Save — ذخیره/بارگذاری وضعیت بازی (user://save.json)

signal coins_changed
signal achievements_changed(newly: Array)

const PATH := "user://save.json"

var data: Dictionary = {}

func _ready() -> void:
        _default()
        load_now()
        _process_streak()

func _default() -> void:
        data = {
                "version": 1,
                "coins": 120,
                "levels": {},          # id -> {"stars": int}
                "current_level": 1,
                "words_found": 0,
                "bonus_found": 0,
                "coins_earned_total": 0,
                "daily_done": 0,
                "daily": {"last": "", "streak": 0, "best_streak": 0},
                "achievements": {},    # id -> claimed(bool)
                "inventory": {"hint": 1, "reveal": 1, "eraser": 0, "tea": 1},
                "themes_owned": ["cream"],
                "theme": "cream",
                "records": {"longest_word": "", "longest_len": 0, "high_score": 0, "most_wins": "", "wins": 0, "best_round": 0},
                "settings": {"music": 0.8, "sfx": 0.9, "haptics": true},
                "played_days": {}
        }

func load_now() -> void:
        if FileAccess.file_exists(PATH):
                var f := FileAccess.open(PATH, FileAccess.READ)
                var parsed: Variant = JSON.parse_string(f.get_as_text())
                if parsed is Dictionary and parsed.get("version", 0) == 1:
                        # ادغام با پیش‌فرض‌ها (برای سازگاری آینده)
                        for k in parsed:
                                data[k] = parsed[k]

func save_now() -> void:
        var f := FileAccess.open(PATH, FileAccess.WRITE)
        if f:
                f.store_string(JSON.stringify(data))
                f.close()

# ---------- سکه و ستاره ----------
func coins() -> int:
        return int(data.get("coins", 0))

func add_coins(n: int) -> void:
        data["coins"] = int(data.get("coins", 0)) + n
        if n > 0:
                data["coins_earned_total"] = int(data.get("coins_earned_total", 0)) + n
        coins_changed.emit()
        save_now()

func try_spend(n: int) -> bool:
        if coins() >= n:
                add_coins(-n)
                return true
        return false

func total_stars() -> int:
        var s := 0
        for k in data.get("levels", {}):
                s += int(data["levels"][k].get("stars", 0))
        return s

func level_stars(id: int) -> int:
        var lv: Dictionary = data.get("levels", {}).get(str(id), {})
        return int(lv.get("stars", 0))

func is_level_unlocked(id: int) -> bool:
        if id == 1:
                return true
        return level_stars(id - 1) > 0

func set_level_result(id: int, stars: int) -> bool:
        ## برمی‌گرداند آیا رکورد بهبود یافته است
        var key := str(id)
        var prev := level_stars(id)
        data["levels"][key] = {"stars": max(prev, stars)}
        if id == int(data.get("current_level", 1)) and stars > 0 and id < 100:
                data["current_level"] = id + 1
        save_now()
        return stars > prev

func current_level() -> int:
        return int(data.get("current_level", 1))

# ---------- آمار ----------
func add_word_found(w: String, is_bonus: bool) -> void:
        data["words_found"] = int(data.get("words_found", 0)) + 1
        if is_bonus:
                data["bonus_found"] = int(data.get("bonus_found", 0)) + 1
        var rec: Dictionary = data["records"]
        if w.length() > int(rec.get("longest_len", 0)):
                rec["longest_word"] = w
                rec["longest_len"] = w.length()
        save_now()
        check_achievements()

func add_daily_done() -> void:
        data["daily_done"] = int(data.get("daily_done", 0)) + 1
        save_now()
        check_achievements()

func add_group_result(won: bool, champion_name: String, round_best: int) -> void:
        var rec: Dictionary = data["records"]
        if won:
                rec["wins"] = int(rec.get("wins", 0)) + 1
                rec["most_wins"] = champion_name
        rec["best_round"] = max(int(rec.get("best_round", 0)), round_best)
        save_now()
        check_achievements()

# ---------- چالش روزانه / استریک ورود ----------
func today_str() -> String:
        return Time.get_date_string_from_system()  # YYYY-MM-DD

func _process_streak() -> void:
        var today := today_str()
        if not data["played_days"].has(today):
                data["played_days"][today] = true
                var yesterday := _yesterday_str()
                if data["daily"].get("last", "") == yesterday:
                        data["daily"]["streak"] = int(data["daily"].get("streak", 0)) + 1
                else:
                        data["daily"]["streak"] = 1
                data["daily"]["last"] = today
                data["daily"]["best_streak"] = max(int(data["daily"].get("best_streak", 0)), int(data["daily"]["streak"]))
                save_now()
                check_achievements()

func _yesterday_str() -> String:
        var t := Time.get_unix_time_from_system() - 86400
        var dt := Time.get_datetime_dict_from_unix_time(int(t))
        return "%04d-%02d-%02d" % [dt.year, dt.month, dt.day]

# ---------- دستاوردها ----------
func _achievement_progress(a: Dictionary) -> int:
        match a["type"]:
                "words": return int(data.get("words_found", 0))
                "levels":
                        var c := 0
                        for k in data.get("levels", {}):
                                if int(data["levels"][k].get("stars", 0)) > 0: c += 1
                        return c
                "stars": return total_stars()
                "bonus": return int(data.get("bonus_found", 0))
                "coins": return int(data.get("coins_earned_total", 0))
                "streak": return int(data["daily"].get("best_streak", 0))
                "daily": return int(data.get("daily_done", 0))
                "word7": return 1 if int(data["records"].get("longest_len", 0)) >= 7 else 0
                "party_win", "league_win":
                        return 1 if int(data["records"].get("wins", 0)) > 0 else 0
        return 0

func check_achievements() -> Array:
        ## دستاوردهای تکمیل‌شده اما ادعانشده را برمی‌گرداند
        var newly: Array = []
        for a in Data.achievements:
                if data["achievements"].has(a["id"]):
                        continue
                if _achievement_progress(a) >= int(a["goal"]):
                        data["achievements"][a["id"]] = false  # تکمیل شده، ادعا نشده
                        newly.append(a)
        if newly.size() > 0:
                data["achievements_changed_at"] = today_str()
                save_now()
                achievements_changed.emit(newly)
        return newly

func claim_achievement(id: String) -> int:
        if data["achievements"].get(id, true) == false:
                data["achievements"][id] = true
                var a := Data.achievement_by_id(id)
                var reward := int(a.get("reward", 0))
                add_coins(reward)
                return reward
        return 0

func unclaimed_achievements() -> Array:
        var out: Array = []
        for a in Data.achievements:
                if data["achievements"].get(a["id"], true) == false:
                        out.append(a)
        return out

# ---------- انبار ----------
func inventory(id: String) -> int:
        return int(data.get("inventory", {}).get(id, 0))

func use_item(id: String) -> bool:
        if inventory(id) > 0:
                data["inventory"][id] = inventory(id) - 1
                save_now()
                return true
        return false

func buy_item(id: String, price: int) -> bool:
        if try_spend(price):
                data["inventory"][id] = inventory(id) + 1
                save_now()
                return true
        return false

# ---------- تم‌ها ----------
func buy_theme(id: String, price: int) -> bool:
        if data["themes_owned"].has(id):
                return true
        if try_spend(price):
                data["themes_owned"].append(id)
                save_now()
                return true
        return false

func set_theme(id: String) -> void:
        if data["themes_owned"].has(id):
                data["theme"] = id
                save_now()

func theme() -> Dictionary:
        for t in Data.shop.get("themes", []):
                if t["id"] == data.get("theme", "cream"):
                        return t
        return {"id": "cream", "accent": "#e8862e", "accent2": "#4e9a51", "bg": "#fbf3e4"}
