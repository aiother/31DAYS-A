extends "res://prototypes/EXP-003/slots_base.gd"
## Variant 2 · 黄昏卡片: three wide paper cards in a row. Each card's top strip
## is that slot's own sky — the dusk of its day with the sun where the day
## stood — and the details sit underneath. Completed slots wear a gold edge.

func variant_name() -> String:
	return "2 · 黄昏卡片"

func card_size() -> Vector2:
	return Vector2(520, 400)

func row_position() -> Vector2:
	return Vector2(120, 300)

func row_separation() -> int:
	return 40

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.09, 0.06, 0.08))
	InkDraw.wash(self, Rect2(0, 0, size.x, size.y), Color(DuskStyle.DUSK_TOP, 0.4), Color(DuskStyle.DUSK_BOTTOM, 0.15))
	_draw_header()

func _draw_card(card: Button, index: int, focused: bool) -> void:
	var state: String = data.call("state", index)
	var time: Dictionary = slot_time(index)
	var lift: float = -18.0 if focused else 0.0
	var rect: Rect2 = Rect2(Vector2(0, lift), card.size)
	var record: Dictionary = {"state": state}
	if state == "empty":
		# Dashed outline: an empty place waiting for a story.
		var corners: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
		for side: int in range(4):
			var a: Vector2 = corners[side]
			var b: Vector2 = corners[(side + 1) % 4]
			for step: int in range(0, 16, 2):
				card.draw_line(a.lerp(b, step / 16.0), a.lerp(b, (step + 1) / 16.0), Color(DuskStyle.PAPER_DAY, 0.7 if focused else 0.4), 2.0)
		card.draw_string(font, rect.position + Vector2(0, rect.size.y * 0.5), "＋ 新的开始" if mode == "new" else "空槽", HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, UiTheme.SIZE_HEADING, Color(DuskStyle.PAPER_DAY, 0.8))
		card.draw_string(font, rect.position + Vector2(0, 50), "槽 " + NUMERALS[index], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, UiTheme.SIZE_BODY, Color(DuskStyle.PAPER_DAY, 0.6))
		_record(index, record)
		return
	InkDraw.paper(card, rect, DuskStyle.paper_color(time) if state != "unreadable" else Color(DuskStyle.PAPER_DAY).darkened(0.3), 120 + index, DuskStyle.WOBBLE, 6)
	var sky: Rect2 = Rect2(rect.position + Vector2(12, 12), Vector2(rect.size.x - 24, 130))
	var dusk: float = DuskStyle.dusk(time)
	if state == "unreadable":
		card.draw_rect(sky, Color(0.3, 0.28, 0.28))
		card.draw_string(font, sky.position + Vector2(0, 82), "无法读取", HORIZONTAL_ALIGNMENT_CENTER, sky.size.x, UiTheme.SIZE_HEADING, DuskStyle.PAPER_DAY)
	else:
		InkDraw.wash(card, sky, DuskStyle.DUSK_TOP.lerp(Color("8fb3c8"), 1.0 - dusk), DuskStyle.DUSK_BOTTOM.lerp(Color("f3e2b8"), 1.0 - dusk))
		var horizon: float = sky.end.y - 28
		var sun: Vector2 = Vector2(sky.position.x + sky.size.x * clampf(float(time["day_progress"]), 0.05, 0.95), horizon)
		InkDraw.glow(card, sun, 26, DuskStyle.SUN, 1.0)
		card.draw_circle(sun, 14, DuskStyle.SUN)
		card.draw_rect(Rect2(sky.position.x, horizon, sky.size.x, sky.end.y - horizon), Color(0.15, 0.09, 0.12, 0.85))
		card.draw_string(font, sky.position + Vector2(20, 44), "槽 " + NUMERALS[index], HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_HEADING, DuskStyle.PAPER_DAY)
		record["sky_dusk"] = dusk
	InkDraw.rough_rect(card, rect, Color(DuskStyle.INK, 0.9 if focused else 0.55), 3.0 if focused else 1.6, 130 + index, DuskStyle.WOBBLE)
	if state == "completed":
		card.draw_rect(rect.grow(-4), Color(DuskStyle.GROWTH, 0.9), false, 3.0)
		card.draw_rect(rect.grow(-10), Color(DuskStyle.GROWTH, 0.5), false, 1.5)
	if state == "unreadable":
		card.draw_string(font, rect.position + Vector2(30, 210), "存档文件损坏或版本不符", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_BODY, DuskStyle.INK)
		card.draw_string(font, rect.position + Vector2(30, 260), "可在新游戏中覆盖此槽", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_SMALL, Color(DuskStyle.INK, 0.7))
		_record(index, record)
		return
	var slot: Dictionary = data.slots[index]
	var lines: Array[String] = slot_lines(index)
	card.draw_string(font, rect.position + Vector2(30, 186), lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_BODY, DuskStyle.LIFE)
	card.draw_string(font, rect.position + Vector2(30, 228), lines[1], HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_SMALL, DuskStyle.INK)
	draw_shards(card, rect.position + Vector2(300, 222), int(slot["health"]), 0.8)
	card.draw_string(font, rect.position + Vector2(30, 268), lines[2], HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_SMALL, DuskStyle.INK)
	card.draw_string(font, rect.position + Vector2(30, 308), lines[3], HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_SMALL, DuskStyle.INK)
	if state == "completed":
		card.draw_string(font, rect.position + Vector2(30, 360), "已通关 · 夕阳将至", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_BODY, DuskStyle.GROWTH.darkened(0.25))
	record["lines"] = lines
	_record(index, record)

func _record(index: int, record: Dictionary) -> void:
	if drawn.get("cards") == null:
		drawn["cards"] = {}
	drawn["cards"][index] = record
