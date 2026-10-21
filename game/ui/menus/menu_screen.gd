class_name MenuScreen
extends Control
## UI-004 base for the full-screen title and slot screens (EXP-003 choices):
## a modal confirm sheet whose focus starts on 返回, one prompt line kept
## clear of everything else, Esc / Back handling, and a record of what was
## really drawn, read by tests. LifeUI owns every action.
const PROMPT_SIZE: Vector2 = Vector2(760, 60)
const SHEET_SIZE: Vector2 = Vector2(800, 320)
## The confirm sheet closed (by either button, Esc or Back).
signal dialog_closed

var font: Font
var clock: float = 0.0
var buttons: Array[Button] = []
var dialog: Control
var dialog_text: String = ""
var prompt: String = ""
## Called when Esc / Back reaches the screen with no sheet open.
var on_back: Callable
## What the last frame put on screen; read by tests.
var drawn: Dictionary = {}

## Ink button in paper colour for the dark dusk backgrounds.
class LightInkButton extends InkButton:
	func setup(value: String, font_size: int, stroke_seed: int) -> InkButton:
		super.setup(value, font_size, stroke_seed)
		for name: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
			add_theme_color_override(name, DuskStyle.PAPER_DAY)
		return self

	func _draw() -> void:
		var current: String = ink_state()
		if current in ["focus", "hover", "pressed"]:
			InkDraw.rough_line(self, Vector2(18, size.y - 9), Vector2(size.x * 0.72, size.y - 9), Color(DuskStyle.PAPER_DAY, 0.85), 2.4, seed, 1.4)
		if current == "focus":
			draw_colored_polygon(PackedVector2Array([Vector2(4, size.y * 0.5 - 7), Vector2(13, size.y * 0.5), Vector2(4, size.y * 0.5 + 7)]), DuskStyle.LIFE)

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	font = UiTheme.font()
	theme = UiTheme.get_theme()
	visible = false

func _process(delta: float) -> void:
	if not visible:
		return
	clock += delta
	queue_redraw()
	for button: Button in buttons:
		button.queue_redraw()
	if dialog != null:
		dialog.queue_redraw()

func light_button(parent: Node, value: String, action: Callable, size_px: int = 32) -> InkButton:
	var button: InkButton = LightInkButton.new().setup(value, size_px, 700 + buttons.size())
	button.custom_minimum_size = Vector2(320, 60)
	button.pressed.connect(action)
	parent.add_child(button)
	buttons.append(button)
	return button

func clear_buttons() -> void:
	for button: Button in buttons:
		button.queue_free()
	buttons.clear()

## The line under the screen: errors from LifeUI.save_failed() and the
## reasons a slot cannot be used. Empty hides it.
func set_prompt(text: String) -> void:
	prompt = text

func prompt_rect() -> Rect2:
	return Rect2(Vector2((size.x - PROMPT_SIZE.x) * 0.5, size.y - 196), PROMPT_SIZE)

func draw_prompt(time: Dictionary) -> void:
	drawn.erase("prompt")
	if prompt.is_empty():
		return
	var box: Rect2 = prompt_rect()
	InkDraw.paper(self, box, Color(DuskStyle.paper_color(time), 0.95), 950, DuskStyle.WOBBLE, 0)
	InkDraw.rough_rect(self, box, Color(DuskStyle.INK, 0.85), DuskStyle.INK_WIDTH, 951, DuskStyle.WOBBLE)
	var record: Dictionary = ink(self, box.position + Vector2(0, 40), prompt, UiTheme.SIZE_BODY, DuskStyle.LIFE, HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	record["rect"] = box
	drawn["prompt"] = record

## Draws text and returns what it drew: the record a test reads can only come
## from this call, with the same text and colour (review R2).
func ink(ci: CanvasItem, at: Vector2, text: String, size_px: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> Dictionary:
	ci.draw_multiline_string(font, at, text, align, width, size_px, -1, color)
	return {"text": text, "color": color}

func focus_first() -> void:
	for button: Button in buttons:
		if button.is_visible_in_tree() and not button.disabled:
			button.grab_focus()
			return

## Modal confirm sheet; focus starts on 返回 so a stray confirm does nothing.
func ask(text: String, yes_label: String, yes: Callable, refocus: Button = null) -> void:
	close_dialog(false)
	dialog_text = text
	for button: Button in buttons:
		button.focus_mode = Control.FOCUS_NONE
	dialog = Control.new()
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog.draw.connect(_draw_dialog.bind(dialog))
	add_child(dialog)
	var sheet: Rect2 = sheet_rect()
	var accept: InkButton = InkButton.new().setup(yes_label, 28, 880)
	var cancel: InkButton = InkButton.new().setup("返回", 28, 881)
	for item: InkButton in [accept, cancel]:
		item.custom_minimum_size = Vector2(260, 58)
		item.size = item.custom_minimum_size
		dialog.add_child(item)
	accept.position = sheet.position + Vector2(90, sheet.size.y - 96)
	cancel.position = sheet.position + Vector2(sheet.size.x - 350, sheet.size.y - 96)
	accept.focus_neighbor_right = accept.get_path_to(cancel)
	cancel.focus_neighbor_left = cancel.get_path_to(accept)
	accept.pressed.connect(func() -> void:
		close_dialog(false)
		yes.call()
		# Still here (e.g. the save failed): give the focus back to what asked,
		# so keys and pads can carry on (review R1).
		# The freed sheet's button may still hold the focus until deletion.
		if is_visible_in_tree() and dialog == null and not buttons.has(get_viewport().gui_get_focus_owner()):
			if is_instance_valid(refocus):
				refocus.grab_focus()
			else:
				focus_first())
	cancel.pressed.connect(func() -> void: close_dialog())
	dialog.set_meta("accept", accept)
	dialog.set_meta("cancel", cancel)
	dialog.set_meta("refocus", refocus)
	cancel.grab_focus()

func close_dialog(restore_focus: bool = true) -> void:
	if dialog == null:
		return
	var refocus: Button = dialog.get_meta("refocus") as Button
	dialog.queue_free()
	dialog = null
	drawn.erase("dialog")
	for button: Button in buttons:
		button.focus_mode = Control.FOCUS_ALL
	dialog_closed.emit()
	if restore_focus:
		if is_instance_valid(refocus):
			refocus.grab_focus()
		else:
			focus_first()

func dialog_button(which: String) -> Button:
	return dialog.get_meta(which) as Button if dialog != null else null

func sheet_rect() -> Rect2:
	return Rect2((size - SHEET_SIZE) * 0.5, SHEET_SIZE)

func sheet_time() -> Dictionary:
	return {"day": 3, "day_progress": 0.55}

## sheet: the dialog node itself, still valid while a closed one is freed.
func _draw_dialog(sheet_node: Control) -> void:
	if sheet_node != dialog:
		return
	var time: Dictionary = sheet_time()
	dialog.draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.03, 0.04, 0.6))
	var sheet: Rect2 = sheet_rect()
	InkDraw.paper(dialog, sheet, Color(DuskStyle.paper_color(time), 0.96), 870, DuskStyle.WOBBLE, 6)
	DuskStyle.panel(dialog, sheet, time, 871)
	var record: Dictionary = ink(dialog, sheet.position + Vector2(40, 96), dialog_text, UiTheme.SIZE_HEADING, DuskStyle.INK, HORIZONTAL_ALIGNMENT_CENTER, sheet.size.x - 80)
	record["rect"] = sheet
	drawn["dialog"] = record

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause") or event.is_action_pressed("use_item"):
		if dialog != null:
			close_dialog()
		elif on_back.is_valid():
			on_back.call()
		get_viewport().set_input_as_handled()
