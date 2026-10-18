class_name DrinkState
extends RefCounted
## The drink currently in the barista's hands: an ordered list of step ids.

const MAX_STEPS := 6

var steps: Array[StringName] = []


func has_cup() -> bool:
	return not steps.is_empty() and steps[0] == &"cup"


func is_empty() -> bool:
	return steps.is_empty()


func add_step(step_id: StringName) -> void:
	steps.append(step_id)


func clear() -> void:
	steps.clear()


## Colours of the liquid layers (everything except the cup), bottom to top.
func get_layer_colors() -> Array[Color]:
	var out: Array[Color] = []
	for s in steps:
		if s != &"cup":
			out.append(StepDefs.color_of(s))
	return out
