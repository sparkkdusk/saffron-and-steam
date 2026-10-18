class_name Interactable
extends Area2D
## Reusable click target. Add one anywhere, set `station_id`, connect `interacted`.
## Draws a hover outline, shows a hand cursor and can show a progress bar.

signal interacted(who: Interactable)
signal hovered(who: Interactable)
signal unhovered(who: Interactable)

@export var station_id: StringName = &""
@export var display_name: String = ""
@export var size: Vector2 = Vector2(16, 16)
@export var enabled: bool = true:
	set(v):
		enabled = v
		if not enabled and _hover:
			_set_hover(false)
		queue_redraw()

var _hover: bool = false
var _progress: float = -1.0


func _ready() -> void:
	input_pickable = true
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	add_child(shape)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	EventBus.action_progress.connect(_on_progress)
	set_process(false)


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if not enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		AudioManager.play_sfx("click", 1.2)
		interacted.emit(self)
		get_viewport().set_input_as_handled()


func _on_mouse_entered() -> void:
	if enabled:
		_set_hover(true)


func _on_mouse_exited() -> void:
	_set_hover(false)


func _set_hover(value: bool) -> void:
	if _hover == value:
		return
	_hover = value
	if value:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		hovered.emit(self)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		unhovered.emit(self)
	queue_redraw()


func _on_progress(id: StringName, ratio: float) -> void:
	if id != station_id:
		return
	_progress = ratio
	queue_redraw()


func _exit_tree() -> void:
	if _hover:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _draw() -> void:
	var rect := Rect2(-size / 2.0, size)
	if _hover and enabled:
		draw_rect(rect.grow(1.0), Color(1.0, 0.9, 0.5, 0.18))
		draw_rect(rect.grow(1.0), Color(1.0, 0.85, 0.35), false, 1.0)
	if _progress >= 0.0:
		var bar := Rect2(rect.position + Vector2(0, -5), Vector2(rect.size.x, 3))
		draw_rect(bar.grow(1.0), Color(0.1, 0.05, 0.03))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(_progress, 0.0, 1.0), bar.size.y)), Color(0.95, 0.75, 0.3))
