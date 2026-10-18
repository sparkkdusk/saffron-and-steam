class_name CustomerManager
extends Node
## Spawns customers at random times, gives each a unique id and an order.
## Supports several customers at once: raise `max_customers` and add slots.

signal customer_spawned(customer: Customer)

@export var customer_scene: PackedScene
@export var min_delay: float = 3.0
@export var max_delay: float = 7.0
@export var max_customers: int = 1

var _order_manager: OrderManager
var _layer: Node2D
var _slots: Array = []                 # Array[Marker2D]
var _slot_owner: Dictionary = {}       # slot index -> customer id
var _customers: Dictionary = {}        # customer id -> Customer
var _next_id: int = 1
var _timer: Timer
var _running: bool = false


func setup(order_manager: OrderManager, layer: Node2D, slots: Array) -> void:
	_order_manager = order_manager
	_layer = layer
	_slots = slots
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer)
	add_child(_timer)


func start() -> void:
	_running = true
	_schedule()


func stop() -> void:
	_running = false
	if _timer != null:
		_timer.stop()


func get_customer(id: int) -> Customer:
	return _customers.get(id)


func first_waiting() -> Customer:
	var best: Customer = null
	for id in _customers:
		var c: Customer = _customers[id]
		if is_instance_valid(c) and c.is_waiting():
			if best == null or c.customer_id < best.customer_id:
				best = c
	return best


func _schedule() -> void:
	if not _running or _customers.size() >= max_customers or not _timer.is_stopped():
		return
	_timer.start(randf_range(min_delay, max_delay))


func _on_timer() -> void:
	var slot_index := _free_slot()
	if slot_index == -1 or _customers.size() >= max_customers:
		return
	_spawn(slot_index)


func _free_slot() -> int:
	for i in _slots.size():
		if not _slot_owner.has(i):
			return i
	return -1


func _spawn(slot_index: int) -> void:
	if GameState.customer_profiles.is_empty() or GameState.get_unlocked_recipes().is_empty():
		return
	var profile: CustomerProfile = GameState.customer_profiles.pick_random()
	var customer: Customer = customer_scene.instantiate()
	var id := _next_id
	_next_id += 1
	var slot: Marker2D = _slots[slot_index]
	customer.setup(id, profile, slot.global_position)
	customer.left.connect(_on_customer_left)
	_layer.add_child(customer)
	_customers[id] = customer
	_slot_owner[slot_index] = id
	AudioManager.play_sfx("bell")
	customer_spawned.emit(customer)
	await customer.walk_in()
	if not is_instance_valid(customer):
		return
	var recipe := _pick_recipe(profile)
	var order := _order_manager.create_order(id, recipe)
	customer.set_order(order)
	EventBus.order_placed.emit(order.id, id, recipe.id)


func _pick_recipe(profile: CustomerProfile) -> Recipe:
	var pool: Array = []
	for r in GameState.get_unlocked_recipes():
		pool.append(r)
		if r.id == profile.favorite_recipe:
			pool.append(r)   # favourites appear twice as often
			pool.append(r)
	return pool.pick_random()


func _on_customer_left(id: int) -> void:
	_customers.erase(id)
	for i in _slot_owner.keys():
		if _slot_owner[i] == id:
			_slot_owner.erase(i)
	_order_manager.forget_customer(id)
	EventBus.customer_left.emit(id)
	_schedule()
