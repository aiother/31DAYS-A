extends CombatHurtbox
## Developer fixture, not an enemy: no AI, HP, death, drops or persistent state.
var hit_count: int = 0
var damage_total: int = 0
var last_impulse: Vector2 = Vector2.ZERO
var _flash: float = 0.0
@onready var counter: Label = $Counter

func _ready() -> void:
	hit_received.connect(_on_hit)

func _on_hit(damage: int, impulse: Vector2, _source: Node2D, _attack_id: int) -> void:
	hit_count += 1
	damage_total += damage
	last_impulse = impulse
	_flash = 1.0
	counter.text = "命中 %d / 伤害 %d" % [hit_count, damage_total]

func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 4.0)
	queue_redraw()

func _draw() -> void:
	var color: Color = Color(0.92, 0.67, 0.33).lerp(Color.WHITE, _flash)
	draw_rect(Rect2(-20, -40, 40, 80), color)
	draw_line(Vector2(-16, -32), Vector2(16, 32), Color(0.18, 0.22, 0.25), 3)
	draw_line(Vector2(16, -32), Vector2(-16, 32), Color(0.18, 0.22, 0.25), 3)
	if _flash > 0.0 and last_impulse.length() > 0.0:
		draw_line(Vector2.ZERO, last_impulse.normalized() * 65.0, Color.WHITE, 4)
