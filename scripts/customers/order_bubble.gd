extends Node2D
## The speech bubble above a customer: drink icon, name, price and a soft
## patience bar (it only fades, nobody gets angry - this is a cozy game).

const SIZE := Vector2(64, 36)

var recipe: Recipe = null
var patience_left: float = 1.0   # 1 = fresh, 0 = patience used up


func show_order(r: Recipe) -> void:
	recipe = r
	visible = true
	scale = Vector2.ZERO
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()


func hide_bubble() -> void:
	visible = false


func set_patience(v: float) -> void:
	patience_left = clampf(v, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	if recipe == null:
		return
	var ink := Color(0.15, 0.08, 0.06)
	var rect := Rect2(-SIZE / 2.0, SIZE)
	draw_rect(rect.grow(1.0), ink)
	draw_rect(rect, Color(0.99, 0.95, 0.85))
	draw_colored_polygon(PackedVector2Array([Vector2(-5, rect.end.y), Vector2(5, rect.end.y), Vector2(0, rect.end.y + 8)]), ink)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, rect.end.y - 1), Vector2(4, rect.end.y - 1), Vector2(0, rect.end.y + 6)]), Color(0.99, 0.95, 0.85))
	# cup icon
	var cup := Rect2(rect.position + Vector2(6, 6), Vector2(13, 14))
	draw_rect(cup.grow(1.0), ink)
	draw_rect(cup, Color(0.97, 0.94, 0.86))
	draw_rect(Rect2(cup.position + Vector2(1, 4), Vector2(11, 9)), recipe.drink_color)
	draw_rect(Rect2(cup.end.x + 1, cup.position.y + 3, 2, 6), ink)
	# name
	draw_string(UITheme.get_font(), rect.position + Vector2(23, 13), recipe.short_name,
			HORIZONTAL_ALIGNMENT_LEFT, 40.0, 8, ink)
	# price
	draw_circle(rect.position + Vector2(26, 21), 3.0, Color(0.9, 0.7, 0.2))
	draw_string(UITheme.get_font(), rect.position + Vector2(31, 24), str(recipe.base_price),
			HORIZONTAL_ALIGNMENT_LEFT, 18.0, 8, ink)
	# patience bar
	var bar := Rect2(rect.position + Vector2(5, SIZE.y - 7), Vector2(SIZE.x - 10, 3))
	draw_rect(bar, Color(0.8, 0.7, 0.55))
	var col := Color(0.55, 0.78, 0.4).lerp(Color(0.95, 0.6, 0.3), 1.0 - patience_left)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * patience_left, bar.size.y)), col)
