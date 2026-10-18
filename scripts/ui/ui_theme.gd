class_name UITheme
extends RefCounted
## Builds the pixel-style UI theme in code (no theme file needed).
## To use your own pixel font: put it at res://assets/fonts/pixel_font.ttf

const FONT_PATH := "res://assets/fonts/pixel_font.ttf"
const FONT_SIZE := 8

const COL_PANEL := Color(0.23, 0.13, 0.09)
const COL_PANEL_LIGHT := Color(0.35, 0.21, 0.14)
const COL_BORDER := Color(0.78, 0.6, 0.18)
const COL_TEXT := Color(0.98, 0.94, 0.82)
const COL_TEXT_DIM := Color(0.75, 0.65, 0.5)
const COL_GOOD := Color(0.6, 0.85, 0.5)
const COL_BAD := Color(0.95, 0.5, 0.45)

static var _font: Font = null
static var _theme: Theme = null


static func get_font() -> Font:
	if _font == null:
		if ResourceLoader.exists(FONT_PATH):
			_font = load(FONT_PATH)
		else:
			_font = ThemeDB.fallback_font
	return _font


static func box(bg: Color, border: Color, margin: float = 3.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(0)
	sb.anti_aliasing = false
	sb.content_margin_left = margin + 2
	sb.content_margin_right = margin + 2
	sb.content_margin_top = margin
	sb.content_margin_bottom = margin
	return sb


static func build() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = get_font()
	t.default_font_size = FONT_SIZE
	# Labels
	t.set_color("font_color", "Label", COL_TEXT)
	# Buttons: normal / hover / pressed / disabled
	t.set_stylebox("normal", "Button", box(COL_PANEL_LIGHT, COL_BORDER.darkened(0.3)))
	t.set_stylebox("hover", "Button", box(COL_PANEL_LIGHT.lightened(0.15), COL_BORDER))
	t.set_stylebox("pressed", "Button", box(COL_PANEL.darkened(0.2), COL_BORDER))
	t.set_stylebox("disabled", "Button", box(COL_PANEL, COL_PANEL_LIGHT))
	t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), COL_TEXT))
	t.set_color("font_color", "Button", COL_TEXT)
	t.set_color("font_hover_color", "Button", Color(1, 1, 0.8))
	t.set_color("font_disabled_color", "Button", COL_TEXT_DIM)
	# Panels
	t.set_stylebox("panel", "Panel", box(COL_PANEL, COL_BORDER, 4.0))
	t.set_stylebox("panel", "PanelContainer", box(COL_PANEL, COL_BORDER, 4.0))
	# Slider
	t.set_stylebox("slider", "HSlider", box(COL_PANEL.darkened(0.3), COL_BORDER.darkened(0.4), 1.0))
	t.set_stylebox("grabber_area", "HSlider", box(COL_BORDER, COL_BORDER, 1.0))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(COL_BORDER.lightened(0.2), COL_BORDER, 1.0))
	var img := Image.create(6, 10, false, Image.FORMAT_RGBA8)
	img.fill(COL_TEXT)
	var tex := ImageTexture.create_from_image(img)
	t.set_icon("grabber", "HSlider", tex)
	t.set_icon("grabber_highlight", "HSlider", tex)
	t.set_icon("grabber_disabled", "HSlider", tex)
	_theme = t
	return t
