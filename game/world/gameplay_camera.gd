class_name GameplayCamera
extends Camera2D
## Gameplay framing (ART-003 player_scale_v1, user 2026-10-30): the world is shown
## at normal_zoom so the 112 px player reads at about 210 px of a 1080p screen (19.5% of
## its height), standing with its feet at ground_ratio of the screen height.
## Only the view changes: world units, collision and Room geometry stay as they are.
## `offset` is left to cinematics and screen shake.
## Provisional defaults; user 2026-10-31 requested continued tuning.
@export_range(0.5, 4.0, 0.025) var normal_zoom: float = 1.875
@export_range(0.0, 1.0, 0.01) var ground_ratio: float = 0.88
@export_range(0.5, 1.875, 0.025) var battle_zoom: float = 1.5
@export_range(0.1, 2.0, 0.05) var transition_seconds: float = 0.25

func _ready() -> void:
	process_priority = 50 # Session/cinematic changes publish before this view update.
	zoom = Vector2(normal_zoom, normal_zoom)
	position = Vector2(0.0, -feet_lift(float(ProjectSettings.get_setting("display/window/size/viewport_height"))))

func _process(delta: float) -> void:
	var host: Node = get_parent().get_parent()
	var state: Dictionary = host.call("gameplay_camera_state") if host.has_method("gameplay_camera_state") else {}
	# Cinematic presentation retains ownership of framing, including its offset.
	if bool(state.get("cinematic", false)): return
	var size: Vector2 = get_viewport_rect().size
	var desired_zoom: float = clampf(battle_zoom, 0.5, normal_zoom) if bool(state.get("battle", false)) else normal_zoom
	# Never request a view larger than the Room, even with a very low custom zoom.
	var room_size: Vector2 = Vector2(limit_right - limit_left, limit_bottom - limit_top)
	var fitting_zoom: float = maxf(size.x / maxf(room_size.x, 1.0), size.y / maxf(room_size.y, 1.0))
	desired_zoom = maxf(desired_zoom, fitting_zoom)
	var weight: float = 1.0 - exp(-minf(delta, 1.0 / 30.0) / maxf(transition_seconds, 0.01))
	var next_zoom: float = maxf(lerpf(zoom.x, desired_zoom, weight), fitting_zoom)
	if absf(next_zoom - desired_zoom) < 0.0001: next_zoom = desired_zoom
	zoom = Vector2(next_zoom, next_zoom)
	var desired_position: Vector2 = Vector2(0.0, -feet_lift(size.y, next_zoom))
	if bool(state.get("battle", false)) and state.has("focus"):
		var anchor: Vector2 = (get_parent() as Node2D).global_position
		# Keep the player anchor, bias horizontally toward the opponent. The
		# vertical framing still leaves space above for airborne attacks.
		# The 35% horizontal bias is provisional too.
		desired_position.x = (Vector2(state["focus"]).x - anchor.x) * 0.35
	position = position.lerp(desired_position, weight)
	if position.distance_to(desired_position) < 0.001: position = desired_position

## World distance from the camera centre down to the player's feet.
func feet_lift(viewport_height: float, framing_zoom: float = -1.0) -> float:
	return (ground_ratio - 0.5) * world_length(viewport_height, framing_zoom)

## A screen-space distance expressed in world units at this framing.
## Omit framing_zoom for normal framing; pass the actual zoom for battle/cinematics.
func world_length(screen_pixels: float, framing_zoom: float = -1.0) -> float:
	return screen_pixels / (normal_zoom if framing_zoom < 0.0 else framing_zoom)
