class_name UiTheme
extends RefCounted
## Shared theme for formal UI screens (UI-002 onwards): handwriting font,
## a size scale, and ink-on-paper button states. Not the project default
## theme; each formal screen applies it to its own root Control.
const FONT_PATH: String = "res://assets/fonts/LXGWWenKai-Regular.ttf"
## Size scale for 1920x1080 (canvas_items stretch scales it for 1280x720).
const SIZE_TITLE: int = 46
const SIZE_HEADING: int = 32
const SIZE_BODY: int = 24
const SIZE_SMALL: int = 18
const BUTTON_STATES: Array[String] = ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]

static var _theme: Theme

static func font() -> Font:
	return load(FONT_PATH) as Font

## Built once and shared; screens may still override per node.
static func get_theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme

static func _build() -> Theme:
	var theme: Theme = Theme.new()
	theme.default_font = font()
	theme.default_font_size = SIZE_BODY
	for type: String in ["Label", "Button"]:
		theme.set_color("font_color", type, DuskStyle.INK)
	theme.set_color("font_hover_color", "Button", DuskStyle.INK)
	theme.set_color("font_focus_color", "Button", DuskStyle.INK)
	theme.set_color("font_pressed_color", "Button", DuskStyle.INK)
	theme.set_color("font_hover_pressed_color", "Button", DuskStyle.INK)
	theme.set_color("font_disabled_color", "Button", Color(DuskStyle.INK, 0.35))
	theme.set_stylebox("normal", "Button", _box(Color(0, 0, 0, 0)))
	theme.set_stylebox("disabled", "Button", _box(Color(0, 0, 0, 0)))
	theme.set_stylebox("hover", "Button", _box(Color(DuskStyle.DUSK_BOTTOM, 0.22)))
	theme.set_stylebox("pressed", "Button", _box(Color(DuskStyle.DUSK_TOP, 0.28)))
	theme.set_stylebox("hover_pressed", "Button", _box(Color(DuskStyle.DUSK_TOP, 0.32)))
	# Focus is drawn by the screen as an ink underline and marker, not a box.
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	return theme

static func _box(color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_content_margin_all(10)
	box.content_margin_left = 22
	return box
