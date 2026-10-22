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

func _draw() -> void:
	draw_circle(Vector2.ZERO, 18, Color(0.8, 0.9, 0.95))
	draw_circle(Vector2(-5, -6), 5, Color.WHITE)
	draw_arc(Vector2.ZERO, 25, 0, TAU, 32, Color(0.45, 0.75, 0.8), 2)

func in_range(player: PlayerController) -> bool:
	return global_position.distance_to(player.global_position + Vector2(0, -44)) <= config.interaction_radius
