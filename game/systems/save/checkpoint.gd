class_name GrayboxCheckpoint
extends Area2D
@export var config: CheckpointConfig
var active: bool = false
var label: Label

func _ready() -> void:
	assert(config != null)
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	position = config.spawn_position
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = config.trigger_size
	shape.shape = rectangle
	shape.position.y = -config.trigger_size.y * 0.5
	add_child(shape)
	label = Label.new()
	label.position = Vector2(-64, -156)
	label.add_theme_font_size_override("font_size", 18)
	add_child(label)
	body_entered.connect(_on_entered)
	set_active(false)

func set_active(value: bool) -> void:
	active = value
	if label != null:
		label.text = config.display_name + (" · 已记录" if active else "")
	queue_redraw()

func _on_entered(body: Node2D) -> void:
	if body is PlayerController:
		# Teleports can leave a queued enter signal from the pre-load position.
		# Recheck current body bounds before changing the active checkpoint.
		var trigger: Rect2 = Rect2(Vector2(-config.trigger_size.x * 0.5, -config.trigger_size.y), config.trigger_size)
		var current_body: Rect2 = Rect2(to_local(body.global_position) + Vector2(-22, -88), Vector2(44, 88))
		if not trigger.intersects(current_body):
			return
		get_parent().call("activate_checkpoint", config.checkpoint_id)

func _draw() -> void:
	var color: Color = Color(0.4, 1.0, 0.75) if active else Color(0.6, 0.7, 0.8)
	draw_line(Vector2(0, 0), Vector2(0, -112), color, 4)
	draw_colored_polygon(PackedVector2Array([Vector2(2, -110), Vector2(44, -92), Vector2(2, -74)]), color)
