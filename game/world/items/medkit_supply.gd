class_name MedkitSupply
extends Node2D
## A visual collectible only: no navigation anchors or terrain collision.
var persistence_key: String
var prompt: Label

func _ready() -> void:
	prompt = Label.new()
	prompt.position = Vector2(-120, -76)
	prompt.add_theme_font_size_override("font_size", 20)
	add_child(prompt)
	prompt.hide()
	queue_redraw()

func in_range(player: PlayerController) -> bool:
	return global_position.distance_to(player.global_position + Vector2(0, -44)) <= MedkitRules.CONFIG.pickup_radius

func refresh(player: PlayerController, events: Dictionary, count: int) -> void:
	visible = not bool(events.get(persistence_key, false))
	prompt.visible = visible and in_range(player)
	prompt.text = "药包已满 · %d / %d" % [count, MedkitRules.CONFIG.maximum] if count >= MedkitRules.CONFIG.maximum else "靠近自动拾取 · 应急药包"

func _draw() -> void:
	draw_rect(Rect2(-22, -15, 44, 30), Color(0.8, 0.24, 0.22))
	draw_rect(Rect2(-5, -11, 10, 22), Color.WHITE)
	draw_rect(Rect2(-13, -4, 26, 8), Color.WHITE)
