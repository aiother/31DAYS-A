extends Control
## EXP-004 dialogue box, three looks over one behaviour (T7-C): top-centre
## box, text typed out, speaker name at the lower left, E / RB once to finish
## the line or go on, held to speed the typing up, closes by itself after the
## last line. A rescue departure ends in 留下 / 确认离开并放弃救助 (A-020).
## The preview owns pausing; while paused nothing here advances.
signal finished
signal departure_chosen(leave: bool)

## D (user, EXP-004 G4 round 1): B's dusk paper and ink with C's torn
## edges and small name tag.
const VARIANTS: Array[String] = ["A · 墨夜黑框", "B · 黄昏纸笺", "C · 黑纱纸边", "D · 纸笺纸边"]
const BOX: Rect2 = Rect2(540, 120, 840, 250)
const CHARS_PER_SECOND: float = 28.0
const HOLD_MULTIPLIER: float = 4.0
const CHOICE_GAP: float = 40.0

var variant: int = 0
var font: Font
var lines: Array[Dictionary] = []
var index: int = 0
var typed: float = 0.0
var active: bool = false
var paused: bool = false: set = set_paused
## A forced story scene hides the HUD while it plays.
var forced: bool = false
var holding: bool = false
var clock: float = 0.0
var choices: Array[Button] = []
## What the last frame put on screen; read by the smoke test.
var drawn: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = UiTheme.font()

## entries: [{"speaker": String, "text": String, "tone": "" | "aside"}];
## departure: end on the rescue choice instead of closing.
func start(entries: Array[Dictionary], is_forced: bool = false, departure: bool = false) -> void:
	lines = entries
	index = 0
	typed = 0.0
	forced = is_forced
	active = true
	set_meta("departure", departure)
	_clear_choices()

## Review R2: while paused the departure buttons take no click, key or pad
## input; resuming restores them and the focus they had.
func set_paused(value: bool) -> void:
	if value == paused:
		return
	paused = value
	if paused:
		var owner: Control = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
		set_meta("refocus", owner if choices.has(owner) else null)
	for item: Button in choices:
		item.disabled = paused
		item.focus_mode = Control.FOCUS_NONE if paused else Control.FOCUS_ALL
	if not paused and not choices.is_empty():
		var back: Variant = get_meta("refocus", null)
		(back if back is Button and is_instance_valid(back) else choices[0]).grab_focus()

func line() -> Dictionary:
	return lines[index] if active and index < lines.size() else {}

func full_length() -> int:
	return str(line().get("text", "")).length()

func line_done() -> bool:
	return int(typed) >= full_length()

func asking() -> bool:
	return not choices.is_empty()

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()
	if not active or paused or asking():
		return
	holding = Input.is_action_pressed("interact")
	typed = minf(full_length(), typed + delta * CHARS_PER_SECOND * (HOLD_MULTIPLIER if holding else 1.0))

## One press of E / RB: finish the line, or go to the next one.
func press() -> void:
	if not active or paused or asking():
		return
	if not line_done():
		typed = full_length()
		return
	if index + 1 < lines.size():
		index += 1
		typed = 0.0
	elif bool(get_meta("departure", false)):
		_ask_departure()
	else:
		close()

func close() -> void:
	active = false
	forced = false
	_clear_choices()
	drawn = {}
	finished.emit()

func _ask_departure() -> void:
	for caption: String in ["留下", "确认离开并放弃救助"]:
		# Paper-coloured ink on the dark boxes, dark ink on the paper slip.
		var button: InkButton = (InkButton.new() if variant in [1, 3] else MenuScreen.LightInkButton.new()).setup(caption, 26, 950 + choices.size())
		button.custom_minimum_size = Vector2(300, 56)
		button.size = button.custom_minimum_size
		add_child(button)
		choices.append(button)
	# Review R1: the two click areas sit apart (40 px), centred, and above
	# the name tag at the lower left.
	var row: float = 2.0 * 300.0 + CHOICE_GAP
	choices[0].position = BOX.position + Vector2((BOX.size.x - row) * 0.5, 124)
	choices[1].position = choices[0].position + Vector2(300.0 + CHOICE_GAP, 0)
	choices[0].pressed.connect(func() -> void:
		departure_chosen.emit(false)
		close())
	choices[1].pressed.connect(func() -> void:
		departure_chosen.emit(true)
		close())
	for item: Button in choices:
		item.focus_neighbor_top = item.get_path()
		item.focus_neighbor_bottom = item.get_path()
	choices[0].focus_neighbor_left = choices[0].get_path()
	choices[0].focus_neighbor_right = choices[0].get_path_to(choices[1])
	choices[1].focus_neighbor_left = choices[1].get_path_to(choices[0])
	choices[1].focus_neighbor_right = choices[1].get_path()
	# Staying is the safe default; leaving gives the rescue up for good.
	choices[0].grab_focus()

func _clear_choices() -> void:
	for item: Button in choices:
		item.queue_free()
	choices.clear()

## A sheet whose top and bottom edges are torn: the fill follows the tears
## and an edge line traces them.
func _torn_sheet(fill: Color, edge_color: Color) -> void:
	var top: PackedVector2Array = []
	var bottom: PackedVector2Array = []
	for i: int in range(41):
		var x: float = BOX.position.x + BOX.size.x * i / 40.0
		top.append(Vector2(x, BOX.position.y + (InkDraw.noise(i, int(BOX.position.y)) - 0.5) * 8.0))
		bottom.append(Vector2(x, BOX.end.y + (InkDraw.noise(i, int(BOX.end.y)) - 0.5) * 8.0))
	var outline: PackedVector2Array = top.duplicate()
	var back: PackedVector2Array = bottom.duplicate()
	back.reverse()
	outline.append_array(back)
	draw_colored_polygon(outline, fill)
	draw_polyline(top, edge_color, 2.4, true)
	draw_polyline(bottom, edge_color, 2.4, true)

func _ink(at: Vector2, text: String, size_px: int, color: Color, width: float = -1.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Dictionary:
	draw_multiline_string(font, at, text, align, width, size_px, -1, color)
	return {"text": text, "color": color}

func _draw() -> void:
	if not active:
		return
	var entry: Dictionary = line()
	var shown: String = str(entry.get("text", "")).substr(0, int(typed))
	var aside: bool = str(entry.get("tone", "")) == "aside"
	var record: Dictionary = {"variant": VARIANTS[variant], "box": BOX, "line": index}
	var text_color: Color
	var name_color: Color
	match variant:
		0:
			# Closest to T7: a black translucent box, a white bold name.
			draw_rect(BOX, Color(0.02, 0.02, 0.03, 0.82))
			InkDraw.rough_line(self, BOX.position + Vector2(24, BOX.size.y - 6), BOX.end - Vector2(24, 6), Color(DuskStyle.PAPER_DAY, 0.35), 1.6, 960, 0.8)
			text_color = Color(DuskStyle.PAPER_DAY, 0.7) if aside else DuskStyle.PAPER_DAY
			name_color = Color.WHITE
		1:
			# Paper slip in the day's dusk, ink text, a vermilion name seal.
			InkDraw.paper(self, BOX, Color(DuskStyle.PAPER_DUSK, 0.95), 961, DuskStyle.WOBBLE, 8)
			InkDraw.rough_rect(self, BOX, Color(DuskStyle.INK, 0.85), DuskStyle.INK_WIDTH, 962, DuskStyle.WOBBLE)
			text_color = Color(DuskStyle.INK, 0.6) if aside else DuskStyle.INK
			name_color = DuskStyle.PAPER_DAY
		3:
			# B's dusk paper and ink, C's torn edges instead of a drawn frame.
			_torn_sheet(Color(DuskStyle.PAPER_DUSK, 0.95), Color(DuskStyle.INK, 0.75))
			text_color = Color(DuskStyle.INK, 0.6) if aside else DuskStyle.INK
			name_color = DuskStyle.PAPER_DAY
		_:
			# Black gauze with torn paper edges top and bottom.
			draw_rect(BOX, Color(0.03, 0.02, 0.03, 0.72))
			for edge: float in [BOX.position.y, BOX.end.y]:
				var points: PackedVector2Array = []
				for i: int in range(41):
					var x: float = BOX.position.x + BOX.size.x * i / 40.0
					points.append(Vector2(x, edge + (InkDraw.noise(i, int(edge)) - 0.5) * 8.0))
				draw_polyline(points, Color(DuskStyle.PAPER_DUSK, 0.85), 3.0, true)
			text_color = Color(DuskStyle.PAPER_DAY, 0.7) if aside else DuskStyle.PAPER_DAY
			name_color = Color.WHITE
	record["text"] = _ink(BOX.position + Vector2(48, 66), shown, UiTheme.SIZE_BODY + 4, text_color, BOX.size.x - 96)
	var speaker: String = str(entry.get("speaker", ""))
	if not speaker.is_empty():
		var tag: Rect2 = Rect2(BOX.position + Vector2(28, BOX.size.y - 50), Vector2(font.get_string_size(speaker, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_HEADING).x + 40, 44))
		match variant:
			1:
				draw_rect(tag, Color(DuskStyle.LIFE, 0.92))
			2, 3:
				InkDraw.paper(self, tag, Color(DuskStyle.INK, 0.9), 963, DuskStyle.WOBBLE, 0)
		# Bold by a second, slightly offset pass of the same text.
		_ink(tag.position + Vector2(21, 33), speaker, UiTheme.SIZE_HEADING, name_color)
		record["speaker"] = _ink(tag.position + Vector2(20, 33), speaker, UiTheme.SIZE_HEADING, name_color)
		record["speaker_rect"] = tag
	if not asking():
		# Go-on marker once the line is out; a speed mark while E / RB is held.
		var marker: Vector2 = BOX.end - Vector2(46, 34 + 4.0 * sin(clock * 5.0))
		var marker_color: Color = DuskStyle.LIFE if variant != 0 else DuskStyle.PAPER_DAY
		if line_done():
			draw_colored_polygon(PackedVector2Array([marker, marker + Vector2(16, 0), marker + Vector2(8, 12)]), marker_color)
			record["marker"] = "continue"
		elif holding:
			record["marker"] = _ink(BOX.end - Vector2(70, 22), "»»", UiTheme.SIZE_BODY, marker_color)["text"]
		record["hint"] = _ink(Vector2(BOX.position.x, BOX.end.y + 30), "E / RB 继续 · 长按加速", UiTheme.SIZE_SMALL, Color(DuskStyle.PAPER_DAY, 0.6), BOX.size.x, HORIZONTAL_ALIGNMENT_CENTER)["text"]
	else:
		record["choices"] = choices.map(func(item: Button) -> String: return item.text)
		record["choice_rects"] = choices.map(func(item: Button) -> Rect2: return item.get_global_rect())
	record["aside"] = aside
	record["text_color"] = text_color
	drawn = record
