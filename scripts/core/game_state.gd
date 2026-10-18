extends Node
## Persistent player state + content database + save/load.
## Autoload name: GameState

const SAVE_PATH := "user://savegame.cfg"
const RECIPE_DIR := "res://data/recipes/"
const CUSTOMER_DIR := "res://data/customers/"

## Decorations you can buy. Each id must match a DecorItem node in the cafe scene.
const DECOR := {
	&"plant": {"name": "Window Plant", "cost": 25},
	&"lantern": {"name": "Brass Lantern", "cost": 40},
	&"cat": {"name": "Sleepy Cat", "cost": 60},
}

var coins: int = 0
var unlocked_recipes: Array[StringName] = []
var owned_decor: Array[StringName] = []
var music_volume: float = 0.6
var sfx_volume: float = 0.8

var recipes: Dictionary = {}        # StringName -> Recipe
var customer_profiles: Array = []   # Array[CustomerProfile]


func _ready() -> void:
	_load_content()
	load_game()


# ---------------------------------------------------------------- content
func _load_content() -> void:
	recipes.clear()
	customer_profiles.clear()
	for res in _load_dir(RECIPE_DIR):
		recipes[res.id] = res
	customer_profiles.append_array(_load_dir(CUSTOMER_DIR))
	_apply_defaults()


func _load_dir(path: String) -> Array:
	var out: Array = []
	var files := Array(DirAccess.get_files_at(path))
	files.sort()
	for file in files:
		# Exported games list resources as "name.tres.remap"
		var clean: String = String(file).trim_suffix(".remap")
		if clean.ends_with(".tres"):
			var res = load(path + clean)
			if res != null:
				out.append(res)
	return out


func _apply_defaults() -> void:
	for id in recipes:
		if recipes[id].unlock_cost <= 0 and not unlocked_recipes.has(id):
			unlocked_recipes.append(id)


func get_unlocked_recipes() -> Array:
	var out: Array = []
	for id in unlocked_recipes:
		if recipes.has(id):
			out.append(recipes[id])
	return out


func is_recipe_unlocked(id: StringName) -> bool:
	return unlocked_recipes.has(id)


func owns_decor(id: StringName) -> bool:
	return owned_decor.has(id)


# --------------------------------------------------------------- economy
func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	EventBus.coins_changed.emit(coins)
	save_game()


func spend_coins(amount: int) -> bool:
	if amount < 0 or coins < amount:
		return false
	coins -= amount
	EventBus.coins_changed.emit(coins)
	return true


func buy_recipe(id: StringName) -> bool:
	if not recipes.has(id) or unlocked_recipes.has(id):
		return false
	if not spend_coins(recipes[id].unlock_cost):
		return false
	unlocked_recipes.append(id)
	EventBus.recipe_unlocked.emit(id)
	save_game()
	return true


func buy_decor(id: StringName) -> bool:
	if not DECOR.has(id) or owned_decor.has(id):
		return false
	if not spend_coins(int(DECOR[id]["cost"])):
		return false
	owned_decor.append(id)
	EventBus.decor_purchased.emit(id)
	save_game()
	return true


# ------------------------------------------------------------- save/load
func save_game() -> void:
	var cfg := ConfigFile.new()
	var rec_ids: Array = []
	for id in unlocked_recipes:
		rec_ids.append(String(id))
	var decor_ids: Array = []
	for id in owned_decor:
		decor_ids.append(String(id))
	cfg.set_value("progress", "coins", coins)
	cfg.set_value("progress", "recipes", rec_ids)
	cfg.set_value("progress", "decor", decor_ids)
	cfg.set_value("settings", "music_volume", music_volume)
	cfg.set_value("settings", "sfx_volume", sfx_volume)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("Could not save game (error %d)" % err)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return  # first run: keep defaults
	coins = maxi(int(cfg.get_value("progress", "coins", 0)), 0)
	unlocked_recipes.clear()
	for s in cfg.get_value("progress", "recipes", []):
		if recipes.has(StringName(s)):
			unlocked_recipes.append(StringName(s))
	owned_decor.clear()
	for s in cfg.get_value("progress", "decor", []):
		if DECOR.has(StringName(s)):
			owned_decor.append(StringName(s))
	music_volume = clampf(float(cfg.get_value("settings", "music_volume", 0.6)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value("settings", "sfx_volume", 0.8)), 0.0, 1.0)
	_apply_defaults()


func reset_progress() -> void:
	coins = 0
	unlocked_recipes.clear()
	owned_decor.clear()
	_apply_defaults()
	save_game()
	EventBus.coins_changed.emit(coins)
