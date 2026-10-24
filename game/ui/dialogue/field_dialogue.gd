class_name FieldDialogue
extends CanvasLayer
## UI-008 formal dialogue box, EXP-004 variant D · 纸笺纸边 (user, 2026-10-22):
## a dusk paper slip with torn top and bottom edges at the top centre, ink
## text typed out, the speaker on a small ink tag at the lower left. E / RB
## once finishes the line or goes on, held speeds the typing up; the last line
## closes it. A rescue departure ends in 留下 / 确认离开并放弃救助 (A-020),
## focus on 留下. Also the G-08 tag: near a rescue that can no longer happen, a
## small slip says someone once needed help here.
##
## `text`, `speaker` and `hint` stay hidden Labels holding the state sessions
## and tests read and write (text.visible_characters, speaker.text, ...); the
## slip is drawn from them. `quest` and `notice` keep their graybox look until
## UI-010.
signal finished
signal departure_confirmed
signal departure_cancelled
## UI-010: every show_notice() text, for the formal centre notice.
signal noticed(message: String)
const BOX: Rect2 = Rect2(540, 120, 840, 250)
const CHOICE_SIZE: Vector2 = Vector2(300, 56)
const CHOICE_GAP: float = 40.0
const MISSED_TEXT: String = "此处曾有人需要帮助\n更早到来，或许还来得及"
const MISSED_SECONDS: float = 4.0
const MISSED_SIZE: Vector2 = Vector2(380, 92)
## Tag bottom this far above the survivor, clear of the interaction prompt.
const MISSED_LIFT: float = 220.0
## Fallback reach for a survivor without a talk target (the ravine depth).
const MISSED_REACH: float = 160.0

var active: bool = false
var confirming: bool = false
var line_index: int = 0
var _lines: PackedStringArray
var _config: DialogueConfig
var _count: float = 0.0
var _grace: float = 0.0
## The slip (named panel for continuity with the graybox box).
var panel: Control
var text: Label
var speaker: Label
var hint: Label
var choices: Control
var quest: Label
var notice: Label
var font: Font
var holding: bool = false
var clock: float = 0.0
var _was_paused: bool = false
var _refocus: Button
## G-08 tag state for the Room the player is in.
var missed: Control
var missed_age: float = -1.0
var _missed_room: Node
var _missed_shown: bool = false
## What the last frame put on screen; read by tests.
var drawn: Dictionary = {}
var missed_drawn: Dictionary = {}

func _ready() -> void:
	layer = 15
	# Runs while paused only to guard the departure buttons; typing checks it.
	process_mode = Node.PROCESS_MODE_ALWAYS
	font = UiTheme.font()
	panel = Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.draw.connect(_draw_slip)
	add_child(panel)
	# State only; the slip draws them.
	text = Label.new()
	text.hide()
	add_child(text)
	speaker = Label.new()
	speaker.hide()
	add_child(speaker)
	hint = Label.new()
	hint.text = "E / RB 继续 · 长按加速"
	hint.hide()
	add_child(hint)
	choices = Control.new()
	choices.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(choices)
	for caption: String in ["留下", "确认离开并放弃救助"]:
		var button: InkButton = InkButton.new().setup(caption, 26, 940 + choices.get_child_count())
		button.custom_minimum_size = CHOICE_SIZE
		button.size = CHOICE_SIZE
		choices.add_child(button)
	# Two click areas side by side with a gap, above the name tag (EXP-004 R1).
	var row: float = 2.0 * CHOICE_SIZE.x + CHOICE_GAP
	(choices.get_child(0) as Button).position = BOX.position + Vector2((BOX.size.x - row) * 0.5, 124)
	(choices.get_child(1) as Button).position = (choices.get_child(0) as Button).position + Vector2(CHOICE_SIZE.x + CHOICE_GAP, 0)
	var stay: Button = choices.get_child(0) as Button
	var leave: Button = choices.get_child(1) as Button
	for item: Button in [stay, leave]:
		item.focus_neighbor_top = item.get_path()
		item.focus_neighbor_bottom = item.get_path()
		item.focus_next = item.get_path_to(leave if item == stay else stay)
		item.focus_previous = item.focus_next
	stay.focus_neighbor_left = stay.get_path()
	stay.focus_neighbor_right = stay.get_path_to(leave)
	leave.focus_neighbor_left = leave.get_path_to(stay)
	leave.focus_neighbor_right = leave.get_path()
	stay.pressed.connect(func() -> void: departure_cancelled.emit())
	leave.pressed.connect(func() -> void: departure_confirmed.emit())
	missed = Control.new()
	missed.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	missed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	missed.draw.connect(_draw_missed)
	add_child(missed)
	# UI-010: the task text and the notice stay as data the sessions write;
	# the formal quest slip and centre notice (LifeUI) show them, so these
	# graybox Labels sit under a hidden holder and never draw.
	var models: Control = Control.new()
	models.name = "GrayboxModels"
	models.hide()
	add_child(models)
	quest = Label.new()
	quest.position = Vector2(64, 490)
	quest.add_theme_font_size_override("font_size", 23)
	models.add_child(quest)
	notice = Label.new()
	notice.position = Vector2(560, 540)
	notice.add_theme_font_size_override("font_size", 30)
	models.add_child(notice)
	dismiss()

func show_notice(message: String) -> void:
	notice.text = message
	notice.modulate.a = 1
	# This node runs while paused (button guard); the notice still stops
	# while paused, as before UI-008.
	create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP).tween_property(notice, "modulate:a", 0.0, 3.0)
	noticed.emit(message)

func start(config: DialogueConfig, lines: PackedStringArray) -> void:
	_config = config
	_lines = lines
	line_index = 0
	active = true
	confirming = false
	choices.hide()
	panel.show()
	speaker.text = config.speaker
	_show_line()

func _show_line() -> void:
	text.text = _lines[line_index]
	_count = 0
	text.visible_characters = 0
	_grace = 0.12

func _process(delta: float) -> void:
	clock += delta
	var paused: bool = get_tree().paused
	if paused != _was_paused:
		_guard_pause(paused)
	panel.queue_redraw()
	missed.queue_redraw()
	if paused:
		return
	_update_missed(delta)
	if not active or confirming:
		return
	_grace = maxf(0, _grace - delta)
	holding = Input.is_action_pressed("interact")
	_count += delta * _config.characters_per_second * (_config.hold_speed_multiplier if holding else 1.0)
	text.visible_characters = mini(text.get_total_character_count(), int(_count))
	if _grace == 0 and Input.is_action_just_pressed("interact"):
		advance()

## While paused the departure buttons take no click, key or pad input;
## resuming restores them and the focus they had.
func _guard_pause(paused: bool) -> void:
	_was_paused = paused
	var owner: Control = panel.get_viewport().gui_get_focus_owner()
	if paused and owner is Button and choices.is_ancestor_of(owner):
		_refocus = owner as Button
	for item: Node in choices.get_children():
		(item as Button).disabled = paused
		(item as Button).focus_mode = Control.FOCUS_NONE if paused else Control.FOCUS_ALL
	if not paused and confirming and choices.visible:
		(_refocus if is_instance_valid(_refocus) else choices.get_child(0) as Button).grab_focus()
		_refocus = null

func advance() -> void:
	if not active or confirming or get_tree().paused:
		return
	GameAudio.emit_from(self, &"interaction.dialogue")
	if text.visible_characters < text.get_total_character_count():
		_count = text.get_total_character_count()
		text.visible_characters = text.get_total_character_count()
	elif line_index + 1 < _lines.size():
		line_index += 1
		_show_line()
	else:
		finished.emit()

func show_departure() -> void:
	active = true
	confirming = true
	panel.show()
	speaker.text = "7"
	text.text = "这里还需要你，离开后无法弥补。\n返回荒地将永久失去这次救助机会。"
	text.visible_characters = -1
	choices.show()
	# Staying is the safe default; leaving gives the rescue up for good.
	_refocus = choices.get_child(0) as Button
	# Focuses it now, or on resuming when paused.
	_guard_pause(get_tree().paused)

func dismiss() -> void:
	active = false
	confirming = false
	choices.hide()
	panel.hide()
	drawn = {}

func line_done() -> bool:
	return text.visible_characters < 0 or text.visible_characters >= text.get_total_character_count()

## Draws text and returns what it drew, so a record can only come from a
## real draw.
func _ink(ci: CanvasItem, at: Vector2, value: String, size_px: int, color: Color, width: float = -1.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Dictionary:
	ci.draw_multiline_string(font, at, value, align, width, size_px, -1, color)
	return {"text": value, "color": color}

## B's dusk paper with C's torn top and bottom edges; returns what it drew.
func _torn_sheet(ci: CanvasItem, rect: Rect2, fill: Color, edge: Color, seed: int) -> Dictionary:
	var top: PackedVector2Array = []
	var bottom: PackedVector2Array = []
	for i: int in range(41):
		var x: float = rect.position.x + rect.size.x * i / 40.0
		top.append(Vector2(x, rect.position.y + (InkDraw.noise(i, seed) - 0.5) * 8.0))
		bottom.append(Vector2(x, rect.end.y + (InkDraw.noise(i, seed + 1) - 0.5) * 8.0))
	var outline: PackedVector2Array = top.duplicate()
	var back: PackedVector2Array = bottom.duplicate()
	back.reverse()
	outline.append_array(back)
	ci.draw_colored_polygon(outline, fill)
	ci.draw_polyline(top, edge, 2.4, true)
	ci.draw_polyline(bottom, edge, 2.4, true)
	return {"fill": fill, "edge": edge, "outline": outline, "top": top, "bottom": bottom}

## The go-on triangle; returns what it drew.
func _go_on(ci: CanvasItem, at: Vector2, color: Color) -> Dictionary:
	var points: PackedVector2Array = [at, at + Vector2(16, 0), at + Vector2(8, 12)]
	ci.draw_colored_polygon(points, color)
	return {"shape": "continue", "points": points, "color": color}

func _draw_slip() -> void:
	drawn = {}
	if not active:
		return
	var record: Dictionary = {"box": BOX, "line": line_index, "confirming": confirming}
	record["paper"] = _torn_sheet(panel, BOX, Color(DuskStyle.PAPER_DUSK, 0.95), Color(DuskStyle.INK, 0.75), 120)
	var full: String = text.text
	var shown: String = full if text.visible_characters < 0 else full.substr(0, text.visible_characters)
	record["text"] = _ink(panel, BOX.position + Vector2(48, 66), shown, UiTheme.SIZE_BODY + 4, DuskStyle.INK, BOX.size.x - 96)
	if not speaker.text.is_empty():
		var tag: Rect2 = Rect2(BOX.position + Vector2(28, BOX.size.y - 50), Vector2(font.get_string_size(speaker.text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_HEADING).x + 40, 44))
		InkDraw.paper(panel, tag, Color(DuskStyle.INK, 0.9), 121, DuskStyle.WOBBLE, 0)
		# Bold by a second, slightly offset pass of the same text.
		_ink(panel, tag.position + Vector2(21, 33), speaker.text, UiTheme.SIZE_HEADING, DuskStyle.PAPER_DAY)
		record["speaker"] = _ink(panel, tag.position + Vector2(20, 33), speaker.text, UiTheme.SIZE_HEADING, DuskStyle.PAPER_DAY)
		record["speaker_rect"] = tag
	if confirming:
		record["choices"] = choices.get_children().map(func(item: Node) -> String: return (item as Button).text)
		record["choice_rects"] = choices.get_children().map(func(item: Node) -> Rect2: return (item as Control).get_global_rect())
	else:
		var marker: Vector2 = BOX.end - Vector2(46, 34 + 4.0 * sin(clock * 5.0))
		if line_done():
			var mark: Dictionary = _go_on(panel, marker, DuskStyle.LIFE)
			record["marker"] = mark["shape"]
			record["marker_shape"] = mark
		elif holding:
			record["marker"] = _ink(panel, BOX.end - Vector2(70, 22), "»»", UiTheme.SIZE_BODY, DuskStyle.LIFE)["text"]
		var line: Dictionary = _ink(panel, Vector2(BOX.position.x, BOX.end.y + 30), hint.text, UiTheme.SIZE_SMALL, Color(DuskStyle.PAPER_DAY, 0.6), BOX.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		record["hint"] = line["text"]
		record["hint_rect"] = Rect2(BOX.position.x, BOX.end.y + 8, BOX.size.x, 30)
	drawn = record

## --- G-08 ---------------------------------------------------------------

func _session() -> Node:
	return get_parent()

## The Survivor of a rescue that expired in this very Room, when the player
## is near it; null otherwise.
func missed_survivor() -> Node2D:
	var session: Node = _session()
	if session == null or not session.has_method("quest_state"):
		return null
	if session.has_method("has_session") and not bool(session.call("has_session")):
		return null
	var room: Variant = session.get("room")
	if not room is WorldRoom:
		return null
	var state: Dictionary = session.call("quest_state")
	if state.get("state") != "已过期" or state.get("id") != (room as WorldRoom).config.room_id:
		return null
	var survivor: Node2D = (room as Node).get_node_or_null("Survivor") as Node2D
	if survivor == null:
		return null
	var id: String = (room as WorldRoom).config.room_id + ":Survivor"
	if session.has_method("interaction_targets"):
		for target: Dictionary in session.call("interaction_targets"):
			if target.get("id") == id:
				return survivor if bool(target.get("in_range", false)) else null
	var player: Node2D = session.get("player") as Node2D
	return survivor if player != null and player.global_position.distance_to(survivor.global_position) <= MISSED_REACH else null

func _update_missed(delta: float) -> void:
	var room: Variant = _session().get("room") if _session() != null else null
	if room != _missed_room:
		_missed_room = room
		_missed_shown = false
		missed_age = -1.0
	if missed_age >= 0.0:
		# Hidden while a dialogue is open; the rest of its time waits.
		if not active:
			missed_age += delta
		if missed_age >= MISSED_SECONDS:
			missed_age = -1.0
	elif not _missed_shown and not active and missed_survivor() != null and not missed_place().is_empty():
		# Once per visit to the Room; it never stops the player. It waits
		# while there is no clear spot (e.g. the area name on arrival).
		missed_age = 0.0
		_missed_shown = true

## Screen areas the G-08 slip keeps clear of: the HUD as drawn (horizon
## included), the area name, the interaction prompt and a visible save error
## (same rule as UI-007's prompt).
func missed_avoided() -> Array[Rect2]:
	var result: Array[Rect2] = []
	var ui: Variant = _session().get("ui") if _session() != null else null
	if not ui is Node:
		return result
	if (ui as Node).has_method("_protected_rects"):
		result.append_array((ui as Node).call("_protected_rects"))
	var hud: Variant = (ui as Node).get("_hud")
	if hud is FormalHud:
		for key: String in ["emblem", "hint", "horizon", "warning", "final", "banner"]:
			if (hud as FormalHud).drawn.has(key) and (hud as FormalHud).drawn[key].has("rect"):
				result.append((hud as FormalHud).drawn[key]["rect"])
	for name: String in ["_area_banner", "_interact_prompt"]:
		var node: Variant = (ui as Node).get(name)
		if node is Control and (node as Object).get("drawn") is Dictionary and (node as Object).get("drawn").has("rect"):
			result.append((node as Object).get("drawn")["rect"])
	return result

## Above the survivor, else below it; {} when neither spot is clear.
func missed_place() -> Dictionary:
	if not is_instance_valid(_missed_room):
		return {}
	var survivor: Node2D = (_missed_room as Node).get_node_or_null("Survivor") as Node2D
	if survivor == null:
		return {}
	var anchor: Vector2 = survivor.get_viewport().get_canvas_transform() * survivor.global_position
	var view: Vector2 = missed.size
	var avoid: Array[Rect2] = missed_avoided()
	for y: float in [anchor.y - MISSED_LIFT - MISSED_SIZE.y, anchor.y + 60.0]:
		var rect: Rect2 = Rect2(Vector2(anchor.x - MISSED_SIZE.x * 0.5, y), MISSED_SIZE)
		rect.position.x = clampf(rect.position.x, 16.0, view.x - 16.0 - MISSED_SIZE.x)
		rect.position.y = clampf(rect.position.y, 16.0, view.y - 16.0 - MISSED_SIZE.y)
		var clear: bool = true
		for other: Rect2 in avoid:
			clear = clear and not rect.intersects(other)
		if clear:
			return {"rect": rect, "anchor": anchor}
	return {}

func _draw_missed() -> void:
	missed_drawn = {}
	if missed_age < 0.0 or active:
		return
	var placed: Dictionary = missed_place()
	if placed.is_empty():
		# Something took its spot meanwhile: it gives way for this frame.
		return
	var rect: Rect2 = placed["rect"]
	var anchor: Vector2 = placed["anchor"]
	var alpha: float = clampf(minf(missed_age / 0.3, (MISSED_SECONDS - missed_age) / 0.6), 0.0, 1.0)
	InkDraw.paper(missed, rect, Color(DuskStyle.PAPER_DAY, 0.9 * alpha), 125, DuskStyle.WOBBLE, 0)
	InkDraw.rough_rect(missed, rect, Color(DuskStyle.INK, 0.7 * alpha), 1.4, 126, DuskStyle.WOBBLE)
	var shown: Dictionary = _ink(missed, rect.position + Vector2(0, 36), MISSED_TEXT, UiTheme.SIZE_SMALL, Color(DuskStyle.INK, alpha), rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	missed_drawn = {"text": shown["text"], "rect": rect, "alpha": alpha, "anchor": anchor}
