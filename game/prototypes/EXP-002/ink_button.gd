extends Button
## Ink-on-paper button: plain text, a warm wash on hover/focus, a deeper wash
## when pressed, a hand-drawn underline when selected, faded when disabled.
const Ink = preload("res://prototypes/EXP-002/ink.gd")
const Style = preload("res://prototypes/EXP-002/style.gd")

var seed: int = 0
var style: RefCounted

func setup(value: String, font_size: int, stroke_seed: int, visual: RefCounted) -> void:
	text = value
	seed = stroke_seed
	style = visual
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	custom_minimum_size = Vector2(360, 60)
	add_theme_font_size_override("font_size", font_size)
	for name: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		add_theme_color_override(name, Style.INK)
	add_theme_color_override("font_disabled_color", Color(Style.INK, 0.35))
	add_theme_stylebox_override("normal", _box(Color(0, 0, 0, 0)))
	add_theme_stylebox_override("disabled", _box(Color(0, 0, 0, 0)))
	add_theme_stylebox_override("hover", _box(Color(Style.DUSK_BOTTOM, 0.22)))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	add_theme_stylebox_override("pressed", _box(Color(Style.DUSK_TOP, 0.28)))
	add_theme_stylebox_override("hover_pressed", _box(Color(Style.DUSK_TOP, 0.32)))
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _box(color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_content_margin_all(10)
	box.content_margin_left = 22
	return box

## Which visual state is showing; also used by the smoke test.
func ink_state() -> String:
	if disabled:
		return "disabled"
	if button_pressed or get_draw_mode() == DRAW_PRESSED or get_draw_mode() == DRAW_HOVER_PRESSED:
		return "pressed"
	if has_focus():
		return "focus"
	if is_hovered():
		return "hover"
	return "normal"

func _draw() -> void:
	var current: String = ink_state()
	if current == "focus" or current == "hover" or current == "pressed":
		Ink.rough_line(self, Vector2(18, size.y - 9), Vector2(size.x * 0.72, size.y - 9), Color(Style.INK, 0.85), 2.4, seed, 1.4)
	if current == "focus":
		draw_colored_polygon(PackedVector2Array([Vector2(4, size.y * 0.5 - 7), Vector2(13, size.y * 0.5), Vector2(4, size.y * 0.5 + 7)]), Style.LIFE)
