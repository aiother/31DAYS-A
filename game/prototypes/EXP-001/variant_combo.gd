extends "res://prototypes/EXP-001/variant_emblem.gd"
## 方案四（组合，用户 2026-10-20 第1轮挑选）：方案二的徽记 + 方案三的底部地平线时间，
## 地平线上显示时刻；不再用 Tab 展开，完整时间与天数进展改由暂停菜单右侧的时钟展示。
## 透支时的画面失真滤镜由预览场景统一处理（见 hud_preview.gd）。

func title() -> String:
	return "方案四（组合）· 徽记 + 地平线时刻 + 透支失真 + Esc 暂停菜单时钟"

func _draw_time() -> void:
	var y: float = size.y - 36
	draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, 1, 1, 0.18), 2.0)
	var x: float = size.x * state.day_progress()
	draw_line(Vector2(0, y), Vector2(x, y), Color(1.0, 0.7, 0.4, 0.6), 2.0)
	draw_circle(Vector2(x, y), 8, Color(1.0, 0.75, 0.4))
	text(Vector2(clampf(x - 34, 10, size.x - 200), y - 16), state.clock_text(), 22, INK)
	text(Vector2(size.x - 200, y + 26), "第%d日 · 末日前%d天" % [state.day, state.days_left()], 16, Color(MUTED, 0.75))
