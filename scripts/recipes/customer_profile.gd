class_name CustomerProfile
extends Resource
## Look + personality of a customer type. Add new ones in res://data/customers/.

@export var id: StringName = &""
@export var display_name: String = "Guest"
@export_enum("patient", "generous", "chatty", "shy") var personality: String = "patient"
@export var patience_seconds: float = 45.0
@export var favorite_recipe: StringName = &""     # picked more often (optional)
@export var body_color: Color = Color(0.9, 0.7, 0.4)
@export var hair_color: Color = Color(0.3, 0.2, 0.2)
@export var accent_color: Color = Color(0.7, 0.4, 0.3)
@export_file("*.png") var sprite_path: String = ""   # optional; default is res://assets/sprites/customer_<id>.png
