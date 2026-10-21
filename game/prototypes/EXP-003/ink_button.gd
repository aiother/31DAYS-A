extends Button
## EXP-003 ink menu button on the UI-001 theme: hand-drawn underline and a
## vermilion tick for focus (the theme leaves focus drawing to the screen).
var seed: int = 0
## Optional: "light" draws ink in paper colour for dark backgrounds.
var tone: String = "ink"

func setup(value: String, font_size: int, stroke_seed: int, button_tone: String = "ink") -> Button:
	text = value
	seed = stroke_seed
	tone = button_tone
	theme = UiTheme.get_theme()
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	custom_minimum_size = Vector2(320, 58)
	add_theme_font_size_override("font_size", font_size)
	if tone == "light":
		for name: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
			add_theme_color_override(name, DuskStyle.PAPER_DAY)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(grab_focus)
	return self

func ink_state() -> String:
	if disabled:
		return "disabled"
	if has_focus():
		return "focus"
	if is_hovered():
		return "hover"
	return "normal"

func _draw() -> void:
	var line: Color = DuskStyle.PAPER_DAY if tone == "light" else DuskStyle.INK
	if ink_state() in ["focus", "hover"]:
		InkDraw.rough_line(self, Vector2(18, size.y - 9), Vector2(size.x * 0.72, size.y - 9), Color(line, 0.85), 2.4, seed, 1.4)
	if ink_state() == "focus":
		draw_colored_polygon(PackedVector2Array([Vector2(4, size.y * 0.5 - 7), Vector2(13, size.y * 0.5), Vector2(4, size.y * 0.5 + 7)]), DuskStyle.LIFE)
