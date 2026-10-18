extends Node
## Builds the barista animations and puts the station / decor PNGs on screen
## automatically, so no Texture Path or SpriteFrames editing is needed.
## Put this node as the FIRST child of the Cafe node.

# If you ever draw art at 3x size (e.g. barista 168x216), set this to 1.0 / 3.0.
const ART_SCALE := 1.0

const SPRITES := "res://assets/sprites/"

const STATION_ART := {
	"CupStack": "st_cups.png",
	"MilkJug": "st_milk.png",
	"MatchaTin": "st_matcha.png",
	"StrawberrySyrup": "st_syrup.png",
	"TrashBin": "st_bin.png",
	"ServeZone": "st_tray.png",
	"EspressoMachine": "st_machine.png",
}
const DECOR_ART := {
	"Plant": "decor_plant.png",
	"Lantern": "decor_lantern.png",
	"Cat": "decor_cat.png",
}


func _enter_tree() -> void:
	# Runs before Barista's _ready, so barista.gd finds the Anim node.
	_build_barista()


func _ready() -> void:
	# Deferred so it runs after every placeholder has finished its own setup.
	_apply_art.call_deferred()


func _tex(file: String) -> Texture2D:
	var path := SPRITES + file
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("ArtSetup: missing " + path)
	return null


func _build_barista() -> void:
	var barista := get_parent().get_node_or_null("Barista")
	if barista == null:
		push_warning("ArtSetup: no Barista node found")
		return
	var anim := barista.get_node_or_null("Anim") as AnimatedSprite2D
	if anim == null:
		anim = AnimatedSprite2D.new()
		anim.name = "Anim"
		barista.add_child(anim)
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	var defs := [
		["idle", "barista_idle_", 4, 4.0, true],
		["prepare", "barista_prepare_", 4, 8.0, true],
		["serve", "barista_serve_", 3, 8.0, false],
	]
	var first: Texture2D = null
	for d in defs:
		frames.add_animation(d[0])
		frames.set_animation_speed(d[0], d[3])
		frames.set_animation_loop(d[0], d[4])
		for i in range(1, d[2] + 1):
			var t := _tex("%s%d.png" % [d[1], i])
			if t:
				frames.add_frame(d[0], t)
				if first == null:
					first = t
	anim.sprite_frames = frames
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anim.centered = false
	anim.scale = Vector2.ONE * ART_SCALE
	if first:
		var s := first.get_size()
		anim.offset = Vector2(-s.x / 2.0, -s.y)   # feet at bottom centre
	anim.animation = "idle"
	anim.play("idle")


func _apply_art() -> void:
	var cafe := get_parent()
	_replace_visuals(cafe.get_node_or_null("Stations"), STATION_ART)
	_replace_visuals(cafe.get_node_or_null("Decor"), DECOR_ART)


func _replace_visuals(root: Node, table: Dictionary) -> void:
	if root == null:
		return
	for node_name in table:
		var item := root.get_node_or_null(node_name)
		if item == null:
			push_warning("ArtSetup: node not found: " + node_name)
			continue
		var t := _tex(table[node_name])
		if t == null:
			continue
		var old := item.get_node_or_null("Visual")
		if old:
			old.visible = false
		var old_art := item.get_node_or_null("Art")
		if old_art:
			old_art.queue_free()
		var sp := Sprite2D.new()
		sp.name = "Art"
		sp.texture = t
		sp.centered = true
		sp.scale = Vector2.ONE * ART_SCALE
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		item.add_child(sp)
