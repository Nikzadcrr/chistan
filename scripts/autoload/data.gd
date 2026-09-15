extends Node
## Data — بارگذاری دیکشنری، مراحل، شهرها، دستاوردها و فروشگاه

var words: Array = []
var word_set: Dictionary = {}
var levels: Array = []
var cities: Array = []
var achievements: Array = []
var shop: Dictionary = {}

func _ready() -> void:
	var d := load_json("res://assets/data/dictionary.json")
	words = d.get("words", [])
	for w in words:
		word_set[w] = true
	levels = load_json("res://assets/data/levels.json").get("levels", [])
	cities = load_json("res://assets/data/cities.json").get("cities", [])
	achievements = load_json("res://assets/data/achievements.json").get("achievements", [])
	shop = load_json("res://assets/data/shop.json")

func load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("فایل یافت نشد: " + path)
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}

func city_of_level(level_id: int) -> Dictionary:
	for lv in levels:
		if lv["id"] == level_id:
			return cities[lv["city"]]
	return cities[0]

func get_level(level_id: int) -> Dictionary:
	for lv in levels:
		if lv["id"] == level_id:
			return lv
	return levels[0]

func fa_num(value) -> String:
	return UiKit.fa_num(value)

func is_word_valid(w: String) -> bool:
	return word_set.has(w)

func can_form(w: String, letters: Array) -> bool:
	## آیا w از مجموع حروفِ letters قابل ساخت است؟
	var pool := {}
	for l in letters:
		pool[l] = pool.get(l, 0) + 1
	for c in w:
		if pool.get(c, 0) <= 0:
			return false
		pool[c] -= 1
	return true

func subwords_from(letters: Array) -> Array:
	## همه کلمات قابل ساخت از حروف — برای چالش روزانه و حالت جمعی
	var out := []
	for w in words:
		if w.length() >= 3 and can_form(w, letters):
			out.append(w)
	return out

func daily_seed(date_str: String) -> int:
	var h := 0
	for c in date_str:
		h = (h * 131 + c.unicode_at(0)) % 1000000007
	return h

func daily_letters(date_str: String) -> Array:
	## چرخ چالش روزانه — ریشه تصادفی پایدار بر پایه تاریخ
	var rng := RandomNumberGenerator.new()
	rng.seed = daily_seed(date_str)
	var roots: Array = []
	for lv in levels:
		roots.append(lv["root"])
	roots.sort()
	# ریشه‌های ۵ تا ۷ حرفی
	var big: Array = []
	for r in roots:
		if r.length() >= 5 and r.length() <= 7:
			big.append(r)
	var root: String = big[rng.randi_range(0, big.size() - 1)]
	var letters := []
	for c in root:
		letters.append(c)
	return letters

func daily_best_words(letters: Array) -> Array:
	var out := subwords_from(letters)
	out.sort_custom(func(a, b): return a.length() > b.length())
	return out

func achievement_by_id(id: String) -> Dictionary:
	for a in achievements:
		if a["id"] == id:
			return a
	return {}
