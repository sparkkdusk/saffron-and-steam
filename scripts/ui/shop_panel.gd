class_name ShopPanel
extends PanelContainer
## Spend coins on new drinks and decorations. Toggle with S.

var _list: VBoxContainer


func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(300, 0)
	position = Vector2(63, 30)
	var outer := VBoxContainer.new()
	var title := Label.new()
	title.text = "Shop  (S to close)"
	title.add_theme_color_override("font_color", UITheme.COL_BORDER.lightened(0.3))
	outer.add_child(title)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 3)
	outer.add_child(_list)
	add_child(outer)
	EventBus.coins_changed.connect(func(_c): if visible: _refresh())


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()


func _row(text: String, cost: int, owned: bool, on_buy: Callable) -> void:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	if owned:
		b.text = "Owned"
		b.disabled = true
	else:
		b.text = "Buy %d" % cost
		b.disabled = GameState.coins < cost
		b.pressed.connect(func():
			if on_buy.call():
				AudioManager.play_sfx("coin")
				EventBus.say("Purchased!", &"good")
			else:
				AudioManager.play_sfx("wrong")
			_refresh())
	row.add_child(b)
	_list.add_child(row)


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	for id in GameState.recipes:
		var r: Recipe = GameState.recipes[id]
		if r.unlock_cost > 0:
			_row("Recipe: " + r.display_name, r.unlock_cost, GameState.is_recipe_unlocked(id), func(): return GameState.buy_recipe(id))
	for id in GameState.DECOR:
		var d: Dictionary = GameState.DECOR[id]
		_row("Decor: " + d["name"], d["cost"], GameState.owns_decor(id), func(): return GameState.buy_decor(id))
