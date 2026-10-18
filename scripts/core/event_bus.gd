extends Node
## Global signal hub. Holds NO state. It only declares events that cross
## scene boundaries so scenes never need hard references to each other.

signal coins_changed(total: int)
signal feedback_requested(message: String, kind: StringName)   # kind: &"info" | &"good" | &"bad"
signal hint_changed(text: String)                              # hover text
signal drink_changed(drink: RefCounted)                        # DrinkState in hand
signal action_progress(station_id: StringName, ratio: float)   # ratio < 0 hides the bar
signal order_placed(order_id: int, customer_id: int, recipe_id: StringName)
signal order_completed(order_id: int, payout: int)
signal customer_left(customer_id: int)
signal recipe_unlocked(recipe_id: StringName)
signal decor_purchased(decor_id: StringName)
signal panel_requested(panel_name: StringName)                 # &"recipes" | &"shop"


func say(message: String, kind: StringName = &"info") -> void:
	feedback_requested.emit(message, kind)
