class_name RoomPickup
extends Node2D
@export var config: PickupConfig
var prompt: Label

func _ready() -> void:
	assert(config != null)
	add_to_group("room_pickups")
	prompt = Label.new()
	prompt.position = Vector2(-88, -96)
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.text = "E / RB · 拾取" + config.display_name
	add_child(prompt)
	prompt.hide()
	queue_redraw()

func can_collect(player: PlayerController) -> bool:
	return player.life.can_control() and not player.possibility.busy() and not player.combat.is_attacking() and in_range(player)

func refresh(player: PlayerController, collected: bool) -> void:
	visible = not collected
	prompt.visible = not collected and can_collect(player)

## UI-007 (BL-049): key items pulse so they read on the map; same rule as
## SYS-009's key_item. Collected items are hidden by refresh().
func key_item() -> bool:
	return config.persistence_key.begins_with("keyitem:")

var _pulse_time: float = 0.0

func _process(delta: float) -> void:
	if visible and key_item():
		_pulse_time += delta
		queue_redraw()

## 0..1 strength of the pulse this frame; 0 for ordinary pickups.
func highlight() -> float:
	if not key_item():
		return 0.0
	return 0.55 + 0.45 * sin(_pulse_time * 4.0)

## What the last _draw() put on screen for the highlight; read by tests.
var drawn: Dictionary = {}

func _glow(radius: float, color: Color, strength: float) -> Dictionary:
	InkDraw.glow(self, Vector2.ZERO, radius, color, strength)
	return {"radius": radius, "color": color, "strength": strength}

func _ring(radius: float, color: Color) -> Dictionary:
	draw_arc(Vector2.ZERO, radius, 0, TAU, 40, color, 3)
	return {"radius": radius, "color": color}

func _draw() -> void:
	drawn = {}
	var pulse: float = highlight()
	if pulse > 0.0:
		drawn["glow"] = _glow(70, DuskStyle.GROWTH, 0.9 * pulse)
		drawn["ring"] = _ring(32 + 6 * pulse, Color(DuskStyle.GROWTH, 0.5 + 0.4 * pulse))
	draw_circle(Vector2.ZERO, 18, Color(0.8, 0.9, 0.95))
	draw_circle(Vector2(-5, -6), 5, Color.WHITE)
	draw_arc(Vector2.ZERO, 25, 0, TAU, 32, Color(0.45, 0.75, 0.8), 2)

func in_range(player: PlayerController) -> bool:
	return global_position.distance_to(player.global_position + Vector2(0, -44)) <= config.interaction_radius
