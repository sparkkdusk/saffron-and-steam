extends Node2D
## Shows the drink in the barista's hands as a cup with coloured layers.
## Origin = bottom centre of the cup.

const CUP_W := 12.0
const CUP_H := 14.0

var _drink: DrinkState = null


func _ready() -> void:
	EventBus.drink_changed.connect(_on_drink_changed)
	visible = false


func _on_drink_changed(drink: RefCounted) -> void:
	_drink = drink as DrinkState
	visible = _drink != null and _drink.has_cup()
	queue_redraw()


func _draw() -> void:
	if _drink == null or not _drink.has_cup():
		return
	var line := Color(0.2, 0.12, 0.1)
	draw_rect(Rect2(-9, -1, 18, 2), Color(0.95, 0.9, 0.8))
	var body := Rect2(-CUP_W / 2.0, -CUP_H - 1.0, CUP_W, CUP_H)
	draw_rect(body, Color(0.97, 0.94, 0.86))
	var layers := _drink.get_layer_colors()
	if layers.size() > 0:
		var inner := body.grow(-1.0)
		var each := inner.size.y / float(layers.size())
		for i in layers.size():
			var y := inner.end.y - each * float(i + 1)
			draw_rect(Rect2(inner.position.x, y, inner.size.x, ceilf(each)), layers[i])
	draw_rect(body, line, false, 1.0)
	draw_rect(Rect2(body.end.x, body.position.y + 3.0, 2, 6), line)
