class_name DrinkBuilder
extends Node
## Handles the preparation steps. Clicking a station asks this node to perform
## the matching step. Steps take time (progress bar) so they feel physical.

var drink: DrinkState = DrinkState.new()
var _busy: bool = false
var _barista: Barista = null


func setup(barista: Barista) -> void:
	_barista = barista


func is_busy() -> bool:
	return _busy


func handle_station(station_id: StringName) -> void:
	var step_id := StepDefs.step_for_station(station_id)
	if step_id == &"":
		return
	if _busy:
		EventBus.say("One moment, still working on it!")
		return
	var def := StepDefs.get_def(step_id)
	if step_id == &"cup":
		if drink.has_cup():
			EventBus.say("You already have a cup. Right-click or use the bin to pour it out.", &"bad")
			AudioManager.play_sfx("wrong")
			return
	elif not drink.has_cup():
		EventBus.say("Grab a cup first!", &"bad")
		AudioManager.play_sfx("wrong")
		return
	if drink.steps.size() >= DrinkState.MAX_STEPS:
		EventBus.say("That cup is full! Pour it out and start again.", &"bad")
		AudioManager.play_sfx("wrong")
		return

	_busy = true
	var duration: float = def["duration"]
	AudioManager.play_sfx(def["sfx"])
	if _barista != null:
		_barista.play_prepare(duration)
	var tween := create_tween()
	tween.tween_method(func(r: float): EventBus.action_progress.emit(station_id, r), 0.0, 1.0, duration)
	await tween.finished
	EventBus.action_progress.emit(station_id, -1.0)
	drink.add_step(step_id)
	_busy = false
	if _barista != null:
		_barista.play_idle()
	EventBus.drink_changed.emit(drink)
	EventBus.say(def["message"], &"good")


## Throw the drink away (bin / right-click).
func discard(silent: bool = false) -> void:
	if _busy:
		return
	if drink.is_empty():
		if not silent:
			EventBus.say("Nothing to pour out.")
		return
	drink.clear()
	EventBus.drink_changed.emit(drink)
	if not silent:
		AudioManager.play_sfx("trash")
		EventBus.say("Poured it out. Fresh start!")


## The drink was handed to a customer.
func consume() -> void:
	drink.clear()
	EventBus.drink_changed.emit(drink)
