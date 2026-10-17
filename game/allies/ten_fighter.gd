class_name TenFighter
extends SurvivorFighter
var dash_remaining: float = 0
var dash_cooldown: float = 0
var retarget_remaining: float = 0

func _ready() -> void:
	super._ready()
	hurtbox.accepts_hits = false

func _can_step(direction: float, distance: float) -> bool:
	if test_move(global_transform,Vector2(direction*distance,0)):
		return false
	if not is_on_floor():
		return false
	var start: Vector2 = global_position+Vector2(direction*(distance+24),-4)
	var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start,start+Vector2(0,36),1)
	return not get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func _physics_process(delta: float) -> void:
	var tuning: TenConfig = config as TenConfig
	remaining = maxf(0,remaining-delta)
	dash_remaining = maxf(0,dash_remaining-delta)
	dash_cooldown = maxf(0,dash_cooldown-delta)
	retarget_remaining = maxf(0,retarget_remaining-delta)
	velocity.y = minf(1500,velocity.y+1900*delta)
	velocity.x = 0
	if not is_instance_valid(target) or target.health<=0:
		state = State.SEEK
		choose_target()
	elif state!=State.WINDUP and retarget_remaining==0:
		choose_target()
		retarget_remaining = tuning.retarget_interval
	if is_instance_valid(target):
		var offset: Vector2 = target.global_position-global_position
		facing = signf(offset.x) if absf(offset.x)>1 else facing
		if state==State.RECOVERY and remaining==0:
			state = State.SEEK
		if state==State.SEEK and absf(offset.x)<=config.reach and absf(offset.y)<70:
			state = State.WINDUP
			remaining = config.windup
			dash_remaining = 0
		elif state==State.WINDUP:
			if remaining==0:
				_strike()
				state = State.RECOVERY
				remaining = config.recovery
		elif absf(offset.x)>config.reach:
			if state==State.SEEK and absf(offset.x)>tuning.dash_distance and dash_cooldown==0 and _can_step(facing,tuning.dash_speed*tuning.dash_duration):
				dash_remaining = tuning.dash_duration
				dash_cooldown = tuning.dash_cooldown
			var speed: float = tuning.dash_speed if dash_remaining>0 else config.speed
			if state==State.RECOVERY:
				speed *= tuning.recovery_chase_ratio
			if _can_step(facing,speed*delta):
				velocity.x = facing*speed
	move_and_slide()
	_refresh()

func _on_hit(_damage: int, _impulse: Vector2, _source: Node2D, _id: int) -> void:
	pass

func _refresh() -> void:
	$HealthLabel.text = "10 · " + ["接敌","攻击前摇","后摇","待机"][state]
	if dash_remaining>0:
		$HealthLabel.text = "10 · 突进"
