extends Control
## Title screen with Start / How to play / Settings / Reset save / Quit.

const CAFE_SCENE := "res://scenes/cafe/cafe.tscn"
##const CAFE_NAME := "SAFFRON & STEAM"
const TITLE_BG_PATH := "res://assets/reference/title_bg.png"

var _menu: VBoxContainer
var _settings: SettingsMenu
var _info: InfoPanel
var _coins_label: Label


func _ready() -> void:
	theme = UITheme.build()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.07, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	if ResourceLoader.exists(TITLE_BG_PATH):
		var tex := TextureRect.new()
		tex.texture = load(TITLE_BG_PATH)
		tex.modulate = Color(1, 1, 1, 0.55)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_SCALE
		tex.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tex)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var holder := VBoxContainer.new()
	holder.add_theme_constant_override("separation", 8)
	center.add_child(holder)

	var title := Label.new()
##	title.text = CAFE_NAME
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", UITheme.COL_BORDER.lightened(0.3))
	holder.add_child(title)

	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 4)
	holder.add_child(_menu)
	_add_button("Start", _start)
	_add_button("How to play", func(): _show(_info))
	_add_button("Settings", func():
		_settings.refresh()
		_show(_settings))
	_add_button("Reset save", _reset)
	_add_button("Quit", func(): get_tree().quit())

	_settings = SettingsMenu.new()
	_settings.closed.connect(func(): _show(_menu))
	holder.add_child(_settings)
	_info = InfoPanel.new()
	_info.closed.connect(func(): _show(_menu))
	holder.add_child(_info)
	_coins_label = Label.new()
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holder.add_child(_coins_label)
	_show(_menu)
	_update_coins()
	AudioManager.start_ambience()


func _add_button(text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(140, 0)
	b.pressed.connect(func():
		AudioManager.play_sfx("click", 1.2)
		cb.call())
	_menu.add_child(b)


func _show(which: Control) -> void:
	for c in [_menu, _settings, _info]:
		c.visible = (c == which)


func _update_coins() -> void:
	_coins_label.text = "Saved coins: %d" % GameState.coins


func _start() -> void:
	get_tree().change_scene_to_file(CAFE_SCENE)


func _reset() -> void:
	GameState.reset_progress()
	_update_coins()
