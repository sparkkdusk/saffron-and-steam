extends SceneTree
## Headless test runner.
## Run from the project folder:
##   godot --headless --path . -s tests/run_tests.gd
## Exit code 0 = all passed.

var _failed := 0
var _passed := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		print("  PASS  ", label)
	else:
		_failed += 1
		print("  FAIL  ", label)


func _drink(steps: Array) -> DrinkState:
	var d := DrinkState.new()
	for s in steps:
		d.add_step(StringName(s))
	return d


func _run() -> void:
	await process_frame
	var gs: Node = root.get_node("GameState")
	var recipes: Dictionary = gs.recipes

	print("== Recipes ==")
	_check(recipes.size() == 4, "4 recipes loaded")
	var latte: Recipe = recipes[&"latte"]
	_check(latte.matches(_drink(["cup", "brew_espresso", "add_milk"])), "latte matches correct steps")
	_check(not latte.matches(_drink(["cup", "brew_espresso"])), "latte rejects missing milk")
	_check(not latte.matches(_drink(["cup", "add_milk", "brew_espresso"])), "latte rejects wrong order")
	_check(not latte.matches(_drink(["cup", "brew_espresso", "add_milk", "add_milk"])), "latte rejects extra ingredient")
	_check(latte.mismatch_hint(_drink(["cup", "brew_espresso"])).contains("Milk"), "hint names the missing step")
	var matcha: Recipe = recipes[&"strawberry_matcha"]
	_check(matcha.matches(_drink(["cup", "add_matcha", "add_milk", "add_strawberry"])), "strawberry matcha matches")

	print("== Economy ==")
	var prof: CustomerProfile = gs.customer_profiles[0]
	var quick := Economy.payout(latte, prof, 0.2)
	_check(quick["total"] >= latte.base_price + 1, "fast service earns a tip")
	var slow := Economy.payout(latte, prof, 1.5)
	_check(slow["tip"] <= 1, "slow service earns little/no tip")

	print("== OrderManager ==")
	var om := OrderManager.new()
	var o := om.create_order(7, latte)
	var good := _drink(["cup", "brew_espresso", "add_milk"])
	var r1 := om.try_serve(7, good, 0.2, prof)
	_check(r1["result"] == OrderManager.ServeResult.OK and r1["payout"] > 0, "correct drink accepted and paid")
	var r2 := om.try_serve(7, good, 0.2, prof)
	_check(r2["result"] == OrderManager.ServeResult.ALREADY_COMPLETED and r2["payout"] == 0, "second serve pays nothing")
	var o2 := om.create_order(8, latte)
	var r3 := om.try_serve(8, _drink(["cup", "brew_espresso"]), 0.2, prof)
	_check(r3["result"] == OrderManager.ServeResult.WRONG_DRINK and o2.state == Order.State.OPEN, "wrong drink rejected, order stays open")
	var r4 := om.try_serve(8, DrinkState.new(), 0.2, prof)
	_check(r4["result"] == OrderManager.ServeResult.NO_DRINK, "empty hands rejected")
	var r5 := om.try_serve(99, good, 0.2, prof)
	_check(r5["result"] == OrderManager.ServeResult.NO_ORDER, "unknown customer rejected")
	om.free()

	print("== Save / load ==")
	gs.coins = 0
	gs.unlocked_recipes.clear()
	gs.owned_decor.clear()
	gs._apply_defaults()
	gs.add_coins(100)
	_check(gs.buy_recipe(&"double_espresso"), "buy recipe with enough coins")
	_check(gs.coins == 60, "coins deducted")
	_check(not gs.buy_recipe(&"double_espresso"), "cannot buy twice")
	_check(gs.buy_decor(&"plant"), "buy decoration")
	_check(not gs.buy_decor(&"cat") or gs.coins >= 0, "coins never go negative")
	gs.music_volume = 0.3
	gs.save_game()
	var saved_coins: int = gs.coins
	gs.coins = 999
	gs.unlocked_recipes.clear()
	gs.owned_decor.clear()
	gs.load_game()
	_check(gs.coins == saved_coins, "coins restored from file")
	_check(gs.is_recipe_unlocked(&"double_espresso"), "unlocked recipe restored")
	_check(gs.owns_decor(&"plant"), "decoration restored")
	_check(is_equal_approx(gs.music_volume, 0.3), "volume restored")

	print("== Full gameplay loop ==")
	gs.reset_progress()
	var cafe: Node = load("res://scenes/cafe/cafe.tscn").instantiate()
	root.add_child(cafe)
	await process_frame
	var cm = cafe.customer_manager
	var db = cafe.drink_builder
	var customer = await _wait_for_customer(cm)
	_check(customer != null, "a customer arrives and places an order")
	if customer != null:
		var recipe: Recipe = customer.order.recipe
		print("    order: ", recipe.display_name, " -> ", recipe.step_summary())
		await db.handle_station(&"milk_jug")
		_check(db.drink.is_empty(), "milk without a cup is refused")
		for step in recipe.steps:
			await db.handle_station(StepDefs.DEFS[step]["station"])
		_check(recipe.matches(db.drink), "player built the requested drink")
		var before: int = gs.coins
		cafe._serve_to(customer)   # not awaited: runs the full reaction in the background
		await process_frame
		_check(gs.coins > before, "coins awarded (%d -> %d)" % [before, gs.coins])
		var after: int = gs.coins
		cafe._serve_to(customer)
		await process_frame
		_check(gs.coins == after, "serving the same customer again pays nothing")
		await create_timer(5.5).timeout   # let them pay and leave
		_check(not is_instance_valid(customer), "customer left the café")

	var c2 = await _wait_for_customer(cm)
	_check(c2 != null, "next customer arrives")
	if c2 != null:
		await db.handle_station(&"cup_stack")
		var coins_before: int = gs.coins
		await cafe._serve_to(c2)
		_check(gs.coins == coins_before, "wrong drink earns nothing")
		_check(c2.order.state == Order.State.OPEN, "order still open after wrong drink")
		_check(db.drink.is_empty(), "wrong drink was poured out")

	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.cfg"))
	print("")
	print("RESULT: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _wait_for_customer(cm):
	var waited := 0.0
	while waited < 25.0:
		var c = cm.first_waiting()
		if c != null:
			return c
		await create_timer(0.25).timeout
		waited += 0.25
	return null
