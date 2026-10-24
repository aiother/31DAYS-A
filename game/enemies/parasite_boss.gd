class_name ParasiteBoss
extends Node2D
signal defeated
enum State { WAITING, MOVE, WINDUP, BURST, RECOVERY, DEAD }
@export var config: ParasiteConfig
var target: PlayerController
var health: int = 80
var state: State = State.WAITING
var remaining: float = 0.0
var shots_left: int = 0
var shots_fired: int = 0
var flash: float = 0.0
var _side: float = 1.0
var _move_goal: float = 0.0
@onready var hurtbox: CombatHurtbox = $GameplayRoot/Hurtbox
const PROJECTILE: PackedScene = preload("res://enemies/parasite_projectile.tscn")

func _ready() -> void:
	health = config.max_health
	hurtbox.accepts_hits = false
	hurtbox.hit_received.connect(_on_hit)

func start_combat() -> void:
	if state != State.WAITING:
		return
	hurtbox.accepts_hits = true
	_move()

func _move() -> void:
	state = State.MOVE
	remaining = config.move_duration
	_side = -_side
	_move_goal = clampf(target.position.x+_side*280.0,368.0,1648.0)

func _physics_process(delta: float) -> void:
	flash = maxf(0,flash-delta)
	$VisualRoot.modulate = Color(1.8,1.8,1.8) if flash>0 else Color.WHITE
	queue_redraw()
	if state == State.WAITING or state == State.DEAD or not is_instance_valid(target) or not target.life.is_alive():
		return
	remaining = maxf(0,remaining-delta)
	match state:
		State.MOVE:
			position.x = move_toward(position.x,_move_goal,config.move_speed*delta)
			if remaining==0:
				state = State.WINDUP
				GameAudio.emit_from(self, &"enemy.windup", global_position)
				remaining = config.windup
		State.WINDUP:
			if remaining==0:
				state = State.BURST
				shots_left = config.burst_count
				_fire()
		State.BURST:
			if remaining==0:
				if shots_left>0:
					_fire()
				else:
					state = State.RECOVERY
					remaining = config.recovery
		State.RECOVERY:
			if remaining==0:
				_move()

func _fire() -> void:
	var projectile: ParasiteProjectile = PROJECTILE.instantiate() as ParasiteProjectile
	var origin: Vector2 = position+Vector2(-80 if target.position.x<position.x else 80,-64)
	projectile.position = origin
	projectile.velocity = (target.position+Vector2(0,-44)-origin).normalized()*config.projectile_speed
	projectile.source = self
	projectile.leech_boss = self
	get_parent().get_node("Enemies").add_child(projectile)
	shots_left -= 1
	shots_fired += 1
	remaining = config.burst_interval

func leech() -> void:
	if state == State.DEAD or state == State.WAITING:
		return
	health = mini(config.max_health,health+config.leech_heal)
	flash = 0.12

func _on_hit(damage: int, _impulse: Vector2, _source: Node2D, _id: int) -> void:
	if state == State.WAITING or state == State.DEAD or damage<=0:
		return
	health = maxi(0,health-damage)
	flash = 0.12
	if health==0:
		mark_defeated()
		defeated.emit()

func mark_defeated() -> void:
	state = State.DEAD
	health = 0
	hurtbox.accepts_hits = false
	$VisualRoot.hide()

func _draw() -> void:
	if state==State.WINDUP:
		draw_circle(Vector2(0,-72),92,Color(0.8,0.2,0.25,0.25))
