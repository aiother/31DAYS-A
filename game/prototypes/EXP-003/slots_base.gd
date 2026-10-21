extends "res://prototypes/EXP-003/screen_base.gd"
## Slot selection shared logic (T7-A, T7-E1, A-013). Slots sit side by side and
## are chosen with left / right; each shows its title, play time, character
## state and last checkpoint. Variants only lay out and draw the slot cards.
##
## continue: a slot in progress loads; a completed slot answers 游戏已通关 and
## stays here; empty and unreadable slots explain why they cannot be loaded.
## new: picking a slot asks to confirm, and warns when it overwrites progress.
const NUMERALS: Array[String] = ["一", "二", "三"]
var mode: String = "continue"
var cards: Array[Button] = []
var message: String = ""
var message_left: float = 0.0

func card_size() -> Vector2:
	return Vector2(300, 600)

func row_position() -> Vector2:
	return Vector2(420, 220)

func row_separation() -> int:
	return 60

func build() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.position = row_position()
	row.add_theme_constant_override("separation", row_separation())
	add_child(row)
	for i: int in range(3):
		var card: Button = Button.new()
		card.custom_minimum_size = card_size()
		card.flat = true
		card.focus_mode = Control.FOCUS_ALL
		for name: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			card.add_theme_stylebox_override(name, StyleBoxEmpty.new())
		card.draw.connect(func() -> void: _draw_card(card, i, card.has_focus()))
		card.focus_entered.connect(card.queue_redraw)
		card.focus_exited.connect(card.queue_redraw)
		card.mouse_entered.connect(card.grab_focus)
		card.pressed.connect(func() -> void: activate(i))
		row.add_child(card)
		cards.append(card)
		buttons.append(card)
	var back_row: HBoxContainer = HBoxContainer.new()
	back_row.position = Vector2(140, 950)
	add_child(back_row)
	make_button(back_row, "返回主界面", back, 26, back_tone())
	# Continue starts on the first loadable slot; new game on the first empty one.
	var first: int = 0
	for i: int in range(3):
		var state: String = data.call("state", i)
		if (mode == "continue" and state == "progress") or (mode == "new" and state == "empty"):
			first = i
			break
	cards[first].grab_focus.call_deferred()

func back_tone() -> String:
	return "light"

func heading() -> String:
	return "继续游戏 · 选择存档" if mode == "continue" else "新游戏 · 选择存档位置"

func _process(delta: float) -> void:
	super._process(delta)
	message_left = maxf(0.0, message_left - delta)
	for card: Button in cards:
		card.queue_redraw()

func say(text: String) -> void:
	message = text
	message_left = 2.5
	drawn["message"] = text

func activate(index: int) -> void:
	var state: String = data.call("state", index)
	var name: String = "槽" + NUMERALS[index]
	if mode == "continue":
		match state:
			"progress": preview.call("start_game", index)
			"completed": say("游戏已通关")
			"empty": say("%s 是空的，请从主界面选择新游戏" % name)
			"unreadable": say("%s 无法读取，可在新游戏中覆盖" % name)
		return
	if state == "empty":
		ask("在%s开始新游戏？" % name, "开始", func() -> void: _start_new(index))
	else:
		ask("在%s开始新游戏？\n将覆盖此槽现有进度" % name, "覆盖并开始", func() -> void: _start_new(index))

func _start_new(index: int) -> void:
	data.call("start_new", index)
	preview.call("start_game", index)

func back() -> void:
	preview.call("open_title")

## Common text block used by both variants.
func slot_lines(index: int) -> Array[String]:
	var slot: Dictionary = data.slots[index]
	return ["第 %d 日 · 末日前 %d 天" % [int(slot["day"]), 4 - int(slot["day"])],
		"游戏时长 " + Slots.play_time(float(slot["play_seconds"])),
		"可能性 %d / %d · 珍珠 %d" % [int(slot["balance"]), int(slot["maximum"]), int(slot["pearls"])],
		"最后检查点：" + Slots.checkpoint_name(str(slot["checkpoint"]))]

func slot_time(index: int) -> Dictionary:
	var slot: Dictionary = data.slots[index]
	if slot.is_empty() or slot.has("unreadable"):
		return {"day": 1, "day_progress": 0.0}
	return {"day": int(slot["day"]), "day_progress": float(slot["day_progress"]), "final_active": bool(slot["completed"])}

func draw_shards(ci: CanvasItem, at: Vector2, count: int, scale: float = 1.0) -> void:
	for i: int in range(count):
		var c: Vector2 = at + Vector2(i * 22.0 * scale, 0)
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -16) * scale, c + Vector2(6, 0) * scale, c + Vector2(0, 16) * scale, c + Vector2(-6, 0) * scale]), DuskStyle.LIFE)

func draw_seal(ci: CanvasItem, center: Vector2, text: String, radius: float = 54.0) -> void:
	ci.draw_set_transform(center, -0.25, Vector2.ONE)
	InkDraw.rough_circle(ci, Vector2.ZERO, radius, Color(DuskStyle.LIFE, 0.9), 4.0, 77, 1.5)
	InkDraw.rough_circle(ci, Vector2.ZERO, radius - 8, Color(DuskStyle.LIFE, 0.7), 2.0, 78, 1.0)
	ci.draw_string(font, Vector2(-radius, 12), text, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 30, DuskStyle.LIFE)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_card(_card: Button, _index: int, _focused: bool) -> void:
	pass

func _draw_header() -> void:
	ink_text(Vector2(140, 130), heading(), UiTheme.SIZE_TITLE, DuskStyle.PAPER_DAY)
	InkDraw.rough_line(self, Vector2(140, 150), Vector2(520, 150), Color(DuskStyle.LIFE, 0.85), 2.6, 91, 1.2)
	ink_text(Vector2(140, 190), "← → 选择 · Enter / A 确认 · Esc 返回", UiTheme.SIZE_SMALL, Color(DuskStyle.PAPER_DAY, 0.7))
	if message_left > 0.0:
		var alpha: float = clampf(message_left / 0.4, 0.0, 1.0)
		var box: Rect2 = Rect2(Vector2((size.x - 560) * 0.5, 880), Vector2(560, 56))
		DuskStyle.panel(self, box, MOOD, 95)
		ink_text(box.position + Vector2(0, 38), message, UiTheme.SIZE_BODY, Color(DuskStyle.LIFE, alpha), HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	drawn["heading"] = heading()
	drawn["focused"] = cards.find(get_viewport().gui_get_focus_owner())
