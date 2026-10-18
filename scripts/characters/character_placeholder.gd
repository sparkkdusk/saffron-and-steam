class_name CharacterPlaceholder
extends Node2D
## Procedural stand-in for a character sprite. Origin = feet.
## facing_back = true  -> customer seen from behind (hooded shawl + backpack)
## facing_back = false -> barista seen from the front (with a face)
## Replace by adding an AnimatedSprite2D (see Barista) or a Sprite2D.

@export var facing_back: bool = true
@export var body_color: Color = Color(0.5, 0.3, 0.3)
@export var hair_color: Color = Color(0.2, 0.12, 0.1)
@export var accent_color: Color = Color(0.8, 0.6, 0.2)
@export var skin_color: Color = Color(0.93, 0.74, 0.58)

var expression: StringName = &"neutral":
	set(v):
		expression = v
		queue_redraw()


func _ready() -> void:
	queue_redraw()


func apply_colors(body: Color, hair: Color, accent: Color) -> void:
	body_color = body
	hair_color = hair
	accent_color = accent
	queue_redraw()


func _draw() -> void:
	if facing_back:
		_draw_back()
	else:
		_draw_front()


func _outline(rect: Rect2, fill: Color) -> void:
	draw_rect(rect.grow(1.0), fill.darkened(0.65))
	draw_rect(rect, fill)


func _draw_back() -> void:
	var dark := Color(0.12, 0.07, 0.06)
	# legs + shoes
	_outline(Rect2(-10, -24, 8, 20), Color(0.93, 0.88, 0.78))
	_outline(Rect2(2, -24, 8, 20), Color(0.93, 0.88, 0.78))
	_outline(Rect2(-12, -5, 10, 5), accent_color)
	_outline(Rect2(2, -5, 10, 5), accent_color)
	# body (cloak)
	draw_colored_polygon(PackedVector2Array([Vector2(-24, -24), Vector2(24, -24), Vector2(20, -80), Vector2(-20, -80)]), body_color.darkened(0.55))
	draw_colored_polygon(PackedVector2Array([Vector2(-23, -25), Vector2(23, -25), Vector2(19, -79), Vector2(-19, -79)]), body_color)
	# embroidery diamond
	var c := Vector2(0, -44)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-8, 0), c + Vector2(0, -9), c + Vector2(8, 0), c + Vector2(0, 9)]), accent_color)
	# backpack
	_outline(Rect2(-10, -66, 20, 24), accent_color.darkened(0.2))
	# hood / head
	draw_circle(Vector2(0, -92), 16.0, body_color.darkened(0.55))
	draw_circle(Vector2(0, -92), 15.0, body_color.lightened(0.1))
	draw_circle(Vector2(-11, -104), 5.0, hair_color)
	draw_circle(Vector2(11, -104), 5.0, hair_color)
	draw_circle(Vector2(0, -95), 11.0, hair_color)
	draw_rect(Rect2(-1, -105, 2, 16), dark.lightened(0.1))


func _draw_front() -> void:
	var dark := Color(0.12, 0.07, 0.06)
	# torso: blouse + apron + sleeves
	_outline(Rect2(-18, -34, 36, 34), Color(0.96, 0.92, 0.82))
	_outline(Rect2(-11, -30, 22, 30), body_color)
	_outline(Rect2(-24, -32, 8, 22), Color(0.96, 0.92, 0.82))
	_outline(Rect2(16, -32, 8, 22), Color(0.96, 0.92, 0.82))
	# scarf
	_outline(Rect2(-16, -40, 32, 9), accent_color)
	# head
	draw_circle(Vector2(0, -52), 15.0, dark)
	draw_circle(Vector2(0, -52), 14.0, skin_color)
	# headscarf / hair
	draw_circle(Vector2(0, -58), 15.0, dark)
	draw_rect(Rect2(-15, -66, 30, 12), accent_color)
	draw_circle(Vector2(0, -58), 14.0, accent_color)
	draw_rect(Rect2(-12, -56, 24, 3), hair_color)
	# eyes + blush + mouth
	draw_rect(Rect2(-7, -50, 3, 5), dark)
	draw_rect(Rect2(4, -50, 3, 5), dark)
	draw_rect(Rect2(-6, -50, 1, 1), Color.WHITE)
	draw_rect(Rect2(5, -50, 1, 1), Color.WHITE)
	draw_rect(Rect2(-10, -44, 3, 2), Color(0.9, 0.5, 0.5))
	draw_rect(Rect2(7, -44, 3, 2), Color(0.9, 0.5, 0.5))
	match expression:
		&"happy":
			draw_rect(Rect2(-3, -41, 6, 1), dark)
			draw_rect(Rect2(-2, -40, 4, 1), dark)
		&"sad":
			draw_rect(Rect2(-2, -41, 4, 1), dark)
			draw_rect(Rect2(-3, -40, 1, 1), dark)
			draw_rect(Rect2(2, -40, 1, 1), dark)
		_:
			draw_rect(Rect2(-2, -41, 4, 1), dark)
