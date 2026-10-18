extends Node2D
## Subtle life: rain streaks in the window, steam over the espresso machine,
## gentle lantern glow. All procedural; swap for your own sprites/particles later.

const WINDOW := Rect2(373, 14, 50, 130)
const STEAM_POS := Vector2(262, 118)
const LANTERN_POS := Vector2(235, 38)

var _drops: Array[Vector2] = []
var _t: float = 0.0


func _ready() -> void:
	for i in 18:
		_drops.append(Vector2(randf_range(WINDOW.position.x, WINDOW.end.x), randf_range(WINDOW.position.y, WINDOW.end.y)))
	var steam := CPUParticles2D.new()
	steam.position = STEAM_POS
	steam.amount = 8
	steam.lifetime = 1.8
	steam.direction = Vector2(0, -1)
	steam.spread = 12.0
	steam.gravity = Vector2.ZERO
	steam.initial_velocity_min = 6.0
	steam.initial_velocity_max = 11.0
	steam.scale_amount_min = 1.5
	steam.scale_amount_max = 2.5
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.55))
	grad.set_color(1, Color(1, 1, 1, 0.0))
	steam.color_ramp = grad
	add_child(steam)


func _process(delta: float) -> void:
	_t += delta
	for i in _drops.size():
		var p := _drops[i]
		p += Vector2(-12, 60) * delta
		if p.y > WINDOW.end.y or p.x < WINDOW.position.x:
			p = Vector2(randf_range(WINDOW.position.x + 6, WINDOW.end.x + 6), WINDOW.position.y)
		_drops[i] = p
	queue_redraw()


func _draw() -> void:
	for p in _drops:
		draw_line(p, p + Vector2(-1, 3), Color(0.9, 0.95, 1.0, 0.7), 1.0)
	var flicker := 0.10 + 0.03 * sin(_t * 3.1) + 0.02 * sin(_t * 7.3)
	draw_circle(LANTERN_POS, 46.0, Color(1.0, 0.7, 0.25, flicker * 0.5))
	draw_circle(LANTERN_POS, 28.0, Color(1.0, 0.75, 0.3, flicker))
