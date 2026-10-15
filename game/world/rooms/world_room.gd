class_name WorldRoom
extends Node2D
signal checkpoint_requested(id: String)
signal exit_requested(target: String)
signal exit_left
@export var config: RoomConfig

func _ready() -> void:
	assert(config != null)
	var ground: TileMapLayer = $Ground
	var columns: int = ceili(config.bounds.size.x / 64.0)
	for x: int in range(columns):
		for y: int in range(config.floor_row, config.floor_row + config.ground_rows):
			ground.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
	$Exit.body_entered.connect(_on_exit_entered)
	$Exit.body_exited.connect(_on_exit_left)
	queue_redraw()

func activate_checkpoint(id: String) -> void:
	checkpoint_requested.emit(id)

func _on_exit_entered(body: Node2D) -> void:
	if body is PlayerController:
		exit_requested.emit(config.next_room_id)

func _on_exit_left(body: Node2D) -> void:
	if body is PlayerController:
		exit_left.emit()

func _draw() -> void:
	# Flat traversable floor, tall empty space: no platform or combat challenge.
	draw_rect(config.bounds, Color(0.06, 0.08, 0.10))
	for x: int in [32, 112, 1720, 1840]:
		draw_line(Vector2(x, 0), Vector2(x + 16, 820), Color(0.14, 0.17, 0.19), 8)
	var mouth: PackedVector2Array = PackedVector2Array([Vector2(1740, 520), Vector2(1830, 560), Vector2(1780, 700), Vector2(1850, 896), Vector2(1920, 896), Vector2(1920, 400)])
	draw_colored_polygon(mouth, Color(0.025, 0.035, 0.04))
	draw_line(Vector2(1780, 700), Vector2(1850, 896), Color(0.35, 0.40, 0.42), 4)
