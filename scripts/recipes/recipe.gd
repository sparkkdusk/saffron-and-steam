class_name Recipe
extends Resource
## One drink. Create new drinks by adding a .tres file in res://data/recipes/.

@export var id: StringName = &""
@export var display_name: String = "Drink"
@export var short_name: String = "Drink"          # fits in the order bubble
@export_multiline var description: String = ""
@export var steps: Array[StringName] = []         # ordered step ids (see StepDefs)
@export var equipment: Array[String] = []         # shown in the recipe book only
@export var base_price: int = 3
@export var unlock_cost: int = 0                  # 0 = available from the start
@export var drink_color: Color = Color(0.5, 0.3, 0.2)


## True only if the drink contains exactly the recipe steps, in order.
func matches(drink: DrinkState) -> bool:
	if drink == null or drink.steps.size() != steps.size():
		return false
	for i in steps.size():
		if drink.steps[i] != steps[i]:
			return false
	return true


func step_summary() -> String:
	var parts: PackedStringArray = []
	for s in steps:
		parts.append(StepDefs.label_of(s))
	return " > ".join(parts)


## Friendly explanation of what is wrong with a drink (used in feedback).
func mismatch_hint(drink: DrinkState) -> String:
	if drink == null or drink.is_empty():
		return "I don't see a drink yet."
	# Is the drink a correct start of the recipe? -> just unfinished.
	var is_prefix := drink.steps.size() < steps.size()
	if is_prefix:
		for i in drink.steps.size():
			if drink.steps[i] != steps[i]:
				is_prefix = false
				break
	if is_prefix:
		var missing: PackedStringArray = []
		for i in range(drink.steps.size(), steps.size()):
			missing.append(StepDefs.label_of(steps[i]))
		return "It's missing: %s." % ", ".join(missing)
	if drink.steps.size() > steps.size():
		return "That has too many ingredients for a %s." % display_name
	return "That isn't how a %s is made. Check the recipe book (R)." % display_name
