class_name OrderManager
extends Node
## Owns all orders and decides whether a served drink is accepted.
## It never touches visuals: it only returns a result dictionary.

enum ServeResult { OK, WRONG_DRINK, NO_ORDER, ALREADY_COMPLETED, NO_DRINK }

var _orders: Dictionary = {}       # order id -> Order
var _by_customer: Dictionary = {}  # customer id -> order id
var _next_id: int = 1


func create_order(customer_id: int, recipe: Recipe) -> Order:
	var order := Order.new()
	order.id = _next_id
	_next_id += 1
	order.customer_id = customer_id
	order.recipe = recipe
	_orders[order.id] = order
	_by_customer[customer_id] = order.id
	return order


func get_order_for_customer(customer_id: int) -> Order:
	if not _by_customer.has(customer_id):
		return null
	return _orders.get(_by_customer[customer_id])


func try_serve(customer_id: int, drink: DrinkState, wait_ratio: float, profile: CustomerProfile) -> Dictionary:
	var result := {"result": ServeResult.NO_ORDER, "order": null, "payout": 0, "tip": 0,
			"reaction": &"neutral", "hint": ""}
	var order := get_order_for_customer(customer_id)
	if order == null:
		return result
	result["order"] = order
	if order.state == Order.State.COMPLETED:
		result["result"] = ServeResult.ALREADY_COMPLETED
		return result
	if drink == null or not drink.has_cup():
		result["result"] = ServeResult.NO_DRINK
		return result
	if not order.recipe.matches(drink):
		result["result"] = ServeResult.WRONG_DRINK
		result["reaction"] = Economy.reaction_for_wrong(drink)
		result["hint"] = order.recipe.mismatch_hint(drink)
		return result
	# Success: mark completed FIRST so nothing can pay out twice.
	order.state = Order.State.COMPLETED
	var pay := Economy.payout(order.recipe, profile, wait_ratio)
	result["result"] = ServeResult.OK
	result["payout"] = pay["total"]
	result["tip"] = pay["tip"]
	result["reaction"] = Economy.reaction_for_ok(wait_ratio)
	return result


func forget_customer(customer_id: int) -> void:
	if _by_customer.has(customer_id):
		_orders.erase(_by_customer[customer_id])
		_by_customer.erase(customer_id)
