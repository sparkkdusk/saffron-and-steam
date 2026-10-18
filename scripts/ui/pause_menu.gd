extends CanvasLayer
## Pause menu (Esc). Pauses the whole tree; this node keeps running.

var _dim: ColorRect
var _menu: PanelContainer
var _settings: SettingsMenu
var _info: InfoPanel


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)

	_menu = PanelContainer.new()
	_menu.theme = UITheme.build()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var title := Label.new()
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_add_button(box, "Resume", toggle)
	_add_button(box, "How to play", func(): _show_only(_info))
	_add_button(box, "Settings", func():
		_settings.refresh()
		_show_only(_settings))
	_add_button(box, "Quit to title", _quit_to_title)
	_menu.add_child(box)
	_center(_menu)

	_settings = SettingsMenu.new()
	_settings.closed.connect(func(): _show_only(_menu))
	_center(_settings)
	_info = InfoPanel.new()
	_info.closed.connect(func(): _show_only(_menu))
	_center(_info)
	_show_only(_menu)


func _center(c: Control) -> void:
	var holder := CenterContainer.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(c)
	add_child(holder)
	c.set_meta("holder", holder)


func _show_only(which: Control) -> void:
	for c in [_menu, _settings, _info]:
		c.get_meta("holder").visible = (c == which)


func _add_button(parent: Control, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, 0)
	b.pressed.connect(func():
		AudioManager.play_sfx("click", 1.2)
		cb.call())
	parent.add_child(b)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	visible = not visible
	get_tree().paused = visible
	if visible:
		_show_only(_menu)
	else:
		GameState.save_game()


func _quit_to_title() -> void:
	get_tree().paused = false
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/ui/title_screen.tscn")
