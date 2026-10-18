class_name Barista
extends Node2D
## The player character. Works behind the counter.
## Animations: idle, prepare, serve, react.
## ART SWAP: add an AnimatedSprite2D child named "Anim" with animations named
## "idle", "prepare", "serve". If it exists it is used; otherwise the
## procedural placeholder is animated with tweens.

@onready var visual: CharacterPlaceholder = $Visual
@onready var anim: AnimatedSprite2D = get_node_or_null("Anim")

var _tween: Tween = null


func _ready() -> void:
	if anim != null and anim.sprite_frames != null:
		visual.visible = false
	play_idle()


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	visual.position = Vector2.ZERO
	visual.scale = Vector2.ONE
	visual.rotation = 0.0


func _has_anim(anim_name: String) -> bool:
	return anim != null and anim.sprite_frames != null and anim.sprite_frames.has_animation(anim_name)


func play_idle() -> void:
	_kill_tween()
	visual.expression = &"neutral"
	if _has_anim("idle"):
		anim.play("idle")
		return
	_tween = create_tween().set_loops()
	_tween.tween_property(visual, "scale", Vector2(1.0, 1.03), 1.2).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(visual, "scale", Vector2(1.0, 1.0), 1.2).set_trans(Tween.TRANS_SINE)


func play_prepare(duration: float = 1.0) -> void:
	_kill_tween()
	visual.expression = &"happy"
	if _has_anim("prepare"):
		anim.play("prepare")
		return
	_tween = create_tween().set_loops(maxi(1, int(duration / 0.3)))
	_tween.tween_property(visual, "rotation", 0.04, 0.15)
	_tween.tween_property(visual, "rotation", -0.04, 0.15)


func play_serve() -> void:
	_kill_tween()
	visual.expression = &"happy"
	if _has_anim("serve"):
		anim.play("serve")
		return
	_tween = create_tween()
	_tween.tween_property(visual, "position:y", 4.0, 0.15)
	_tween.tween_property(visual, "position:y", 0.0, 0.2)
	_tween.tween_callback(play_idle)


func play_oops() -> void:
	_kill_tween()
	visual.expression = &"sad"
	_tween = create_tween()
	_tween.tween_property(visual, "scale", Vector2(1.0, 0.95), 0.2)
	_tween.tween_interval(0.5)
	_tween.tween_callback(play_idle)
