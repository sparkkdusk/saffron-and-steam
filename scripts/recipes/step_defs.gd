class_name StepDefs
extends RefCounted
## Every preparation step the player can perform. DATA ONLY.
## A step is triggered by clicking a station (station id -> step id).
## Recipes are just ordered lists of step ids.

const DEFS := {
	&"cup": {
		"label": "Cup", "station": &"cup_stack", "duration": 0.35, "sfx": "cup",
		"color": Color(0.96, 0.92, 0.82), "message": "Got a cup. Now add something!",
	},
	&"brew_espresso": {
		"label": "Espresso", "station": &"espresso_machine", "duration": 1.6, "sfx": "brew",
		"color": Color(0.35, 0.2, 0.12), "message": "Espresso brewed!",
	},
	&"add_milk": {
		"label": "Milk", "station": &"milk_jug", "duration": 1.0, "sfx": "pour",
		"color": Color(0.94, 0.88, 0.78), "message": "Milk added.",
	},
	&"add_matcha": {
		"label": "Matcha", "station": &"matcha_tin", "duration": 1.0, "sfx": "pour",
		"color": Color(0.48, 0.64, 0.29), "message": "Matcha whisked in.",
	},
	&"add_strawberry": {
		"label": "Strawberry", "station": &"strawberry_syrup", "duration": 0.8, "sfx": "pour",
		"color": Color(0.88, 0.47, 0.53), "message": "Strawberry swirled in.",
	},
}


static func get_def(step_id: StringName) -> Dictionary:
	return DEFS.get(step_id, {})


static func step_for_station(station_id: StringName) -> StringName:
	for step_id in DEFS:
		if DEFS[step_id]["station"] == station_id:
			return step_id
	return &""


static func label_of(step_id: StringName) -> String:
	return String(DEFS.get(step_id, {}).get("label", step_id))


static func color_of(step_id: StringName) -> Color:
	return DEFS.get(step_id, {}).get("color", Color.WHITE)
