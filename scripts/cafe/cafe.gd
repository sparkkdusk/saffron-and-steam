extends Node2D
## Café scene orchestrator. It only WIRES systems together:
##   stations -> DrinkBuilder, serve clicks -> OrderManager -> Customer.
## No game rules live here.

@onready var order_manager: OrderManager = $Managers/OrderManager
@onready var drink_builder: DrinkBuilder = $Managers/DrinkBuilder
@onready var customer_manager: CustomerManager = $Managers/CustomerManager
@onready var barista: Barista = $Barista
@onready var stations: Node2D = $Stations
@onready var reference: Sprite2D = $ReferenceOverlay
@onready var pause_menu: CanvasLayer = $PauseMenu

const REFERENCE_PATH := "res://assets/reference/cafe_reference.png"
## Drop YOUR full-scene picture here and it becomes the game background.
const BACKDROP_PATH := "res://assets/backgrounds/cafe_full.png"


func _ready() -> void:
	for child in stations.get_children():
		if child is Interactable:
			child.interacted.connect(_on_station_interacted)
			child.hovered.connect(_on_hovered)
			child.unhovered.connect(_on_unhovered)
	drink_builder.setup(barista)
	customer_manager.setup(order_manager, $Customers, $CustomerSlots.get_children())
	customer_manager.customer_spawned.connect(_on_customer_spawned)
	if ResourceLoader.exists(REFERENCE_PATH):
		reference.texture = load(REFERENCE_PATH)
	reference.visible = false
	_apply_backdrop()
	EventBus.drink_changed.emit(drink_builder.drink)
	EventBus.coins_changed.emit(GameState.coins)
	AudioManager.start_ambience()
	customer_manager.start()
	EventBus.panel_requested.connect(func(n): if n == &"pause": pause_menu.toggle())
	EventBus.say("Welcome! A customer will arrive soon. Press R for recipes.")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_menu.toggle()
	elif event.is_action_pressed("toggle_reference"):
		reference.visible = not reference.visible
	elif event.is_action_pressed("toggle_recipes"):
		EventBus.panel_requested.emit(&"recipes")
	elif event.is_action_pressed("toggle_shop"):
		EventBus.panel_requested.emit(&"shop")
	elif event.is_action_pressed("discard_drink"):
		drink_builder.discard()


## If cafe_full.png exists: show it behind everything and hide the coloured
## placeholder boxes (background + station boxes). Stations stay clickable.
func _apply_backdrop() -> void:
	if not ResourceLoader.exists(BACKDROP_PATH):
		return
	var tex: Texture2D = load(BACKDROP_PATH)
	var backdrop := Sprite2D.new()
	backdrop.name = "Backdrop"
	backdrop.texture = tex
	backdrop.centered = false
	backdrop.scale = Vector2(426.0, 240.0) / Vector2(tex.get_size())
	add_child(backdrop)
	move_child(backdrop, 0)
	$Background.visible = false
	# Station visuals are NOT hidden any more: they draw on top of the backdrop.


# ------------------------------------------------------------------ input
func _on_hovered(who: Interactable) -> void:
	EventBus.hint_changed.emit(who.display_name)


func _on_unhovered(_who: Interactable) -> void:
	EventBus.hint_changed.emit("")


func _on_station_interacted(who: Interactable) -> void:
	match who.station_id:
		&"serve_zone":
			_serve_to(customer_manager.first_waiting())
		&"trash_bin":
			drink_builder.discard()
		_:
			drink_builder.handle_station(who.station_id)


func _on_customer_spawned(customer: Customer) -> void:
	customer.hit.interacted.connect(func(_w): _on_customer_clicked(customer))
	customer.hit.hovered.connect(_on_hovered)
	customer.hit.unhovered.connect(_on_unhovered)


func _on_customer_clicked(customer: Customer) -> void:
	if not is_instance_valid(customer) or customer.is_busy():
		return
	if drink_builder.drink.has_cup():
		_serve_to(customer)
	elif customer.order != null:
		var r := customer.order.recipe
		EventBus.say("%s wants a %s: %s" % [customer.profile.display_name, r.display_name, r.step_summary()])


# ---------------------------------------------------------------- serving
func _serve_to(customer: Customer) -> void:
	if customer == null or not is_instance_valid(customer):
		EventBus.say("Nobody is waiting right now.")
		return
	if customer.is_busy():
		return
	if drink_builder.is_busy():
		EventBus.say("Finish the current step first.")
		return
	var res := order_manager.try_serve(customer.customer_id, drink_builder.drink,
			customer.patience_ratio(), customer.profile)
	match res["result"]:
		OrderManager.ServeResult.OK:
			await _complete_order(customer, res)
		OrderManager.ServeResult.WRONG_DRINK:
			AudioManager.play_sfx("wrong")
			barista.play_oops()
			EventBus.say("Not quite! %s I'll pour it out." % res["hint"], &"bad")
			drink_builder.discard(true)
			await customer.react(res["reaction"])
		OrderManager.ServeResult.NO_DRINK:
			EventBus.say("Make a drink first. Start with the cup stack!", &"bad")
		_:
			EventBus.say("That customer is already taken care of.")


func _complete_order(customer: Customer, res: Dictionary) -> void:
	var order: Order = res["order"]
	drink_builder.consume()
	GameState.add_coins(res["payout"])           # pay once, immediately
	EventBus.order_completed.emit(order.id, res["payout"])
	barista.play_serve()
	AudioManager.play_sfx("ding")
	var tip_text := " (tip +%d)" % res["tip"] if res["tip"] > 0 else ""
	EventBus.say("Served! +%d coins%s" % [res["payout"], tip_text], &"good")
	await customer.react(res["reaction"], false)
	await customer.pay_and_leave(res["payout"])
