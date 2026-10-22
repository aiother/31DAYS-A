class_name InteractPrompt
extends Control
## UI-007 scene interaction prompt (BL-049, A-019): when the player is in
## range of something E / RB would act on (SYS-009 interaction_targets()), a
## small tag "E / RB · action" sits beside it on the player's side, in the
## inverse of the scene's base tone. Only the nearest usable target shows;
## nothing shows while paused, in a dialogue or under a story lock (the query
## already reports those as unavailable). Story save retries
## (retry_available) keep their own wording and get no prompt.
const KEYS: String = "E / RB"
const GAP: float = 36.0
## Tag bottom this far above the object, clear of the player's head.
const LIFT: float = 120.0
const MARGIN: float = 16.0
const HEIGHT: float = 44.0

var session: Node
var hud: FormalHud
var banner: AreaBanner
var font: Font
## What the last frame put on screen; read by tests.
var drawn: Dictionary = {}

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = UiTheme.font()

func setup(owner_session: Node, formal_hud: FormalHud, area_banner: AreaBanner = null) -> void:
	session = owner_session
	hud = formal_hud
	banner = area_banner

func _process(_delta: float) -> void:
	queue_redraw()

## The target to prompt for, or {} when none.
func pick() -> Dictionary:
	if session == null or not session.has_method("interaction_targets") or get_tree().paused:
		return {}
	if session.has_method("has_session") and not bool(session.call("has_session")):
		return {}
	var player: PlayerController = session.get("player") as PlayerController
	var best: Dictionary = {}
	var best_distance: float = INF
	for target: Dictionary in session.call("interaction_targets"):
		if not bool(target.get("available", false)) or not bool(target.get("in_range", false)):
			continue
		var distance: float = player.global_position.distance_to(target["position"]) if target.get("range_kind") != "unlimited" else 0.0
		if distance < best_distance:
			best_distance = distance
			best = target
	return best

## Light paper on a dark scene, dark ink on a light one (A-019).
func tone() -> String:
	var base: Color = RenderingServer.get_default_clear_color()
	var room: Variant = session.get("room") if session != null else null
	if room is Node and (room as Node).has_method("base_color"):
		base = (room as Node).call("base_color")
	return "light" if base.get_luminance() < 0.5 else "dark"

func to_screen(world: Vector2) -> Vector2:
	return (session.get("player") as Node2D).get_viewport().get_canvas_transform() * world

## Places the tag beside the target on the player's side, then keeps it on
## screen and clear of the HUD.
func place(target_screen: Vector2, player_screen: Vector2, width: float, unlimited: bool) -> Dictionary:
	var side: String = "right" if player_screen.x >= target_screen.x else "left"
	var rect: Rect2
	if unlimited:
		rect = Rect2(Vector2(player_screen.x - width * 0.5, player_screen.y - LIFT - 60.0 - HEIGHT), Vector2(width, HEIGHT))
		side = "above"
	elif side == "right":
		rect = Rect2(Vector2(target_screen.x + GAP, target_screen.y - LIFT - HEIGHT), Vector2(width, HEIGHT))
	else:
		rect = Rect2(Vector2(target_screen.x - GAP - width, target_screen.y - LIFT - HEIGHT), Vector2(width, HEIGHT))
	rect = _clamp(rect)
	for avoid: Rect2 in avoided():
		if rect.intersects(avoid):
			rect.position.y = avoid.end.y + 8.0
			rect = _clamp(rect)
	return {"rect": rect, "side": side}

func _clamp(rect: Rect2) -> Rect2:
	rect.position.x = clampf(rect.position.x, MARGIN, size.x - MARGIN - rect.size.x)
	rect.position.y = clampf(rect.position.y, MARGIN, size.y - MARGIN - rect.size.y)
	return rect

## HUD areas a prompt must not cover (real rects the HUD drew this frame).
func avoided() -> Array[Rect2]:
	var result: Array[Rect2] = []
	if hud != null:
		for key: String in ["emblem", "hint", "warning", "final", "banner"]:
			if hud.drawn.has(key) and hud.drawn[key].has("rect"):
				result.append(hud.drawn[key]["rect"])
	if banner != null and banner.drawn.has("rect"):
		result.append(banner.drawn["rect"])
	return result

func _ink(at: Vector2, text: String, size_px: int, color: Color) -> Dictionary:
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)
	return {"text": text, "color": color}

func _draw() -> void:
	drawn = {}
	var target: Dictionary = pick()
	if target.is_empty():
		return
	var player: Node2D = session.get("player") as Node2D
	var action: String = str(target.get("action", ""))
	var keys_width: float = font.get_string_size(KEYS, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_SMALL).x
	var width: float = 24.0 + keys_width + 18.0 + font.get_string_size(action, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_BODY).x + 22.0
	var target_screen: Vector2 = to_screen(target["position"])
	var player_screen: Vector2 = to_screen(player.global_position)
	var placed: Dictionary = place(target_screen, player_screen, width, target.get("range_kind") == "unlimited")
	var rect: Rect2 = placed["rect"]
	var light: bool = tone() == "light"
	var paper: Color = Color(DuskStyle.PAPER_DAY, 0.94) if light else Color(0.05, 0.04, 0.04, 0.88)
	var ink: Color = DuskStyle.INK if light else DuskStyle.PAPER_DAY
	InkDraw.paper(self, rect, paper, 995, DuskStyle.WOBBLE, 0)
	InkDraw.rough_rect(self, rect, Color(ink, 0.75), 1.4, 996, DuskStyle.WOBBLE)
	# The key glyph sits in a small vermilion-edged box.
	var key_box: Rect2 = Rect2(rect.position + Vector2(10, 8), Vector2(keys_width + 14, HEIGHT - 16))
	draw_rect(key_box, Color(DuskStyle.LIFE, 0.9), false, 1.6)
	var keys: Dictionary = _ink(key_box.position + Vector2(7, 21), KEYS, UiTheme.SIZE_SMALL, ink)
	var said: Dictionary = _ink(Vector2(key_box.end.x + 12, rect.position.y + 30), action, UiTheme.SIZE_BODY, ink)
	# A short ink tick points from the tag toward the object.
	var tip: Vector2 = Vector2(rect.position.x if placed["side"] == "right" else rect.end.x, rect.end.y)
	if placed["side"] != "above":
		InkDraw.rough_line(self, tip, target_screen + Vector2(0, -30), Color(ink if light else DuskStyle.PAPER_DAY, 0.55), 1.4, 997, 0.8)
	drawn = {"id": target["id"], "kind": target["kind"], "action": said, "keys": keys, "rect": rect, "side": placed["side"],
		"tone": "light" if light else "dark", "paper": paper, "target_screen": target_screen, "player_screen": player_screen, "key_item": bool(target.get("key_item", false))}
