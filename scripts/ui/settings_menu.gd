class_name SettingsMenu
extends PanelContainer
## Music / SFX sliders. Emits `closed` when Back is pressed. Saves on close.

signal closed

var _music: HSlider
var _sfx: HSlider


func _ready() -> void:
	theme = UITheme.build()
	custom_minimum_size = Vector2(220, 0)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_music = _slider_row(box, "Music", GameState.music_volume)
	_sfx = _slider_row(box, "Sound effects", GameState.sfx_volume)
	_music.value_changed.connect(func(v): AudioManager.set_music_volume(v))
	_sfx.value_changed.connect(func(v):
		AudioManager.set_sfx_volume(v)
		AudioManager.play_sfx("ding"))
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func():
		GameState.save_game()
		closed.emit())
	box.add_child(back)
	add_child(box)


func refresh() -> void:
	_music.set_value_no_signal(GameState.music_volume)
	_sfx.set_value_no_signal(GameState.sfx_volume)


func _slider_row(parent: Control, label_text: String, value: float) -> HSlider:
	var l := Label.new()
	l.text = label_text
	parent.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(200, 12)
	parent.add_child(s)
	return s
