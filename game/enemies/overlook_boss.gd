class_name OverlookBoss
extends Node2D
signal defeated
signal platforms_requested
enum State { WAITING, WINDUP, DIVE, RECOVERY, HOVER, DEAD }
@export var config: OverlookConfig
var target: PlayerController
var health: int = 60
var state: State = State.WAITING
var remaining: float = 0.0
var impact_x: float = 0.0
var flash: float = 0.0
var _attack_id: int = 0
var _windup_start: Vector2
@onready var hurtbox: CombatHurtbox = $GameplayRoot/Hurtbox

func _ready() -> void:
	health = config.max_health
	hurtbox.hit_received.connect(_on_hit)
	hurtbox.accepts_hits = false

func start_combat() -> void:
	if state == State.DEAD:
		return
	hurtbox.accepts_hits = true
	position.y = config.floor_y
	_windup()

func _windup() -> void:
	state = State.WINDUP
	remaining = config.windup_duration
	impact_x = clampf(target.position.x, 160.0, 1760.0)
	_windup_start = position

func _physics_process(delta: float) -> void:
	flash = maxf(0.0, flash - delta)
	$VisualRoot.modulate = Color(1.8, 1.8, 1.8) if flash > 0 else Color.WHITE
	queue_redraw()
	if state == State.WAITING or state == State.DEAD or not is_instance_valid(target) or not target.life.is_alive():
		return
	remaining = maxf(0.0, remaining - delta)
	match state:
		State.WINDUP:
			position = _windup_start.lerp(Vector2(impact_x, config.floor_y - 360), 1.0 - remaining / maxf(0.001, config.windup_duration))
			if remaining == 0.0:
				# The marked landing point locks at windup start; no homing after warning.
				position.x = impact_x
				state = State.DIVE
		State.DIVE:
			position.y = move_toward(position.y, config.floor_y, config.dive_speed * delta)
			if position.y == config.floor_y:
				_impact()
				state = State.RECOVERY
				remaining = config.recovery_duration
		State.RECOVERY:
			if remaining == 0.0:
				state = State.HOVER
				remaining = config.hover_duration
				platforms_requested.emit()
		State.HOVER:
			position = position.move_toward(config.hover_position, config.rise_speed * delta)
			if remaining == 0.0:
				_windup()

func _impact() -> void:
	_attack_id += 1
	var hit: Rect2 = Rect2(Vector2(position.x - config.impact_size.x * 0.5, config.floor_y - config.impact_size.y), config.impact_size)
	var body: Rect2 = Rect2(target.position + Vector2(-22, -88), Vector2(44, 88))
	if hit.intersects(body):
		(target.get_node("GameplayRoot/Hurtbox") as CombatHurtbox).receive_attack(config.damage, Vector2(100 if target.position.x >= position.x else -100, 0), self, _attack_id)

func _on_hit(damage: int, _impulse: Vector2, _source: Node2D, _id: int) -> void:
	if state == State.WAITING or state == State.DEAD or damage <= 0:
		return
	health = maxi(0, health - damage)
	flash = 0.12
	if health == 0:
		state = State.DEAD
		hurtbox.accepts_hits = false
		$VisualRoot.hide()
		defeated.emit()

func mark_defeated() -> void:
	state = State.DEAD
	health = 0
	hurtbox.accepts_hits = false
	$VisualRoot.hide()

func _draw() -> void:
	if state == State.WINDUP or state == State.DIVE:
		var local_mark: Vector2 = Vector2(impact_x, config.floor_y) - position
		draw_line(local_mark - Vector2(config.impact_size.x * 0.5, 4), local_mark + Vector2(config.impact_size.x * 0.5, -4), Color(1, 0.4, 0.22), 8)
