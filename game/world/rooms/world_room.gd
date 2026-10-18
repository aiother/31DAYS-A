class_name WorldRoom
extends Node2D
signal checkpoint_requested(id: String)
signal exit_requested(target: String)
signal exit_left
signal encounter_requested
@export var config: RoomConfig
@export var environment: RoomRockfallConfig
var environment_hazard: RoomRockfall

func _ready() -> void:
	assert(config != null)
	var ground: TileMapLayer = $Ground
	var columns: int = ceili(config.bounds.size.x / 64.0)
	for x: int in range(columns):
		var row: int = config.floor_row + (config.floor_offsets[x] if x < config.floor_offsets.size() else 0)
		for y: int in range(row, maxi(row + config.ground_rows, config.floor_row + config.ground_rows)):
			ground.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
	$Exit.body_entered.connect(_on_exit_entered)
	$Exit.body_exited.connect(_on_exit_left)
	if has_node("Return"):
		$Return.body_entered.connect(_on_return_entered)
		$Return.body_exited.connect(_on_exit_left)
	if has_node("Encounter"):
		$Encounter.body_entered.connect(_on_encounter_entered)
	if environment!=null:
		environment_hazard = RoomRockfall.new()
		environment_hazard.name = "EnvironmentRockfall"
		environment_hazard.config = environment
		add_child(environment_hazard)
	queue_redraw()

func activate_checkpoint(id: String) -> void:
	checkpoint_requested.emit(id)

func _on_exit_entered(body: Node2D) -> void:
	if body is PlayerController and _currently_overlaps($Exit, body):
		exit_requested.emit(config.next_room_id)

func _currently_overlaps(area: Area2D, body: Node2D) -> bool:
	# Signals queued before a cross-Room teleport may describe the old position.
	var shape: CollisionShape2D = area.get_node("CollisionShape2D") as CollisionShape2D
	var rectangle: RectangleShape2D = shape.shape as RectangleShape2D
	var bounds: Rect2 = Rect2(-rectangle.size * 0.5, rectangle.size)
	return bounds.intersects(Rect2(shape.to_local(body.global_position) + Vector2(-22, -88), Vector2(44, 88)))

func _on_exit_left(body: Node2D) -> void:
	if body is PlayerController:
		exit_left.emit()

func _on_return_entered(body: Node2D) -> void:
	if body is PlayerController and _currently_overlaps($Return, body):
		exit_requested.emit(config.previous_room_id)

func _on_encounter_entered(body: Node2D) -> void:
	if body is PlayerController and _currently_overlaps($Encounter, body):
		encounter_requested.emit()

func _draw() -> void:
	# Flat traversable floor, tall empty space: no platform or combat challenge.
	draw_rect(config.bounds, Color(0.06, 0.08, 0.10))
	if config.room_id == "HD_10002_3":
		for x: int in [80, 560, 1040, 1520, 2000, 2448]:
			draw_rect(Rect2(x, 120, 64, config.bounds.size.y - 120), Color(0.12, 0.145, 0.16))
		draw_line(Vector2(896, 1590), Vector2(1216, 1590), Color(0.18, 0.23, 0.25), 3)
		draw_line(Vector2(2416, 520), Vector2(2416, 200), Color(0.4, 0.45, 0.46), 4)
		return
	if config.room_id == "HD_10002_2":
		for x: int in [48, 520, 1000, 1512, 1840]:
			draw_rect(Rect2(x, 80, 64, config.bounds.size.y - 80), Color(0.12, 0.145, 0.16))
		for y: int in [240, 720, 1200]:
			draw_line(Vector2(80, y), Vector2(1840, y - 24), Color(0.19, 0.22, 0.23), 6)
		draw_line(Vector2(1760, 640), Vector2(1760, 320), Color(0.4, 0.45, 0.46), 4)
		return
	if config.room_id == "HD_10002_1":
		for x: int in [80, 440, 1280, 1680]:
			draw_rect(Rect2(x, 300, 80, 596), Color(0.12, 0.145, 0.16))
			draw_line(Vector2(x, 330), Vector2(x + 80, 300), Color(0.27, 0.30, 0.31), 3)
		draw_line(Vector2(1770, 885), Vector2(1920, 885), Color(0.4, 0.42, 0.4), 6)
		return
	for x: int in [32, 112, 1720, 1840]:
		draw_line(Vector2(x, 0), Vector2(x + 16, 820), Color(0.14, 0.17, 0.19), 8)
	var mouth: PackedVector2Array = PackedVector2Array([Vector2(1740, 520), Vector2(1830, 560), Vector2(1780, 700), Vector2(1850, 896), Vector2(1920, 896), Vector2(1920, 400)])
	draw_colored_polygon(mouth, Color(0.025, 0.035, 0.04))
	draw_line(Vector2(1780, 700), Vector2(1850, 896), Color(0.35, 0.40, 0.42), 4)
