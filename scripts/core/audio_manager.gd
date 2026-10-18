extends Node
## Audio with two buses (Music, SFX). If you have not added audio files yet,
## it SYNTHESISES simple placeholder sounds so the game is never silent.
## Drop real files in res://assets/audio/sfx/<name>.ogg (or .wav/.mp3) to override.
## Autoload name: AudioManager

const RATE := 16000
const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_FILES := ["res://assets/audio/music/cafe_loop.ogg", "res://assets/audio/music/cafe_loop.wav", "res://assets/audio/music/cafe_loop.mp3"]
const RAIN_FILES := ["res://assets/audio/music/rain_loop.ogg", "res://assets/audio/music/rain_loop.wav", "res://assets/audio/music/rain_loop.mp3"]
const EXTS := [".ogg", ".wav", ".mp3"]

var _cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _rain: AudioStreamPlayer
var _started := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_rain = AudioStreamPlayer.new()
	_rain.bus = "Music"
	add_child(_rain)
	apply_volumes()


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func apply_volumes() -> void:
	_set_bus("Music", GameState.music_volume)
	_set_bus("SFX", GameState.sfx_volume)


func _set_bus(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.001)))


func set_music_volume(v: float) -> void:
	GameState.music_volume = clampf(v, 0.0, 1.0)
	apply_volumes()


func set_sfx_volume(v: float) -> void:
	GameState.sfx_volume = clampf(v, 0.0, 1.0)
	apply_volumes()


# ------------------------------------------------------------------ play
func play_sfx(sfx_name: String, pitch: float = 1.0) -> void:
	var stream := _get_sfx(sfx_name)
	if stream == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch
			p.play()
			return
	_players[0].stream = stream
	_players[0].pitch_scale = pitch
	_players[0].play()


func start_ambience() -> void:
	if _started:
		return
	_started = true
	var m := _load_first(MUSIC_FILES)
	if m == null:
		m = _synth_music()
	_loop(m)
	_music.stream = m
	_music.volume_db = -4.0
	_music.play()
	var r := _load_first(RAIN_FILES)
	if r == null:
		r = _synth_rain()
	_loop(r)
	_rain.stream = r
	_rain.volume_db = -14.0
	_rain.play()


func _loop(stream: AudioStream) -> void:
	if "loop" in stream:
		stream.loop = true


func _load_first(paths: Array) -> AudioStream:
	for p in paths:
		if ResourceLoader.exists(p):
			return load(p)
	return null


func _get_sfx(sfx_name: String) -> AudioStream:
	if _cache.has(sfx_name):
		return _cache[sfx_name]
	var stream: AudioStream = null
	for ext in EXTS:
		var path: String = SFX_DIR + sfx_name + ext
		if ResourceLoader.exists(path):
			stream = load(path)
			break
	if stream == null:
		stream = _synth_sfx(sfx_name)
	_cache[sfx_name] = stream
	return stream


# ------------------------------------------------------------ synthesis
func _make_wav(samples: PackedFloat32Array, looped: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	if looped:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav


func _tone(freqs: Array, dur: float, decay: float, vol: float, delay_step: float = 0.0) -> AudioStreamWAV:
	var total := dur + delay_step * freqs.size()
	var n := int(total * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for fi in freqs.size():
		var start := int(delay_step * fi * RATE)
		for i in int(dur * RATE):
			var t := float(i) / RATE
			var env := exp(-t * decay) * minf(1.0, t / 0.005)
			if start + i < n:
				buf[start + i] += sin(TAU * float(freqs[fi]) * t) * vol * env
	return _make_wav(buf)


func _noise(dur: float, smooth: float, vol: float, fade_in: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lp := 0.0
	for i in n:
		lp += ((randf() * 2.0 - 1.0) - lp) * smooth
		var t := float(i) / RATE
		var env := minf(1.0, t / fade_in) * minf(1.0, (dur - t) / 0.15)
		buf[i] = lp * vol * env
	return _make_wav(buf)


func _synth_sfx(sfx_name: String) -> AudioStream:
	match sfx_name:
		"click": return _tone([1100.0], 0.05, 40.0, 0.3)
		"cup": return _tone([320.0, 480.0], 0.12, 22.0, 0.35)
		"pour": return _noise(0.9, 0.12, 1.1, 0.1)
		"brew": return _noise(1.6, 0.04, 1.6, 0.2)
		"ding": return _tone([880.0, 1320.0], 0.4, 7.0, 0.3, 0.07)
		"bell": return _tone([988.0, 1319.0, 1175.0], 0.5, 5.0, 0.25, 0.14)
		"coin": return _tone([1568.0, 2093.0], 0.25, 9.0, 0.25, 0.06)
		"wrong": return _tone([220.0, 175.0], 0.3, 7.0, 0.35, 0.1)
		"trash": return _noise(0.35, 0.3, 0.7, 0.02)
	return null


func _synth_music() -> AudioStreamWAV:
	var length := 8.0
	var n := int(length * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var chords := [[130.81, 164.81, 196.0], [110.0, 130.81, 164.81], [87.31, 130.81, 174.61], [98.0, 146.83, 196.0]]
	var chord_len := int(2.0 * RATE)
	for ci in 4:
		for f in chords[ci]:
			for i in chord_len:
				var t := float(i) / RATE
				var env := minf(1.0, t / 0.5) * minf(1.0, (2.0 - t) / 0.5)
				var idx := (ci * chord_len + i) % n
				buf[idx] += sin(TAU * float(f) * t) * 0.05 * env
	var melody := [[0.0, 392.0], [1.0, 329.63], [2.0, 293.66], [3.0, 329.63], [4.0, 440.0], [5.0, 392.0], [6.0, 329.63], [7.0, 261.63]]
	for m in melody:
		var start := int(float(m[0]) * RATE)
		for i in int(0.9 * RATE):
			var t := float(i) / RATE
			var env := exp(-t * 4.0) * minf(1.0, t / 0.01)
			var idx := (start + i) % n
			buf[idx] += (sin(TAU * float(m[1]) * t) * 0.12 + sin(TAU * float(m[1]) * 2.0 * t) * 0.03) * env
	return _make_wav(buf, true)


func _synth_rain() -> AudioStreamWAV:
	var n := int(3.0 * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lp := 0.0
	for i in n:
		lp += ((randf() * 2.0 - 1.0) - lp) * 0.25
		buf[i] = lp * 0.5
	return _make_wav(buf, true)
