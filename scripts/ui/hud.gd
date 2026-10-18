extends CanvasLayer
## In-game HUD: coin counter, buttons, hover hint, feedback line and the
## recipe / shop panels. Everything is built in code from the shared theme.

var _root: Control
var _coin_label: Label
var _hint_label: Label
var _feedback: Label
var _feedback_panel: PanelContainer
var _feedback_tween: Tween
var _recipe_panel: Control
var _shop_panel: Control


func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.theme = UITheme.build()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_coin_counter()
	_build_buttons()
	_build_feedback()
	_recipe_panel = RecipePanel.new()
	_shop_panel = ShopPanel.new()
	_root.add_child(_recipe_panel)
	_root.add_child(_shop_panel)
	EventBus.coins_changed.connect(_on_coins_changed)
	EventBus.feedback_requested.connect(_on_feedback)
	EventBus.hint_changed.connect(_on_hint)
	EventBus.panel_requested.connect(_on_panel_requested)
	_on_coins_changed(GameState.coins)


func _build_coin_counter() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(4, 4)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := HBoxContainer.new()
	var icon := ColorRect.new()
	icon.custom_minimum_size = Vector2(7, 7)
	icon.color = Color(0.95, 0.75, 0.25)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_wrap := CenterContainer.new()
	icon_wrap.add_child(icon)
	_coin_label = Label.new()
	_coin_label.text = "0"
	box.add_child(icon_wrap)
	box.add_child(_coin_label)
	panel.add_child(box)
	_root.add_child(panel)


func _build_buttons() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 2)
	row.position = Vector2(426.0 - 4.0 - 156.0, 4.0)
	var defs := [["Recipes [R]", &"recipes"], ["Shop [S]", &"shop"], ["Menu [Esc]", &"pause"]]
	for d in defs:
		var b := Button.new()
		b.text = d[0]
		b.focus_mode = Control.FOCUS_NONE
		var panel_name: StringName = d[1]
		b.pressed.connect(func():
			AudioManager.play_sfx("click", 1.2)
			EventBus.panel_requested.emit(panel_name))
		row.add_child(b)
	_root.add_child(row)
	# hover hint under the buttons
	_hint_label = Label.new()
	_hint_label.position = Vector2(4, 24)
	_hint_label.add_theme_color_override("font_color", UITheme.COL_BORDER.lightened(0.3))
	_root.add_child(_hint_label)


func _build_feedback() -> void:
	_feedback_panel = PanelContainer.new()
	_feedback_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feedback_panel.modulate.a = 0.0
	_feedback = Label.new()
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.custom_minimum_size = Vector2(300, 0)
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_panel.add_child(_feedback)
	_feedback_panel.position = Vector2(63, 214)
	_root.add_child(_feedback_panel)


func _on_coins_changed(total: int) -> void:
	_coin_label.text = str(total)


func _on_hint(text: String) -> void:
	_hint_label.text = text


func _on_feedback(message: String, kind: StringName) -> void:
	_feedback.text = message
	var col := UITheme.COL_TEXT
	if kind == &"good":
		col = UITheme.COL_GOOD
	elif kind == &"bad":
		col = UITheme.COL_BAD
	_feedback.add_theme_color_override("font_color", col)
	_feedback_panel.size = Vector2.ZERO
	_feedback_panel.position.x = (426.0 - 300.0) / 2.0
	_feedback_panel.position.y = 240.0 - 26.0
	if _feedback_tween != null and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback_panel.modulate.a = 1.0
	_feedback_tween = create_tween()
	_feedback_tween.tween_interval(3.5)
	_feedback_tween.tween_property(_feedback_panel, "modulate:a", 0.0, 0.6)


func _on_panel_requested(panel_name: StringName) -> void:
	match panel_name:
		&"recipes":
			_shop_panel.visible = false
			_recipe_panel.toggle()
		&"shop":
			_recipe_panel.visible = false
			_shop_panel.toggle()
