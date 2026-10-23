class_name CenterNotice
extends Control
## UI-010 (BL-044): short notices in the upper middle of the screen for task
## changes (quest_changed), things obtained (item_obtained) and the text the
## sessions pass to FieldDialogue.show_notice(). One at a time, in order, each
## for SECONDS; the queue waits (clock stopped) while hidden by dialogue,
## story, pause or death, or while no spot is clear.
##
## One event, one notice. Every quest_changed / item_obtained signal is its
## own event (SYS-009 sends each once, after a good save), so signals are
## never dropped, even when two read the same. A show_notice() text and a
## signal for the same event within MERGE_SECONDS become one notice -- the
## signal gives the title and colour, the text its detail line; each text
## joins at most one signal and each signal at most one text. "Same event":
## a task ending (完成 / 放弃 / 过期) and a text naming it, or an obtained
## thing and a "获得…" text that names it. The same text twice inside the
## window is dropped.
const WIDTH: float = 560.0
const TOPS: Array[float] = [236.0, 380.0, 500.0, 640.0]
const SECONDS: float = 2.5
const FADE_IN: float = 0.25
const FADE_OUT: float = 0.5
const MERGE_SECONDS: float = 1.5
const QUEST_TITLES: Dictionary = {"开始": "救助开始", "进展": "救助进展", "完成": "救助完成", "放弃": "已放弃救助", "过期": "救助已过期"}

var session: Node
var hud: Control
## Rects to keep clear of; set by LifeUI.
var avoid: Callable
var font: Font
## Waiting notices, oldest first; the head is the one on show.
var queue: Array[Dictionary] = []
## Every notice ever queued this session, for tests and the merge window.
var history: Array[Dictionary] = []
var age: float = 0.0
var clock: float = 0.0
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
	if session.has_signal("item_obtained"):
		session.connect("item_obtained", _on_item_obtained)

## The dialogue node is created by the session; LifeUI hands it over.
func listen(dialogue: Node) -> void:
	if dialogue != null and dialogue.has_signal("noticed") and not dialogue.is_connected("noticed", _on_noticed):
		dialogue.connect("noticed", _on_noticed)

func _on_quest_changed(kind: String, value: Dictionary) -> void:
	var color: Color = DuskStyle.GROWTH if kind == "完成" else (DuskStyle.LIFE if kind in ["放弃", "过期"] else DuskStyle.INK)
	push({"title": QUEST_TITLES.get(kind, "救助"), "line": str(value.get("objective", "")), "color": color, "source": "quest", "kind": kind})

func _on_item_obtained(kind: String, display_name: String) -> void:
	push({"title": "获得 · " + display_name, "line": "" if kind == display_name else kind, "color": DuskStyle.GROWTH, "source": "item", "kind": kind, "name": display_name})

func _on_noticed(message: String) -> void:
	var parts: PackedStringArray = message.split(" · ", true, 1)
	var color: Color = DuskStyle.INK
	if message.contains("放弃") or message.contains("过期") or message.contains("失去"):
		color = DuskStyle.LIFE
	elif message.contains("完成") or message.begins_with("获得"):
		color = DuskStyle.GROWTH
	push({"title": parts[0], "line": parts[1] if parts.size() > 1 else "", "color": color, "source": "notice", "text": message})

## Whether a show_notice() text and a signal tell of the same event.
func same_event(a: Dictionary, b: Dictionary) -> bool:
	var text: Dictionary = a if a["source"] == "notice" else b
	var other: Dictionary = b if a["source"] == "notice" else a
	if text["source"] != "notice" or other["source"] == "notice":
		return false
	var message: String = text["text"]
	if other["source"] == "quest":
		return other["kind"] in ["完成", "放弃", "过期"] and message.contains(other["kind"])
	return message.begins_with("获得") and message.contains(other["name"])

func push(entry: Dictionary) -> void:
	entry["at"] = clock
	for known: Dictionary in history:
		if clock - float(known["at"]) > MERGE_SECONDS:
			continue
		if entry["source"] == "notice" and known["source"] == "notice" and known["text"] == entry["text"]:
			return
		if not known.get("merged", false) and same_event(known, entry):
			# The signal names the event; the text keeps its detail.
			var signal_entry: Dictionary = entry if entry["source"] != "notice" else known
			var text_entry: Dictionary = entry if entry["source"] == "notice" else known
			known["title"] = signal_entry["title"]
			known["color"] = signal_entry["color"]
			known["line"] = text_entry["line"]
			known["merged"] = true
			return
	history.append(entry)
	queue.append(entry)

func showing() -> bool:
	return not queue.is_empty()

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

func box_height(entry: Dictionary) -> float:
	var line: String = str(entry.get("line", ""))
	var under: float = font.get_multiline_string_size(line, HORIZONTAL_ALIGNMENT_CENTER, WIDTH - 60, UiTheme.SIZE_SMALL + 2).y if not line.is_empty() else 0.0
	return 64.0 + under + (12.0 if under > 0.0 else 0.0)

## The first clear spot, or an empty rect when every one is taken.
func place(entry: Dictionary) -> Rect2:
	var others: Array[Rect2] = avoid.call() if avoid.is_valid() else []
	var view: float = size.x if size.x > 0.0 else 1920.0
	for top: float in TOPS:
		var rect: Rect2 = Rect2(Vector2((view - WIDTH) * 0.5, top), Vector2(WIDTH, box_height(entry)))
		var clear_spot: bool = true
		for other: Rect2 in others:
			clear_spot = clear_spot and not rect.intersects(other)
		if clear_spot:
			return rect
	return Rect2()

func alpha() -> float:
	return clampf(minf(age / FADE_IN, (SECONDS - age) / FADE_OUT), 0.0, 1.0)

func _process(delta: float) -> void:
	if not get_tree().paused:
		clock += delta
	# The head waits, its clock stopped, while it cannot be shown.
	if showing() and not blocked() and not place(queue[0]).size == Vector2.ZERO:
		age += delta
		if age >= SECONDS:
			queue.pop_front()
			age = 0.0
	queue_redraw()

func _ink(at: Vector2, value: String, size_px: int, color: Color, width: float) -> Dictionary:
	draw_multiline_string(font, at, value, HORIZONTAL_ALIGNMENT_CENTER, width, size_px, -1, color)
	return {"text": value, "color": color}

func _paper(rect: Rect2, color: Color) -> Dictionary:
	InkDraw.paper(self, rect, color, 995, DuskStyle.WOBBLE, 4)
	return {"rect": rect, "color": color}

func _bar(rect: Rect2, color: Color) -> Dictionary:
	draw_rect(rect, color)
	return {"rect": rect, "color": color}

func _draw() -> void:
	drawn = {}
	if not showing() or blocked():
		return
	var entry: Dictionary = queue[0]
	var rect: Rect2 = place(entry)
	if rect.size == Vector2.ZERO:
		return
	var a: float = alpha()
	var key: Color = entry["color"]
	var record: Dictionary = {"rect": rect, "alpha": a, "queued": queue.size()}
	record["paper"] = _paper(rect, Color(DuskStyle.PAPER_DAY, 0.95 * a))
	InkDraw.rough_rect(self, rect, Color(DuskStyle.INK, 0.6 * a), 1.4, 996, DuskStyle.WOBBLE)
	# The key colour: a bar along the top edge and the title.
	record["bar"] = _bar(Rect2(rect.position + Vector2(20, 10), Vector2(rect.size.x - 40, 5)), Color(key, a))
	var title_color: Color = key.darkened(0.25) if key == DuskStyle.GROWTH else key
	record["title"] = _ink(rect.position + Vector2(0, 50), str(entry["title"]), UiTheme.SIZE_HEADING - 4, Color(title_color, a), rect.size.x)
	if not str(entry.get("line", "")).is_empty():
		record["line"] = _ink(rect.position + Vector2(30, 84), str(entry["line"]), UiTheme.SIZE_SMALL + 2, Color(DuskStyle.INK, 0.85 * a), rect.size.x - 60)
	drawn = record
