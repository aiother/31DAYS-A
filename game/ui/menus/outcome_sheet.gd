class_name OutcomeSheet
extends Control
## UI-005: the paper sheet for death (A-014), the V0.1 ending, the final
## battle timeout (A-011) and the third-day exploration timeout (G-03). A
## title, a few lines, ink buttons, a question when an option asks first, and
## its own error line so save failures never sit under or over the sheet.
## Every text record comes from the call that draws it.
const WIDTH: float = 760.0
const LINE: float = 38.0
const BUTTON_SIZE: Vector2 = Vector2(420, 58)
## A question closed (answered, 返回, Esc or Back).
signal question_closed

var font: Font
var title: String = ""
var title_color: Color = DuskStyle.INK
var body: String = ""
var error: String = ""
var question: String = ""
## Backdrop over the game (0 when a curtain already covers it).
var dim: float = 0.6
var buttons: Array[InkButton] = []
var mood: Dictionary = {"day": 3, "day_progress": 0.55}
## What the last frame put on screen; read by tests.
var drawn: Dictionary = {}
var _column: VBoxContainer
var _entries: Array = []
var _answer: Array[InkButton] = []
## The option that asked; focus returns there when the question closes.
var _asked_from: Control

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	font = UiTheme.font()
	theme = UiTheme.get_theme()
	visible = false

func _ready() -> void:
	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 10)
	add_child(_column)

## entries: [[label, Callable], ...]; focus starts on entries[focus].
func open(sheet_title: String, sheet_body: String, colour: Color, entries: Array, focus: int = 0) -> void:
	close_question()
	title = sheet_title
	body = sheet_body
	title_color = colour
	error = ""
	_entries = entries
	for item: InkButton in buttons:
		_column.remove_child(item)
		item.queue_free()
	buttons.clear()
	for i: int in range(entries.size()):
		var item: InkButton = InkButton.new().setup(str(entries[i][0]), 28, 760 + i)
		item.custom_minimum_size = BUTTON_SIZE
		item.pressed.connect(entries[i][1])
		_column.add_child(item)
		buttons.append(item)
	_link(buttons)
	visible = true
	_layout()
	if not buttons.is_empty():
		buttons[clampi(focus, 0, buttons.size() - 1)].grab_focus()

func close() -> void:
	close_question()
	visible = false

func button(label: String) -> InkButton:
	for item: InkButton in buttons:
		if item.text == label:
			return item
	return null

func set_body(text: String) -> void:
	body = text

func set_error(text: String) -> void:
	error = text

## Asks before an option; focus starts on 返回 and stays inside the question.
func ask(text: String, yes_label: String, yes: Callable) -> void:
	close_question()
	question = text
	_asked_from = get_viewport().gui_get_focus_owner()
	for item: InkButton in buttons:
		item.visible = false
	var accept: InkButton = InkButton.new().setup(yes_label, 28, 790)
	var cancel: InkButton = InkButton.new().setup("返回", 28, 791)
	for item: InkButton in [accept, cancel]:
		item.custom_minimum_size = BUTTON_SIZE
		_column.add_child(item)
		_answer.append(item)
	_link(_answer)
	accept.pressed.connect(func() -> void:
		close_question()
		yes.call())
	cancel.pressed.connect(func() -> void: close_question())
	_layout()
	cancel.grab_focus()

func asking() -> bool:
	return not _answer.is_empty()

func answer_button(which: String) -> InkButton:
	if _answer.is_empty():
		return null
	return _answer[0] if which == "accept" else _answer[1]

func close_question() -> void:
	if _answer.is_empty():
		return
	var refocus: Control = _asked_from
	_asked_from = null
	for item: InkButton in _answer:
		_column.remove_child(item)
		item.queue_free()
	_answer.clear()
	question = ""
	for item: InkButton in buttons:
		item.visible = true
	_layout()
	if is_instance_valid(refocus) and refocus.is_visible_in_tree():
		refocus.grab_focus()
	elif visible and not buttons.is_empty():
		buttons[0].grab_focus()
	question_closed.emit()

## Up / down walk the column and stop at its ends; nothing outside the
## sheet can take the focus while it is open.
func _link(items: Array[InkButton]) -> void:
	for i: int in range(items.size()):
		var item: InkButton = items[i]
		item.focus_neighbor_top = item.get_path_to(items[maxi(0, i - 1)])
		item.focus_neighbor_bottom = item.get_path_to(items[mini(items.size() - 1, i + 1)])
		item.focus_neighbor_left = item.get_path()
		item.focus_neighbor_right = item.get_path()
		item.focus_previous = item.focus_neighbor_top
		item.focus_next = item.focus_neighbor_bottom

func _lines() -> int:
	var shown: String = question if asking() else body
	return 0 if shown.is_empty() else shown.count("\n") + 1

func sheet_rect() -> Rect2:
	var count: int = _answer.size() if asking() else buttons.size()
	var height: float = 150.0 + _lines() * LINE + 24.0 + count * (BUTTON_SIZE.y + 10.0) + 80.0
	return Rect2((size - Vector2(WIDTH, height)) * 0.5, Vector2(WIDTH, height))

func _layout() -> void:
	if _column == null:
		return
	var sheet: Rect2 = sheet_rect()
	_column.reset_size()
	_column.position = Vector2(sheet.position.x + (WIDTH - BUTTON_SIZE.x) * 0.5, sheet.position.y + 150.0 + _lines() * LINE + 24.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()

func _process(_delta: float) -> void:
	if visible:
		_layout()
		queue_redraw()

func _ink(at: Vector2, text: String, size_px: int, color: Color, width: float) -> Dictionary:
	draw_multiline_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, width, size_px, -1, color)
	return {"text": text, "color": color}

func _draw() -> void:
	if dim > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.02, 0.03, dim))
	var sheet: Rect2 = sheet_rect()
	InkDraw.paper(self, sheet, Color(DuskStyle.paper_color(mood), 0.97), 750, DuskStyle.WOBBLE, 6)
	DuskStyle.panel(self, sheet, mood, 751)
	var record: Dictionary = {"rect": sheet}
	if not title.is_empty():
		record["title"] = _ink(sheet.position + Vector2(0, 92), title, UiTheme.SIZE_TITLE, title_color, WIDTH)
		InkDraw.rough_line(self, sheet.position + Vector2(WIDTH * 0.5 - 90, 112), sheet.position + Vector2(WIDTH * 0.5 + 90, 112), Color(DuskStyle.LIFE, 0.8), 2.4, 752, DuskStyle.WOBBLE)
	var lines: String = question if asking() else body
	if not lines.is_empty():
		record["question" if asking() else "body"] = _ink(sheet.position + Vector2(40, 162), lines, UiTheme.SIZE_BODY if asking() else UiTheme.SIZE_SMALL + 2, DuskStyle.INK, WIDTH - 80)
	if not error.is_empty():
		record["error"] = _ink(Vector2(sheet.position.x + 30, sheet.end.y - 34), error, UiTheme.SIZE_SMALL, DuskStyle.LIFE, WIDTH - 60)
	var shown: Array = []
	for item: InkButton in (_answer if asking() else buttons):
		shown.append(item.text)
	record["buttons"] = shown
	record["button_rects"] = (_answer if asking() else buttons).map(func(item: InkButton) -> Rect2: return item.get_global_rect())
	drawn = record

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not asking():
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause") or event.is_action_pressed("use_item"):
		close_question()
		get_viewport().set_input_as_handled()
