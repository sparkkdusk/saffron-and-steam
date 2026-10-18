extends SceneTree
## Dev helper: renders the café, plays part of an order and saves screenshots.
##   xvfb-run -a godot --path . -s tests/screenshot.gd
func _initialize() -> void:
	_run.call_deferred()

func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("/tmp/shot_%s.png" % name)

func _run() -> void:
	await process_frame
	var cafe: Node = load("res://scenes/cafe/cafe.tscn").instantiate()
	root.add_child(cafe)
	var cm = cafe.customer_manager
	var db = cafe.drink_builder
	var c = null
	var waited := 0.0
	while c == null and waited < 20.0:
		await create_timer(0.25).timeout
		waited += 0.25
		c = cm.first_waiting()
	await create_timer(0.5).timeout
	await _shot("waiting")
	root.get_node("EventBus").say("Espresso brewed!", &"good")
	cafe._on_hovered(cafe.get_node("Stations/MilkJug"))
	await _shot("ui")
	for s in [&"cup_stack", &"espresso_machine"]:
		await db.handle_station(s)
	await _shot("drink")
	cafe.reference.visible = true
	await _shot("reference")
	quit(0)
