extends Node
## Sound — موسیقی شهرها و افکت‌های صوتی

var _music: AudioStreamPlayer
var _music_name := ""
var _sfx_pool: Array = []
var _sfx_idx := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)
	apply_volumes()

func apply_volumes() -> void:
	var st: Dictionary = Save.data.get("settings", {})
	_music.volume_db = linear_to_db(clampf(float(st.get("music", 0.8)), 0.0, 1.0))
	for p in _sfx_pool:
		p.volume_db = linear_to_db(clampf(float(st.get("sfx", 0.9)), 0.0, 1.0)) - 3.0

func set_music_vol(v: float) -> void:
	Save.data["settings"]["music"] = v
	apply_volumes()
	Save.save_now()

func set_sfx_vol(v: float) -> void:
	Save.data["settings"]["sfx"] = v
	apply_volumes()
	Save.save_now()

func music(name: String) -> void:
	if _music_name == name and _music.playing:
		return
	_music_name = name
	var stream: AudioStream = load("res://assets/audio/music/%s.ogg" % name)
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_music.stream = stream
	_music.play()

func stop_music() -> void:
	_music_name = ""
	_music.stop()

func sfx(name: String, pitch: float = 1.0, volume: float = 0.0) -> void:
	var p: AudioStreamPlayer = _sfx_pool[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % _sfx_pool.size()
	p.stream = load("res://assets/audio/sfx/%s.wav" % name)
	p.pitch_scale = pitch
	p.volume_db = -3.0 + volume
	p.play()

## افکت کلمه با پیچ فزاینده (کمبو)
func sfx_combo(name: String, combo: int) -> void:
	sfx(name, minf(1.0 + combo * 0.06, 1.5))
