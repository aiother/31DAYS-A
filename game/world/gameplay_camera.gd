class_name GameplayCamera
extends Camera2D
## Gameplay framing (ART-003 player_scale_v1, user 2026-10-30): the world is shown
## at ZOOM so the 112 px player reads at about 210 px of a 1080p screen (19.5% of
## its height), standing with its feet at GROUND_RATIO of the screen height.
## Only the view changes: world units, collision and Room geometry stay as they are.
## `offset` is left to cinematics and screen shake.
const ZOOM: float = 1.875
const GROUND_RATIO: float = 0.88

func _ready() -> void:
	zoom = Vector2(ZOOM, ZOOM)
	position = Vector2(0.0, -feet_lift(float(ProjectSettings.get_setting("display/window/size/viewport_height"))))

## World distance from the camera centre down to the player's feet.
static func feet_lift(viewport_height: float) -> float:
	return (GROUND_RATIO - 0.5) * viewport_height / ZOOM

## A screen-space distance expressed in world units at this framing.
static func world_length(screen_pixels: float) -> float:
	return screen_pixels / ZOOM
