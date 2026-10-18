class_name DecorItem
extends Node2D
## A purchasable decoration. Hidden until bought in the shop.

@export var decor_id: StringName = &""


func _ready() -> void:
	visible = GameState.owns_decor(decor_id)
	EventBus.decor_purchased.connect(_on_purchased)


func _on_purchased(id: StringName) -> void:
	if id == decor_id:
		visible = true
