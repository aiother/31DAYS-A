extends "res://prototypes/EXP-003/slots_base.gd"
## Variant 1 · 书签: three tall bookmarks stand side by side on a dark desk; the
## selected one rises. Each bookmark's paper takes its own slot's dusk, so a
## later day reads warmer at a glance; key colours stay fixed.

func variant_name() -> String:
	return "1 · 书签"

func card_size() -> Vector2:
	return Vector2(320, 620)

func row_position() -> Vector2:
	return Vector2(400, 230)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.10, 0.06, 0.08))
	InkDraw.wash(self, Rect2(Vector2.ZERO, size), Color(DuskStyle.DUSK_TOP, 0.35), Color(DuskStyle.DUSK_BOTTOM, 0.25))
	InkDraw.glow(self, Vector2(size.x * 0.5, size.y * 0.55), 520, DuskStyle.SUN, 0.35)
	_draw_header()

func _draw_card(card: Button, index: int, focused: bool) -> void:
	var state: String = data.call("state", index)
	var time: Dictionary = slot_time(index)
	var lift: float = -36.0 if focused else 0.0
	var w: float = card.size.x
	var h: float = card.size.y
	var shape: PackedVector2Array = PackedVector2Array([Vector2(0, lift), Vector2(w, lift), Vector2(w, h + lift), Vector2(w * 0.5, h - 46 + lift), Vector2(0, h + lift)])
	var paper: Color = DuskStyle.paper_color(time)
	if state == "empty":
		paper = Color(DuskStyle.PAPER_DAY, 0.35)
	elif state == "unreadable":
		paper = Color(DuskStyle.PAPER_DAY, 0.55).darkened(0.25)
	card.draw_colored_polygon(shape, paper)
	var outline: PackedVector2Array = shape.duplicate()
	outline.append(shape[0])
	card.draw_polyline(outline, Color(DuskStyle.INK, 0.9 if focused else 0.5), 3.0 if focused else 1.6, true)
	var top: float = 70.0 + lift
	card.draw_string(font, Vector2(0, top), "槽 " + NUMERALS[index], HORIZONTAL_ALIGNMENT_CENTER, w, UiTheme.SIZE_HEADING, DuskStyle.INK)
	InkDraw.rough_line(card, Vector2(w * 0.3, top + 16), Vector2(w * 0.7, top + 16), Color(DuskStyle.LIFE, 0.8), 2.2, 100 + index, 1.0)
	var record: Dictionary = {"state": state}
	match state:
		"empty":
			card.draw_string(font, Vector2(0, h * 0.45 + lift), "空", HORIZONTAL_ALIGNMENT_CENTER, w, 72, Color(DuskStyle.INK, 0.35))
			record["label"] = drawn_text(card, Vector2(0, h * 0.45 + 60 + lift), "新的开始" if mode == "new" else "没有存档", UiTheme.SIZE_BODY, Color(DuskStyle.INK, 0.5), HORIZONTAL_ALIGNMENT_CENTER, w)
		"unreadable":
			for i: int in range(6):
				InkDraw.rough_line(card, Vector2(20 + i * 50, h * 0.42 + lift), Vector2(50 + i * 50, h * 0.48 + lift), Color(DuskStyle.INK, 0.5), 2.0, 110 + i, 2.0)
			record["label"] = drawn_text(card, Vector2(0, h * 0.58 + lift), "无法读取", UiTheme.SIZE_HEADING, DuskStyle.LIFE, HORIZONTAL_ALIGNMENT_CENTER, w)
		_:
			var slot: Dictionary = data.slots[index]
			card.draw_string(font, Vector2(0, top + 70), "末日前31天", HORIZONTAL_ALIGNMENT_CENTER, w, UiTheme.SIZE_BODY, Color(DuskStyle.INK, 0.75))
			var lines: Array[String] = slot_lines(index)
			var y: float = top + 140
			var shown: Array[String] = []
			for line: String in lines:
				shown.append(drawn_text(card, Vector2(28, y), line, UiTheme.SIZE_SMALL, DuskStyle.INK, HORIZONTAL_ALIGNMENT_LEFT, w - 56))
				y += 58
			draw_shards(card, Vector2(40, y + 10), int(slot["health"]))
			record["lines"] = shown
			if state == "completed":
				record["seal"] = draw_seal(card, Vector2(w * 0.68, h - 150 + lift), "已通关")
	if drawn.get("cards") == null:
		drawn["cards"] = {}
	drawn["cards"][index] = record
