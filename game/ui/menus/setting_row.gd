class_name SettingRow
extends Control
## UI-006: one focusable line of the settings page, drawn in ink. Kinds:
## "slider" (0-100 in steps of 5), "choice" (cycles a list), "toggle" and
## "action". Left / right adjust, Enter / A toggles or activates, the mouse
## clicks or drags. The page turns changes into SettingsService calls.
signal changed(value: Variant)
signal activated
const STEP: int = 5
const VALUE_X: float = 190.0

var kind: String = "action"
var label: String = ""
var value: Variant
## choice: [[value, text], ...]
var choices: Array = []
var seed: int = 0
var font: Font
## What the last frame put on screen; read by tests.
var drawn: Dictionary = {}

func setup(row_kind: String, title: String, initial: Variant, stroke_seed: int, options: Array = []) -> SettingRow:
	kind = row_kind
	label = title
	value = initial
	choices = options
	seed = stroke_seed
	font = UiTheme.font()
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	return self

## Shows a value from the settings service without emitting a change.
func show_value(current: Variant) -> void:
	value = current
	queue_redraw()

func value_text() -> String:
	match kind:
		"slider":
			return str(roundi(float(value)))
		"toggle":
			return "开" if bool(value) else "关"
		"choice":
			for option: Array in choices:
				if option[0] == value:
					return str(option[1])
	return ""

func bar_rect() -> Rect2:
	return Rect2(VALUE_X, size.y * 0.5 - 4.0, size.x - VALUE_X - 70.0, 8.0)

func _choice_index() -> int:
	for i: int in range(choices.size()):
		if choices[i][0] == value:
			return i
	return 0

func step(direction: int) -> void:
	match kind:
		"slider":
			commit(clampf(float(roundi(float(value) / STEP) * STEP + STEP * direction), 0.0, 100.0))
		"choice":
			commit(choices[posmod(_choice_index() + direction, choices.size())][0])
		"toggle":
			commit(not bool(value))

## Sets a value as if the player chose it (emits changed).
func commit(next: Variant) -> void:
	if next == value:
		return
	value = next
	queue_redraw()
	changed.emit(value)

func _slider_at(x: float) -> void:
	var bar: Rect2 = bar_rect()
	commit(float(roundi(clampf((x - bar.position.x) / bar.size.x, 0.0, 1.0) * 100.0)))

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left", true) and kind != "action":
		step(-1)
	elif event.is_action_pressed("ui_right", true) and kind != "action":
		step(1)
	elif event.is_action_pressed("ui_accept") and kind != "slider":
		if kind == "action":
			activated.emit()
		else:
			step(1)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		grab_focus()
		match kind:
			"slider": _slider_at(event.position.x)
			"choice": step(-1 if event.position.x < VALUE_X + 40.0 else 1)
			"toggle": step(1)
			_: activated.emit()
	elif event is InputEventMouseMotion and kind == "slider" and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_slider_at(event.position.x)
	else:
		return
	accept_event()

func _draw() -> void:
	var focused: bool = has_focus()
	var mid: float = size.y * 0.5
	if focused:
		InkDraw.rough_line(self, Vector2(18, size.y - 6), Vector2(VALUE_X - 20, size.y - 6), Color(DuskStyle.INK, 0.85), 2.4, seed, 1.4)
		draw_colored_polygon(PackedVector2Array([Vector2(4, mid - 7), Vector2(13, mid), Vector2(4, mid + 7)]), DuskStyle.LIFE)
	draw_string(font, Vector2(24, mid + 9), label, HORIZONTAL_ALIGNMENT_LEFT, VALUE_X - 30, UiTheme.SIZE_BODY, DuskStyle.INK)
	var shown: String = value_text()
	match kind:
		"slider":
			var bar: Rect2 = bar_rect()
			var fill: float = clampf(float(value) / 100.0, 0.0, 1.0)
			InkDraw.rough_line(self, Vector2(bar.position.x, mid), Vector2(bar.end.x, mid), Color(DuskStyle.INK, 0.25), 6.0, seed + 1, 0.6)
			if fill > 0.0:
				InkDraw.rough_line(self, Vector2(bar.position.x, mid), Vector2(bar.position.x + bar.size.x * fill, mid), DuskStyle.POSSIBILITY, 6.0, seed + 2, 0.6)
			draw_circle(Vector2(bar.position.x + bar.size.x * fill, mid), 10.0 if focused else 8.0, DuskStyle.INK)
			draw_string(font, Vector2(bar.end.x + 16, mid + 8), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_BODY, DuskStyle.INK)
		"choice":
			var arrows: Color = Color(DuskStyle.INK, 0.9 if focused else 0.4)
			draw_string(font, Vector2(VALUE_X, mid + 9), "‹", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_BODY, arrows)
			draw_string(font, Vector2(VALUE_X + 30, mid + 9), shown, HORIZONTAL_ALIGNMENT_CENTER, 180, UiTheme.SIZE_BODY, DuskStyle.INK)
			draw_string(font, Vector2(VALUE_X + 222, mid + 9), "›", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_BODY, arrows)
		"toggle":
			var box: Rect2 = Rect2(VALUE_X, mid - 14, 60, 28)
			InkDraw.rough_rect(self, box, Color(DuskStyle.INK, 0.8), 1.6, seed + 3, 0.6)
			var knob: Vector2 = Vector2(box.end.x - 14 if bool(value) else box.position.x + 14, mid)
			draw_circle(knob, 9, DuskStyle.LIFE if bool(value) else Color(DuskStyle.INK, 0.45))
			draw_string(font, Vector2(box.end.x + 16, mid + 8), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_BODY, DuskStyle.INK)
	drawn = {"label": label, "text": shown, "focused": focused, "rect": get_rect()}
