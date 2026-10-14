extends Node2D
## Development fixture only. No production Room ID or persistent state.
@onready var ground: TileMapLayer = $Ground
@onready var player: PlayerController = $Player
@onready var status: Label = $Instructions/Status

func _ready() -> void:
	for x: int in range(30):
		for y: int in range(14, 17):
			ground.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
	queue_redraw()

func _process(_delta: float) -> void:
	var state: String = "落地硬直" if player.landing_lock_remaining > 0.0 else ("地面" if player.is_on_floor() else "空中")
	status.text = "%s   水平速度 %.0f   纵向速度 %.0f" % [state, player.velocity.x, player.velocity.y]
	if player.combat.is_attacking():
		var phases: PackedStringArray = PackedStringArray(["待机", "前摇", "判定", "后摇"])
		status.text += "   攻击%d · %s" % [player.combat.combo_step, phases[player.combat.phase]]
	if Input.is_action_just_pressed("debug_reset"):
		get_tree().reload_current_scene()
	if Input.is_action_just_pressed("toggle_fullscreen"):
		var fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)

func _draw() -> void:
	for x: int in range(0, 1921, 64):
		draw_line(Vector2(x, 200), Vector2(x, 896), Color(0.14, 0.19, 0.23), 1.0)
	for y: int in range(256, 897, 64):
		draw_line(Vector2(0, y), Vector2(1920, y), Color(0.14, 0.19, 0.23), 1.0)
