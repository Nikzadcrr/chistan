extends Node
## Game — وضعیت نشست بازی: حالت کلاسیک، چالش روزانه، حالت جمعی و لیگ

enum Mode { CLASSIC, DAILY, GROUP }

var mode: int = Mode.CLASSIC
var level_id: int = 1
var level: Dictionary = {}
var daily_date := ""
var daily_letters: Array = []
var daily_score := 0
var daily_found: Array = []
var daily_time := 180.0

# حالت جمعی / لیگ
var group: Dictionary = {}

const AVATAR_COLORS := ["#e8862e", "#4e9a51", "#2fa8a0", "#d95a4e", "#c9932b", "#d95a7e", "#8c5a38", "#6b8e23"]

func start_level(id: int) -> void:
	mode = Mode.CLASSIC
	level_id = id
	level = Data.get_level(id)

func start_daily() -> void:
	mode = Mode.DAILY
	daily_date = Save.today_str()
	daily_letters = Data.daily_letters(daily_date)
	daily_score = 0
	daily_found = []
	daily_time = 180.0

func start_group(config: Dictionary) -> void:
	## config: {"players":[{"name","color"}], "rounds": int, "is_league": bool, "seconds_per_turn": int}
	mode = Mode.GROUP
	group = {
		"players": config.get("players", []),
		"rounds": config.get("rounds", 3),
		"is_league": config.get("is_league", false),
		"seconds": config.get("seconds_per_turn", 30),
		"turn": 0,          # اندیس بازیکن نوبت‌دار
		"round": 1,         # دور فعلی
		"scores": {},       # index -> score
		"words": {},        # index -> Array[String] (برای رکورد بلندترین کلمه)
		"letters": [],      # حروف دور فعلی
		"turn_words": [],   # کلمات یافت‌شده در نوبت جاری
		"turn_score": 0,
		"finished": false,
	}
	for i in group["players"].size():
		group["scores"][i] = 0
		group["words"][i] = []
	_next_group_letters()

func _next_group_letters() -> void:
	## حروف نوبت — از ریشه‌های دیکشنری (۵ حرف) با تصادف‌سازی زمانی
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var roots: Array = []
	for lv in Data.levels:
		var r: String = lv["root"]
		if r.length() >= 4 and r.length() <= 6:
			roots.append(r)
	var root: String = roots[rng.randi_range(0, roots.size() - 1)]
	group["letters"] = []
	for c in root:
		group["letters"].append(c)

func group_turn_done(score: int, words_found: Array) -> void:
	group["scores"][group["turn"]] = int(group["scores"].get(group["turn"], 0)) + score
	var all: Array = group["words"][group["turn"]]
	all.append_array(words_found)
	group["words"][group["turn"]] = all
	# بازیکن بعدی / دور بعد
	if group["turn"] < group["players"].size() - 1:
		group["turn"] += 1
	elif group["round"] < group["rounds"]:
		group["round"] += 1
		group["turn"] = 0
	else:
		group["finished"] = true
	_next_group_letters()

func group_ranking() -> Array:
	## بر پایه امتیاز نزولی → [{index, name, color, score, longest}]
	var out: Array = []
	for i in group["players"].size():
		var p: Dictionary = group["players"][i]
		var longest := ""
		for w in group["words"].get(i, []):
			if w.length() > longest.length():
				longest = w
		out.append({
			"index": i, "name": p["name"], "color": p["color"],
			"score": int(group["scores"].get(i, 0)), "longest": longest,
		})
	out.sort_custom(func(a, b): return a["score"] > b["score"])
	return out

func group_champion() -> Dictionary:
	var r := group_ranking()
	return r[0] if r.size() > 0 else {}

func current_player() -> Dictionary:
	return group["players"][group["turn"]] if group["players"].size() > 0 else {"name": "", "color": 0}

# ---------- راهنمای مسیر ----------
func route_back_from_map() -> String:
	return "menu"
