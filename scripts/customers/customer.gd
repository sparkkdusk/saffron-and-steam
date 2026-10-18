class_name Customer
extends Node2D
## One customer. Origin = feet. Walks in, waits with a personality-driven idle,
## reacts (happy / neutral / disappointed / surprised), pays and leaves.

signal left(customer_id: int)

enum State { ENTERING, WAITING, BUSY, LEAVING }

var customer_id: int = 0
var profile: CustomerProfile
var order: Order
var state: State = State.ENTERING
var slot_position: Vector2 = Vector2(128, 240)
var wait_seconds: float = 0.0

# drawn feedback (animated by tweens)
var reaction: StringName = &""
var popup_text: String = ""
var popup_alpha: float = 0.0
var popup_offset: float = 0.0

var _t: float = 0.0
var _walking: bool = false
var _body: Node2D          # what gets animated: your art if present, else the placeholder

@onready var visual: CharacterPlaceholder = $Visual
@onready var bubble: Node2D = $Bubble
@onready var hit: Interactable = $Hit


func setup(id: int, p: CustomerProfile, slot: Vector2) -> void:
	customer_id = id
	profile = p
	slot_position = slot


func _ready() -> void:
	visual.apply_colors(profile.body_color, profile.hair_color, profile.accent_color)
	_body = visual
	_try_load_art()
	bubble.visible = false
	hit.enabled = false
	hit.display_name = profile.display_name
	position = Vector2(-50.0, slot_position.y)


## Looks for your own sprite: profile.sprite_path, or by convention
## res://assets/sprites/customer_<profile id>.png  (origin = feet, bottom centre).
func _try_load_art() -> void:
	var path := profile.sprite_path
	if path == "":
		path = "res://assets/sprites/customer_%s.png" % profile.id
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	var art := Sprite2D.new()
	art.name = "Art"
	art.texture = tex
	art.centered = false
	art.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
	add_child(art)
	move_child(art, 0)
	visual.visible = false
	_body = art


func is_waiting() -> bool:
	return state == State.WAITING and order != null and order.state == Order.State.OPEN


func is_busy() -> bool:
	return state != State.WAITING


func patience_ratio() -> float:
	return wait_seconds / maxf(profile.patience_seconds, 1.0)


# ------------------------------------------------------------ sequences
func walk_in() -> void:
	state = State.ENTERING
	_walking = true
	var tw := create_tween()
	tw.tween_property(self, "position:x", slot_position.x, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	_walking = false
	_body.position = Vector2.ZERO
	state = State.WAITING


func set_order(o: Order) -> void:
	order = o
	bubble.show_order(o.recipe)
	hit.enabled = true
	AudioManager.play_sfx("ding")


## Show a reaction icon for a moment. Customer goes back to WAITING afterwards
## unless `then_wait` is false (used before paying).
func react(kind: StringName, then_wait: bool = true) -> void:
	var previous := state
	state = State.BUSY
	reaction = kind
	queue_redraw()
	var tw := create_tween()
	match kind:
		&"happy":
			tw.tween_property(_body, "position:y", -5.0, 0.12)
			tw.tween_property(_body, "position:y", 0.0, 0.12)
			tw.tween_property(_body, "position:y", -4.0, 0.12)
			tw.tween_property(_body, "position:y", 0.0, 0.12)
		&"surprised":
			tw.tween_property(_body, "position:y", -7.0, 0.1)
			tw.tween_property(_body, "position:y", 0.0, 0.15)
		&"disappointed":
			tw.tween_property(_body, "scale", Vector2(1.0, 0.94), 0.25)
			tw.tween_interval(0.5)
			tw.tween_property(_body, "scale", Vector2.ONE, 0.2)
		_:
			tw.tween_property(_body, "rotation", 0.05, 0.2)
			tw.tween_property(_body, "rotation", -0.05, 0.3)
			tw.tween_property(_body, "rotation", 0.0, 0.2)
	tw.tween_interval(0.5)
	await tw.finished
	reaction = &""
	_body.position = Vector2.ZERO
	_body.scale = Vector2.ONE
	_body.rotation = 0.0
	queue_redraw()
	if then_wait:
		state = State.WAITING if previous == State.WAITING else previous


func pay_and_leave(amount: int) -> void:
	state = State.BUSY
	hit.enabled = false
	bubble.hide_bubble()
	popup_text = "+%d" % amount
	popup_alpha = 1.0
	popup_offset = 0.0
	AudioManager.play_sfx("coin")
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "popup_offset", -14.0, 0.9)
	tw.tween_property(self, "popup_alpha", 0.0, 0.9).set_delay(0.3)
	await tw.finished
	popup_text = ""
	state = State.LEAVING
	_walking = true
	var out := create_tween()
	out.tween_property(self, "position:x", -60.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await out.finished
	left.emit(customer_id)
	queue_free()


# --------------------------------------------------------------- per frame
func _process(delta: float) -> void:
	_t += delta
	if _walking:
		_body.position.y = -absf(sin(_t * 12.0)) * 2.0
	elif state == State.WAITING:
		wait_seconds += delta
		var sway := 0.8
		var speed := 1.6
		if profile.personality == "chatty":
			sway = 1.6
			speed = 3.2
		elif profile.personality == "shy":
			sway = 0.4
			speed = 1.0
		_body.position.x = sin(_t * speed) * sway
		if order != null and order.state == Order.State.OPEN:
			bubble.set_patience(1.0 - patience_ratio())
	if popup_alpha > 0.0:
		queue_redraw()


func _draw() -> void:
	if reaction != &"":
		_draw_reaction_icon(Vector2(24, -122))
	if popup_text != "" and popup_alpha > 0.0:
		draw_string(UITheme.get_font(), Vector2(-8, -128 + popup_offset), popup_text,
				HORIZONTAL_ALIGNMENT_CENTER, 24.0, 12, Color(1.0, 0.85, 0.3, popup_alpha))


func _draw_reaction_icon(c: Vector2) -> void:
	var ink := Color(0.15, 0.08, 0.06)
	draw_circle(c, 9.0, ink)
	draw_circle(c, 8.0, Color(0.99, 0.95, 0.85))
	match reaction:
		&"happy":
			var col := Color(0.9, 0.3, 0.4)
			draw_circle(c + Vector2(-2, -1), 2.4, col)
			draw_circle(c + Vector2(2, -1), 2.4, col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-4.4, 0), c + Vector2(4.4, 0), c + Vector2(0, 5)]), col)
		&"surprised":
			draw_rect(Rect2(c + Vector2(-1, -5), Vector2(2, 6)), Color(0.9, 0.5, 0.1))
			draw_rect(Rect2(c + Vector2(-1, 3), Vector2(2, 2)), Color(0.9, 0.5, 0.1))
		&"disappointed":
			draw_rect(Rect2(c + Vector2(-3, 1), Vector2(6, 1)), ink)
			draw_rect(Rect2(c + Vector2(-4, 2), Vector2(1, 1)), ink)
			draw_rect(Rect2(c + Vector2(3, 2), Vector2(1, 1)), ink)
			draw_rect(Rect2(c + Vector2(-3, -3), Vector2(2, 2)), ink)
			draw_rect(Rect2(c + Vector2(1, -3), Vector2(2, 2)), ink)
			draw_rect(Rect2(c + Vector2(4, -2), Vector2(1, 3)), Color(0.4, 0.6, 0.9))
		_:
			for i in 3:
				draw_rect(Rect2(c + Vector2(-5 + i * 4, 0), Vector2(2, 2)), ink)
