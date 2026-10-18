class_name PlaceholderSprite
extends Node2D
## A drawable stand-in for real art.
##  * If `texture_path` points to an existing image, that image is shown instead.
##  * Otherwise a coloured box with a tiny label is drawn.
## So you can replace placeholders one by one by only typing a path in the
## Inspector (or by dropping a file at the default path). Nothing else changes.

@export_file("*.png") var texture_path: String = ""
@export var size: Vector2 = Vector2(16, 16)
@export var color: Color = Color(0.5, 0.4, 0.3)
@export var label: String = ""
@export var centered: bool = true

var _sprite: Sprite2D = null


func _ready() -> void:
	if texture_path != "" and ResourceLoader.exists(texture_path):
		_sprite = Sprite2D.new()
		_sprite.texture = load(texture_path)
		_sprite.centered = centered
		add_child(_sprite)
	queue_redraw()


func _draw() -> void:
	if _sprite != null:
		return
	var rect := Rect2(-size / 2.0 if centered else Vector2.ZERO, size)
	draw_rect(rect, color)
	draw_rect(rect, color.darkened(0.5), false, 1.0)
	if label != "" and size.x >= 18.0 and size.y >= 10.0:
		draw_string(UITheme.get_font(), rect.position + Vector2(2, 8), label,
				HORIZONTAL_ALIGNMENT_LEFT, size.x - 3.0, 7, color.lightened(0.6))
