class_name QuestSlip
extends Control
## UI-010 (BL-044): the current task on a paper slip at the left, a little
## above the middle, under the HUD control hint and clear of the save error.
## It reads quest_state() when the save or the Room changes and otherwise
## follows quest_changed. While a task runs it stays; a finished, abandoned or
## expired one shows its state for SETTLED_SECONDS and folds away. Hidden in
## dialogue, story scenes, pause and death; the pause menu's "current task"
## reads the same objective text.
const LEFT: float = 40.0
const TOP: float = 450.0
const WIDTH: float = 380.0
const SETTLED_SECONDS: float = 6.0
const RUNNING: String = "进行中"
const STATES: Dictionary = {"已完成": "growth", "已放弃": "life", "已过期": "life"}

var session: Node
var hud: Control
## Rects the slip moves below (the save error); set by LifeUI.
var protected: Callable
var font: Font
var state: Dictionary = {}
## Seconds a settled task has been on show; -1 when it is not settling.
var settled_age: float = -1.0
var _room: Node
## The loaded save's data; a new load is a new dictionary.
var _data: Variant
## What the last frame put on screen, each part returned by the call that drew it.
var drawn: Dictionary = {}

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = UiTheme.font()

func setup(owner_session: Node, formal_hud: Control) -> void:
	session = owner_session
	hud = formal_hud
	if session.has_signal("quest_changed"):
		session.connect("quest_changed", _on_quest_changed)

## quest_changed reports every task (one save can change several); the slip
## shows the current one, so it reads the query again instead of the event.
func _on_quest_changed(_kind: String, _value: Dictionary) -> void:
	refresh()

func _take(value: Dictionary) -> void:
	var old: String = "%s|%s|%s" % [state.get("id", ""), state.get("state", ""), state.get("objective", "")]
	state = value.duplicate(true)
	var now: String = "%s|%s|%s" % [state.get("id", ""), state.get("state", ""), state.get("objective", "")]
	if now != old:
		settled_age = 0.0 if STATES.has(state.get("state", "")) else -1.0

## Read the query afresh: a new save or another Room may show another task.
func refresh() -> void:
	if session != null and session.has_method("quest_state"):
		_take(session.call("quest_state"))

func showing() -> bool:
	var value: String = str(state.get("state", "无"))
	if value == RUNNING:
		return true
	return STATES.has(value) and settled_age >= 0.0 and settled_age < SETTLED_SECONDS

## Dialogue, story, pause, death, menus and a hidden HUD all hide the slip.
func blocked() -> bool:
	if session == null or get_tree().paused:
		return true
	if session.has_method("has_session") and not bool(session.call("has_session")):
		return true
	if hud != null and not hud.visible:
		return true
	if bool(session.get("intro_active")):
		return true
	var talk: Variant = session.get("dialogue_ui")
	if talk is FieldDialogue and (talk as FieldDialogue).active:
		return true
	var player: Variant = session.get("player")
	return player is PlayerController and not (player as PlayerController).life.is_alive()

## The objective under the "救助" title, without repeating that word.
func objective() -> String:
	var value: String = str(state.get("objective", ""))
	for prefix: String in ["救助：", "救助:"]:
		if value.begins_with(prefix):
			return value.trim_prefix(prefix)
	return value

func slip_rect() -> Rect2:
	var goal: String = objective()
	var lines: float = font.get_multiline_string_size(goal, HORIZONTAL_ALIGNMENT_LEFT, WIDTH - 40, UiTheme.SIZE_SMALL + 2).y
	var rect: Rect2 = Rect2(Vector2(LEFT, TOP), Vector2(WIDTH, 58 + lines + 16))
	var others: Array[Rect2] = protected.call() if protected.is_valid() else []
	for other: Rect2 in others:
		if rect.intersects(other):
			rect.position.y = maxf(rect.position.y, other.end.y + 12)
	return rect

func _process(delta: float) -> void:
	var room: Variant = session.get("room") if session != null else null
	var data: Variant = session.get("data") if session != null else null
	if room != _room or not is_same(data, _data):
		_room = room
		_data = data
		refresh()
	if not get_tree().paused and settled_age >= 0.0 and not blocked():
		settled_age += delta
	queue_redraw()

func _ink(at: Vector2, value: String, size_px: int, color: Color, width: float = -1.0) -> Dictionary:
	draw_multiline_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, width, size_px, -1, color)
	return {"text": value, "color": color}

func _paper(rect: Rect2, color: Color) -> Dictionary:
	InkDraw.paper(self, rect, color, 990, DuskStyle.WOBBLE, 4)
	return {"rect": rect, "color": color}

func state_color(value: String) -> Color:
	match STATES.get(value, ""):
		"growth": return DuskStyle.GROWTH
		"life": return DuskStyle.LIFE
	return DuskStyle.INK

func _draw() -> void:
	drawn = {}
	if not showing() or blocked():
		return
	var rect: Rect2 = slip_rect()
	var record: Dictionary = {"rect": rect, "state": state.get("state", ""), "id": state.get("id", "")}
	record["paper"] = _paper(rect, Color(DuskStyle.PAPER_DAY, 0.94))
	InkDraw.rough_rect(self, rect, Color(DuskStyle.INK, 0.6), 1.4, 991, DuskStyle.WOBBLE)
	record["title"] = _ink(rect.position + Vector2(20, 32), str(state.get("title", "救助")), UiTheme.SIZE_SMALL + 2, DuskStyle.LIFE)
	var value: String = str(state.get("state", ""))
	if value != RUNNING:
		record["status"] = _ink(rect.position + Vector2(90, 32), value, UiTheme.SIZE_SMALL + 2, state_color(value).darkened(0.15) if value == "已完成" else state_color(value))
	record["objective"] = _ink(rect.position + Vector2(20, 64), objective(), UiTheme.SIZE_SMALL + 2, DuskStyle.INK, rect.size.x - 40)
	drawn = record
