class_name InkButton
extends Button
## Ink-on-paper menu button (EXP-002 sample two, UI-001 theme): plain text, a
## warm wash on hover, a deeper wash when pressed, and the focus marker the
## theme leaves to the screen: a hand-drawn underline plus a vermilion tick.
var seed: int = 0

func setup(value: String, font_size: int, stroke_seed: int) -> InkButton:
	text = value
	seed = stroke_seed
	theme = UiTheme.get_theme()
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	custom_minimum_size = Vector2(360, 60)
	add_theme_font_size_override("font_size", font_size)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	return self

## Which visual state is showing; also read by tests.
func ink_state() -> String:
	if disabled:
		return "disabled"
	if get_draw_mode() == DRAW_PRESSED or get_draw_mode() == DRAW_HOVER_PRESSED:
		return "pressed"
	if has_focus():
		return "focus"
	if is_hovered():
		return "hover"
	return "normal"

func _draw() -> void:
	var current: String = ink_state()
	if current == "focus" or current == "hover" or current == "pressed":
		InkDraw.rough_line(self, Vector2(18, size.y - 9), Vector2(size.x * 0.72, size.y - 9), Color(DuskStyle.INK, 0.85), 2.4, seed, 1.4)
	if current == "focus":
		draw_colored_polygon(PackedVector2Array([Vector2(4, size.y * 0.5 - 7), Vector2(13, size.y * 0.5), Vector2(4, size.y * 0.5 + 7)]), DuskStyle.LIFE)
