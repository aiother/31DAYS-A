extends Node2D
@onready var entity: ColorlessEntity = get_parent() as ColorlessEntity
var _warning: AudioStreamPlayer

func _ready() -> void:
	_warning = AudioStreamPlayer.new()
	_warning.stream = GrayboxAudio.make_warning()
	_warning.volume_db = -20.0
	add_child(_warning)
	entity.attack_started.connect(_on_attack_started)

func _on_attack_started(_ranged: bool) -> void:
	_warning.play()

func _draw() -> void:
	if entity.state == ColorlessEntity.State.DEAD:
		for i: int in range(4):
			draw_rect(Rect2(-30 + i * 17, -8 - (i % 2) * 6, 12, 8), Color(0.42, 0.46, 0.48))
		return
	var color: Color = Color(0.64, 0.69, 0.7).lerp(Color.WHITE, entity._flash)
	if entity.state == ColorlessEntity.State.WINDUP:
		color = Color(1.0, 0.58, 0.35) if int(Time.get_ticks_msec() / 90) % 2 == 0 else Color.WHITE
	draw_rect(Rect2(-24, -80, 48, 80), color)
	draw_circle(Vector2(entity.facing * 12, -60), 4, Color(0.16, 0.2, 0.23))
	if entity.state == ColorlessEntity.State.WINDUP:
		draw_line(Vector2(0, -40), Vector2(0, -40) + entity._attack_direction * 95, Color(1, 0.65, 0.4), 3)
	if entity.state == ColorlessEntity.State.ACTIVE and not entity._ranged:
		draw_rect(Rect2(Vector2(entity.facing * 48 - 36, -68), Vector2(72, 56)), Color(1, 0.5, 0.35, 0.5))
