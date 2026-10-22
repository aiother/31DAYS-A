class_name AreaBanner
extends Control
## UI-007 area name (BL-045, T7-B): entering a Room of another area (its
## RoomConfig.scene_id changes, a load included) shows the area name large in
## the middle of the screen, the Room's own part small under it, then fades.
## Moving between Rooms of the same area shows nothing. While paused, in a
## dialogue, during a story lock or under the day banner it waits.
const DURATION: float = 2.6
const FADE_IN: float = 0.3
const FADE_OUT: float = 0.6

var session: Node
var hud: FormalHud
var font: Font
var pending: String = ""
var shown_name: String = ""
var age: float = -1.0
var _last_room: Node
var _last_scene: String = ""
## What the last frame put on screen; read by tests.
var drawn: Dictionary = {}

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = UiTheme.font()

func setup(owner_session: Node, formal_hud: FormalHud) -> void:
	session = owner_session
	hud = formal_hud

func _active_session() -> bool:
	return session != null and (not session.has_method("has_session") or bool(session.call("has_session")))

## Reasons the name waits rather than shows.
func blocked() -> bool:
	if get_tree().paused:
		return true
	if bool(session.get("intro_active")):
		return true
	var dialogue: Variant = session.get("dialogue_ui")
	if dialogue is Node and (bool(dialogue.get("active")) or bool(dialogue.get("confirming"))):
		return true
	var player: Variant = session.get("player")
	if player is PlayerController and not (player as PlayerController).life.can_control():
		return true
	return hud != null and hud.drawn.has("banner")

func showing() -> bool:
	return age >= 0.0 and age < DURATION

func _process(delta: float) -> void:
	if not _active_session():
		_last_room = null
		_last_scene = ""
		pending = ""
		age = -1.0
		queue_redraw()
		return
	var room: Variant = session.get("room")
	if room is WorldRoom and room != _last_room:
		_last_room = room
		var config: RoomConfig = (room as WorldRoom).config
		if config.scene_id != _last_scene:
			_last_scene = config.scene_id
			pending = config.display_name
	if showing() and blocked() and not get_tree().paused:
		# A dialogue or story scene took over: the name gives way at once.
		age = -1.0
	# A newer area replaces a name still on screen.
	if not pending.is_empty() and not blocked():
		shown_name = pending
		pending = ""
		age = 0.0
	if showing() and not get_tree().paused:
		age += delta
	queue_redraw()

func alpha() -> float:
	if not showing():
		return 0.0
	return clampf(minf(age / FADE_IN, (DURATION - age) / FADE_OUT), 0.0, 1.0)

func _ink(at: Vector2, text: String, size_px: int, color: Color) -> Dictionary:
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, size_px, color)
	return {"text": text, "color": color}

func _draw() -> void:
	drawn = {}
	if not showing():
		return
	var a: float = alpha()
	var parts: PackedStringArray = shown_name.split(" · ", true, 1)
	var area: String = parts[0]
	var place: String = parts[1] if parts.size() > 1 else ""
	var middle: float = size.y * 0.5
	var width: float = font.get_string_size(area, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x
	var box: Rect2 = Rect2(Vector2((size.x - maxf(width, 360.0)) * 0.5 - 40, middle - 92), Vector2(maxf(width, 360.0) + 80, 150 if place.is_empty() else 186))
	# A soft dark band so the name reads over any scene.
	draw_rect(box, Color(0.04, 0.03, 0.03, 0.45 * a))
	_ink(Vector2(3, middle + 3), area, 64, Color(0, 0, 0, 0.5 * a))
	var record: Dictionary = {"area": _ink(Vector2(0, middle), area, 64, Color(DuskStyle.PAPER_DAY, a)), "alpha": a, "rect": box}
	InkDraw.rough_line(self, Vector2(size.x * 0.5 - width * 0.4, middle + 22), Vector2(size.x * 0.5 + width * 0.4, middle + 22), Color(DuskStyle.LIFE, 0.85 * a), 2.6, 990, 1.0)
	if not place.is_empty():
		record["place"] = _ink(Vector2(0, middle + 66), place, UiTheme.SIZE_BODY, Color(DuskStyle.PAPER_DAY, 0.85 * a))
	drawn = record
