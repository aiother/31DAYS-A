class_name SkyStrip
extends RefCounted
## UI-004: a slot's own sky (EXP-003 variant 2 strip on the variant 1
## bookmark). The dusk deepens with the saved day and the sun sits where that
## day stood. Only mood colours move; key colours stay in DuskStyle.
const NOON_TOP: Color = Color("8fb3c8")
const NOON_BOTTOM: Color = Color("f3e2b8")
const GROUND: Color = Color(0.15, 0.09, 0.12, 0.85)

## time: {"day", "day_progress", "final_active"} like DuskStyle expects.
## Returns what was drawn so tests can compare skies between slots.
static func draw(ci: CanvasItem, rect: Rect2, time: Dictionary) -> Dictionary:
	var dusk: float = DuskStyle.dusk(time)
	var top: Color = DuskStyle.DUSK_TOP.lerp(NOON_TOP, 1.0 - dusk)
	var bottom: Color = DuskStyle.DUSK_BOTTOM.lerp(NOON_BOTTOM, 1.0 - dusk)
	InkDraw.wash(ci, rect, top, bottom)
	var horizon: float = rect.end.y - 26.0
	var sun: Vector2 = Vector2(rect.position.x + rect.size.x * clampf(float(time.get("day_progress", 0.0)), 0.06, 0.94), horizon)
	InkDraw.glow(ci, sun, 26, DuskStyle.SUN, 1.0)
	ci.draw_circle(sun, 13, DuskStyle.SUN)
	ci.draw_rect(Rect2(rect.position.x, horizon, rect.size.x, rect.end.y - horizon), GROUND)
	return {"dusk": dusk, "top": top, "bottom": bottom, "sun_x": (sun.x - rect.position.x) / rect.size.x}
