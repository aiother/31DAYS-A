extends Control
## Shared base for EXP-003 screens: preview hooks, ink text, a modal confirm
## sheet, and a drawn record the smoke test reads.
const InkButton = preload("res://prototypes/EXP-003/ink_button.gd")
const Slots = preload("res://prototypes/EXP-003/mock_slots.gd")
## Fixed dusk for the title screens: day three, late afternoon.
const MOOD: Dictionary = {"day": 3, "day_progress": 0.55, "final_active": false}

var preview: Control
var data: RefCounted
var font: Font
var clock: float = 0.0
var buttons: Array[Button] = []
var dialog: Control
var dialog_text: String = ""
var drawn: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	font = UiTheme.font()
	build()

## Subclasses add their buttons here.
func build() -> void:
	pass

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()
	if dialog != null:
		dialog.queue_redraw()

func ink_text(at: Vector2, value: String, size_px: int, color: Color = DuskStyle.INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	draw_string(font, at, value, align, width, size_px, color)

func make_button(parent: Node, value: String, action: Callable, size_px: int = 30, button_tone: String = "ink") -> Button:
	var button: Button = InkButton.new().setup(value, size_px, 300 + buttons.size(), button_tone)
	button.pressed.connect(action)
	parent.add_child(button)
	buttons.append(button)
	return button

func focus_first() -> void:
	for button: Button in buttons:
		if button.is_visible_in_tree() and not button.disabled:
			button.grab_focus()
			return

## Modal confirm sheet in the middle of the screen; focus starts on cancel.
func ask(text: String, yes_label: String, yes: Callable, no_label: String = "返回") -> void:
	close_dialog()
	dialog_text = text
	# Keep focus inside the sheet while it is open.
	for button: Button in buttons:
		button.focus_mode = Control.FOCUS_NONE
	dialog = Control.new()
	dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog.draw.connect(_draw_dialog)
	add_child(dialog)
	var row: HBoxContainer = HBoxContainer.new()
	row.position = Vector2(700, 600)
	row.add_theme_constant_override("separation", 40)
	dialog.add_child(row)
	var accept: Button = InkButton.new().setup(yes_label, 28, 880)
	accept.custom_minimum_size = Vector2(240, 58)
	accept.pressed.connect(func() -> void:
		close_dialog()
		yes.call())
	row.add_child(accept)
	var cancel: Button = InkButton.new().setup(no_label, 28, 881)
	cancel.custom_minimum_size = Vector2(240, 58)
	cancel.pressed.connect(close_dialog)
	row.add_child(cancel)
	cancel.grab_focus()
	drawn["dialog"] = text

func close_dialog() -> void:
	if dialog != null:
		dialog.queue_free()
		dialog = null
		drawn.erase("dialog")
		for button: Button in buttons:
			button.focus_mode = Control.FOCUS_ALL
		focus_first()

func _draw_dialog() -> void:
	dialog.draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.03, 0.04, 0.55))
	var sheet: Rect2 = Rect2(560, 380, 800, 320)
	InkDraw.paper(dialog, sheet, Color(DuskStyle.paper_color(MOOD), 0.95), 870, DuskStyle.WOBBLE, 6)
	DuskStyle.panel(dialog, sheet, MOOD, 871)
	dialog.draw_multiline_string(font, sheet.position + Vector2(40, 100), dialog_text, HORIZONTAL_ALIGNMENT_CENTER, sheet.size.x - 80, UiTheme.SIZE_HEADING, -1, DuskStyle.INK)

## Esc / B / Back closes an open dialog first; screens decide the rest.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		if dialog != null:
			close_dialog()
		else:
			back()
		get_viewport().set_input_as_handled()

func back() -> void:
	pass
