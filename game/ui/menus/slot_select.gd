class_name SlotSelect
extends MenuScreen
## UI-004 slot selection, EXP-003 variant 1 · 书签 with variant 2's sky strip
## on each bookmark (user, 2026-10-21). Three tall bookmarks side by side; the
## selected one rises. Each shows its own day's sky and paper tint, its title,
## day and countdown, play time, life shards, possibility, pearls and last
## checkpoint. Key colours never follow the slot's day.
##
## Rows come from CheckpointLab.slot_summaries() (SYS-008). Choosing a slot
## calls back into LifeUI, which keeps A-013 and the overwrite rules.
const NUMERALS: Array[String] = ["一", "二", "三"]
const CARD: Vector2 = Vector2(320, 620)
const GAP: float = 60.0
const LIFT: float = 36.0
const SKY_HEIGHT: float = 120.0
const MOOD: Dictionary = {"day": 2, "day_progress": 0.5}

## "continue" or "new".
var mode: String = "continue"
var rows: Array[Dictionary] = []
var cards: Array[Button] = []
var back_button: InkButton
## Callable(index: int) for a chosen slot (0-based).
var on_pick: Callable
var _row: HBoxContainer

func _ready() -> void:
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", int(GAP))
	add_child(_row)
	for i: int in range(3):
		var card: Button = Button.new()
		card.custom_minimum_size = CARD
		card.flat = true
		card.focus_mode = Control.FOCUS_ALL
		for name: String in UiTheme.BUTTON_STATES:
			card.add_theme_stylebox_override(name, StyleBoxEmpty.new())
		card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		card.draw.connect(func() -> void: _draw_card(card, i))
		card.focus_entered.connect(card.queue_redraw)
		card.focus_exited.connect(card.queue_redraw)
		card.mouse_entered.connect(func() -> void:
			if card.focus_mode != Control.FOCUS_NONE: card.grab_focus())
		card.pressed.connect(func() -> void:
			if dialog == null and on_pick.is_valid(): on_pick.call(i))
		_row.add_child(card)
		cards.append(card)
		buttons.append(card)
	var back_row: HBoxContainer = HBoxContainer.new()
	back_row.name = "BackRow"
	add_child(back_row)
	back_button = light_button(back_row, "返回主界面", _go_back, 26)
	for i: int in range(3):
		var card: Button = cards[i]
		card.focus_neighbor_left = card.get_path_to(cards[maxi(0, i - 1)])
		card.focus_neighbor_right = card.get_path_to(cards[mini(2, i + 1)])
		card.focus_neighbor_bottom = card.get_path_to(back_button)
		card.focus_neighbor_top = card.get_path()
	back_button.focus_neighbor_left = back_button.get_path()
	back_button.focus_neighbor_right = back_button.get_path_to(cards[0])
	_layout()

func _go_back() -> void:
	if on_back.is_valid():
		on_back.call()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _row != null:
		_layout()

func _layout() -> void:
	var width: float = CARD.x * 3.0 + GAP * 2.0
	_row.position = Vector2((size.x - width) * 0.5, 250)
	_row.size = Vector2(width, CARD.y)
	var back_row: Control = get_node("BackRow")
	back_row.position = Vector2(140, size.y - 116)

## back_label: 返回主界面 normally; 返回游戏 when a session is still open.
func open(selected_mode: String, summaries: Array[Dictionary], back_label: String = "返回主界面") -> void:
	close_dialog(false)
	mode = selected_mode
	rows = summaries
	back_button.text = back_label
	set_prompt("")
	visible = true
	_layout()
	# Continue starts on the first slot in progress; new game on the first empty one.
	var first: int = 0
	for i: int in range(rows.size()):
		var state: String = str(rows[i]["state"])
		if (mode == "continue" and state == "progress") or (mode == "new" and state == "empty"):
			first = i
			break
	cards[first].grab_focus()

func state(index: int) -> String:
	return str(rows[index]["state"]) if index < rows.size() else "empty"

func slot_name(index: int) -> String:
	return "槽" + NUMERALS[index]

func heading() -> String:
	return "继续游戏 · 选择存档" if mode == "continue" else "新游戏 · 选择存档位置"

func card_rect(index: int) -> Rect2:
	var card: Button = cards[index]
	var lift: float = -LIFT if card.has_focus() else 0.0
	return Rect2(card.get_global_rect().position - get_global_rect().position + Vector2(0, lift), card.size)

func focused() -> int:
	return cards.find(get_viewport().gui_get_focus_owner())

func sheet_time() -> Dictionary:
	return MOOD

## The slot's own time for its sky and paper; completed slots sit at full dusk.
func slot_time(index: int) -> Dictionary:
	var row: Dictionary = rows[index] if index < rows.size() else {}
	if state(index) in ["progress", "completed"]:
		return {"day": int(row["day"]), "day_progress": float(row["day_progress"]), "final_active": state(index) == "completed"}
	return {"day": 1, "day_progress": 0.0}

static func play_time(seconds: float) -> String:
	var total: int = int(seconds)
	return "%d:%02d:%02d" % [int(total / 3600.0), int(total / 60.0) % 60, total % 60]

func _draw() -> void:
	drawn["cards"] = drawn.get("cards", {})
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.10, 0.06, 0.08))
	InkDraw.wash(self, Rect2(Vector2.ZERO, size), Color(DuskStyle.DUSK_TOP, 0.35), Color(DuskStyle.DUSK_BOTTOM, 0.25))
	InkDraw.glow(self, Vector2(size.x * 0.5, size.y * 0.55), 520, DuskStyle.SUN, 0.35)
	var shown_heading: String = ink(self, Vector2(140, 120), heading(), UiTheme.SIZE_TITLE, DuskStyle.PAPER_DAY)["text"]
	InkDraw.rough_line(self, Vector2(140, 140), Vector2(520, 140), Color(DuskStyle.LIFE, 0.85), 2.6, 91, 1.2)
	var hint: String = "← → 选择 · Enter / A 确认 · Esc / Back 返回"
	draw_string(font, Vector2(140, 182), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_SMALL, Color(DuskStyle.PAPER_DAY, 0.7))
	var hint_size: Vector2 = font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_SMALL)
	drawn["heading"] = shown_heading
	drawn["header_rect"] = Rect2(140, 120 - font.get_ascent(UiTheme.SIZE_TITLE), maxf(380.0, hint_size.x), 182 - 120 + font.get_ascent(UiTheme.SIZE_TITLE) + font.get_descent(UiTheme.SIZE_SMALL))
	drawn["focused"] = focused()
	drawn["back_rect"] = back_button.get_global_rect()
	draw_prompt(MOOD)

func _draw_card(card: Button, index: int) -> void:
	var current: String = state(index)
	var time: Dictionary = slot_time(index)
	var lift: float = -LIFT if card.has_focus() else 0.0
	var w: float = card.size.x
	var h: float = card.size.y
	var shape: PackedVector2Array = PackedVector2Array([Vector2(0, lift), Vector2(w, lift), Vector2(w, h + lift), Vector2(w * 0.5, h - 46 + lift), Vector2(0, h + lift)])
	var paper: Color = DuskStyle.paper_color(time)
	if current == "empty":
		paper = Color(DuskStyle.PAPER_DAY, 0.35)
	elif current == "unreadable":
		paper = Color(DuskStyle.PAPER_DAY, 0.55).darkened(0.25)
	card.draw_colored_polygon(shape, paper)
	var sky: Rect2 = Rect2(Vector2(12, 12 + lift), Vector2(w - 24, SKY_HEIGHT))
	var record: Dictionary = {"state": current, "paper": paper, "rect": card_rect(index), "lift": lift}
	var keys: Dictionary = {}
	if current in ["progress", "completed"]:
		record["sky"] = SkyStrip.draw(card, sky, time)
	elif current == "unreadable":
		card.draw_rect(sky, Color(0.30, 0.28, 0.28))
	else:
		card.draw_rect(sky, Color(DuskStyle.PAPER_DAY, 0.18))
	var outline: PackedVector2Array = shape.duplicate()
	outline.append(shape[0])
	card.draw_polyline(outline, Color(DuskStyle.INK, 0.9 if card.has_focus() else 0.5), 3.0 if card.has_focus() else 1.6, true)
	var on_sky: Color = DuskStyle.PAPER_DAY if current != "empty" else Color(DuskStyle.PAPER_DAY, 0.8)
	card.draw_string(font, sky.position + Vector2(18, 44), "槽 " + NUMERALS[index], HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_HEADING, on_sky)
	var top: float = sky.end.y
	match current:
		"empty":
			card.draw_string(font, Vector2(0, top + 190), "空", HORIZONTAL_ALIGNMENT_CENTER, w, 72, Color(DuskStyle.INK, 0.35))
			record["label"] = _text(card, Vector2(0, top + 250), "新的开始" if mode == "new" else "没有存档", UiTheme.SIZE_BODY, Color(DuskStyle.INK, 0.55), HORIZONTAL_ALIGNMENT_CENTER, w)
		"unreadable":
			for i: int in range(6):
				InkDraw.rough_line(card, Vector2(20 + i * 50, top + 140), Vector2(50 + i * 50, top + 176), Color(DuskStyle.INK, 0.5), 2.0, 110 + i, 2.0)
			record["label"] = _key(keys, "label", card, Vector2(0, top + 240), "无法读取", UiTheme.SIZE_HEADING, DuskStyle.LIFE, HORIZONTAL_ALIGNMENT_CENTER, w)
			record["note"] = _text(card, Vector2(28, top + 300), "存档文件损坏或版本不符\n可在新游戏中覆盖此槽", UiTheme.SIZE_SMALL, Color(DuskStyle.INK, 0.75), HORIZONTAL_ALIGNMENT_CENTER, w - 56)
		_:
			var row: Dictionary = rows[index]
			var day: int = int(row["day"])
			var lines: Array[String] = []
			card.draw_string(font, Vector2(0, top + 44), "末日前31天", HORIZONTAL_ALIGNMENT_CENTER, w, UiTheme.SIZE_BODY, Color(DuskStyle.INK, 0.75))
			lines.append(_key(keys, "date", card, Vector2(28, top + 96), "第 %d 日 · 末日前 %d 天" % [day, 4 - day], UiTheme.SIZE_BODY, DuskStyle.LIFE))
			lines.append(_text(card, Vector2(28, top + 142), "游戏时长 " + play_time(float(row["play_seconds"])), UiTheme.SIZE_SMALL, DuskStyle.INK))
			lines.append(_text(card, Vector2(28, top + 188), "生命", UiTheme.SIZE_SMALL, DuskStyle.INK))
			record["shards"] = _shards(card, Vector2(96, top + 182), int(row["health"]), int(row["max_health"]), DuskStyle.LIFE)
			keys["shard"] = record["shards"]["color"]
			lines.append(_key(keys, "possibility", card, Vector2(28, top + 234), "可能性 %d / %d" % [int(row["balance"]), int(row["maximum"])], UiTheme.SIZE_SMALL, DuskStyle.POSSIBILITY.darkened(0.2)))
			lines.append(_text(card, Vector2(28, top + 274), "珍珠 %d" % int(row["pearls"]), UiTheme.SIZE_SMALL, DuskStyle.INK))
			var checkpoint: String = str(row["checkpoint_name"]) if not str(row["checkpoint_name"]).is_empty() else str(row["checkpoint"])
			lines.append(_text(card, Vector2(28, top + 320), "最后检查点\n" + checkpoint, UiTheme.SIZE_SMALL, Color(DuskStyle.INK, 0.85), HORIZONTAL_ALIGNMENT_LEFT, w - 56))
			record["lines"] = lines
			if current == "completed":
				var seal: Dictionary = _seal(card, Vector2(w * 0.72, h - 88 + lift), "已通关", DuskStyle.LIFE)
				record["seal"] = seal["text"]
				keys["seal"] = seal["color"]
	record["keys"] = keys
	var cards_record: Dictionary = drawn.get("cards", {})
	cards_record[index] = record
	drawn["cards"] = cards_record

## Draws text and hands it back, so a record can only come from a real draw.
## Draws a key-coloured text and records the colour it was really drawn in.
func _key(keys: Dictionary, name: String, ci: CanvasItem, at: Vector2, value: String, size_px: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> String:
	var shown: Dictionary = ink(ci, at, value, size_px, color, align, width)
	keys[name] = shown["color"]
	return shown["text"]

func _text(ci: CanvasItem, at: Vector2, value: String, size_px: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> String:
	ci.draw_multiline_string(font, at, value, align, width, size_px, -1, color)
	return value

## The colour returned is the one the filled shards were drawn in.
func _shards(ci: CanvasItem, at: Vector2, count: int, maximum: int, color: Color) -> Dictionary:
	for i: int in range(maxi(count, maximum)):
		var c: Vector2 = at + Vector2(i * 24.0, 0)
		var points: PackedVector2Array = PackedVector2Array([c + Vector2(0, -14), c + Vector2(6, 0), c + Vector2(0, 14), c + Vector2(-6, 0)])
		if i < count:
			ci.draw_colored_polygon(points, color)
		else:
			points.append(points[0])
			ci.draw_polyline(points, Color(DuskStyle.INK, 0.4), 1.4, true)
	return {"filled": count, "slots": maxi(count, maximum), "color": color}

func _seal(ci: CanvasItem, center: Vector2, text: String, color: Color, radius: float = 54.0) -> Dictionary:
	ci.draw_set_transform(center, -0.25, Vector2.ONE)
	InkDraw.rough_circle(ci, Vector2.ZERO, radius, Color(color, 0.9), 4.0, 77, 1.5)
	InkDraw.rough_circle(ci, Vector2.ZERO, radius - 8, Color(color, 0.7), 2.0, 78, 1.0)
	var shown: Dictionary = ink(ci, Vector2(-radius, 12), text, 30, color, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return shown
