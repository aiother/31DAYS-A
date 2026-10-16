class_name SurvivorFighter
extends CharacterBody2D
signal fallen
enum State { SEEK, WINDUP, RECOVERY, DEAD }
@export var config: SurvivorConfig
@export var opponents: Node2D
@onready var hurtbox: CombatHurtbox = $GameplayRoot/Hurtbox
var health: int = 10
var target: ColorlessEntity
var state: State = State.SEEK
var remaining: float = 0.0
var facing: float = 1.0
var attacks: int = 0

func _ready() -> void:
	health = config.max_health
	hurtbox.hit_received.connect(_on_hit)
	_refresh()

func choose_target() -> void:
	target = null
	var nearest: float = INF
	if not is_instance_valid(opponents):
		return
	for child: Node in opponents.get_children():
		if child is ColorlessEntity and (child as ColorlessEntity).health>0:
			var enemy: ColorlessEntity = child as ColorlessEntity
			var distance: float = global_position.distance_squared_to(enemy.global_position)
			if distance<nearest:
				nearest = distance
				target = enemy

func _physics_process(delta: float) -> void:
	if health<=0:
		return
	remaining = maxf(0,remaining-delta)
	velocity.y = minf(1500,velocity.y+1900*delta)
	velocity.x = 0
	if not is_instance_valid(target) or target.health<=0:
		state = State.SEEK
		choose_target()
	if is_instance_valid(target):
		var offset: Vector2 = target.global_position-global_position
		if state==State.SEEK:
			facing = signf(offset.x) if absf(offset.x)>1 else facing
			if absf(offset.x)<=config.reach and absf(offset.y)<70:
				state = State.WINDUP
				remaining = config.windup
			else:
				velocity.x = facing*config.speed
		elif state==State.WINDUP and remaining==0:
			_strike()
			state = State.RECOVERY
			remaining = config.recovery
		elif state==State.RECOVERY and remaining==0:
			state = State.SEEK
	move_and_slide()
	_refresh()

func _strike() -> void:
	attacks += 1
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(96,64)
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0,global_position+Vector2(facing*56,-40))
	query.collision_mask = 16
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query):
		var receiver: CombatHurtbox = result["collider"] as CombatHurtbox
		if receiver==null:
			continue
		var actor: Node = receiver.get_parent().get_parent()
		# Only hostile actors: no allied/player damage and no automatic parry.
		if actor is ColorlessEntity and (actor as ColorlessEntity).health>0:
			receiver.receive_attack(config.damage,Vector2(facing*100,0),self,attacks)

func _on_hit(damage: int, _impulse: Vector2, source: Node2D, _id: int) -> void:
	if health<=0 or source is SurvivorFighter or source is PlayerController:
		return
	health = maxi(0,health-damage)
	if health==0:
		state = State.DEAD
		hurtbox.accepts_hits = false
		velocity = Vector2.ZERO
		fallen.emit()
	_refresh()

func _refresh() -> void:
	$HealthLabel.text = "幸存者 %d / %d · %s" % [health,config.max_health,["接敌","攻击前摇","后摇","倒下"][state]]
	$VisualRoot.modulate = Color(0.3,0.85,0.65) if health>0 else Color(0.22,0.27,0.25)
