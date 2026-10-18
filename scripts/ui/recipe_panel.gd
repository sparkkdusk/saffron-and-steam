class_name RecipePanel
extends PanelContainer
## Recipe book. Toggle with R.

var _list: VBoxContainer


func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(300, 0)
	position = Vector2(63, 30)
	var outer := VBoxContainer.new()
	var title := Label.new()
	title.text = "Recipe Book  (R to close)"
	title.add_theme_color_override("font_color", UITheme.COL_BORDER.lightened(0.3))
	outer.add_child(title)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	outer.add_child(_list)
	add_child(outer)
	EventBus.recipe_unlocked.connect(func(_id): _refresh())


func toggle() -> void:
	visible = not visible
	if visible:
		_refresh()


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	for id in GameState.recipes:
		var r: Recipe = GameState.recipes[id]
		var l := Label.new()
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(280, 0)
		if GameState.is_recipe_unlocked(id):
			l.text = "%s  (%d coins)\n  %s" % [r.display_name, r.base_price, r.step_summary()]
		else:
			l.text = "%s  (locked - buy in the shop)" % r.display_name
			l.add_theme_color_override("font_color", UITheme.COL_TEXT_DIM)
		_list.add_child(l)
