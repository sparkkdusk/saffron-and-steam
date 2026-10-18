class_name InfoPanel
extends PanelContainer
## The "How to play" panel (used by title screen and pause menu).

signal closed

const TEXT := """HOW TO PLAY
1. A customer arrives and shows an order bubble.
2. Left-click the stations in the right order:
   Cup stack > Espresso machine / Matcha tin >
   Milk jug > Strawberry syrup
3. Click the glowing Serve tray (or the customer)
   to hand over the drink.
4. Wrong drink? No problem - you get a hint and
   can start again.

CONTROLS
Left click   use a station / serve
Right click  pour out the drink in your hands
R  recipe book      S  shop
Esc  pause menu     F2  art reference overlay"""


func _ready() -> void:
	theme = UITheme.build()
	process_mode = Node.PROCESS_MODE_ALWAYS
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var l := Label.new()
	l.text = TEXT
	box.add_child(l)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func(): closed.emit())
	box.add_child(back)
	add_child(box)
