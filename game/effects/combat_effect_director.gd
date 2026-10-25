class_name CombatEffectDirector
extends Node
## FX-001: watches the player and the enemies and turns what really happened
## into effects, the hit-stop and the screen shake. Presentation only: it
## reads states and signals and never changes damage, costs or AI; the
## hit-stop only holds the struck actors' own physics step (see HitStop).
@export var config: CombatEffectConfig = preload("res://effects/default_combat_effects.tres")
var effects: CombatEffects
var player: PlayerController
## Hit-stops started on the player (one per landed swing, however many it hit).
var stops: int = 0
## The last screen shake asked for: {"power", "frame"}; empty if none yet.
var last_shake: Dictionary = {}
var shake_left: float = 0.0
var shake_power: float = 0.0
var _camera: Camera2D
var _camera_rest: Vector2 = Vector2.ZERO
var _struck: Array[Dictionary] = []
var _dodge_serial: int = 0
var _healing: bool = false
var _heal_health: int = 0
var _bounce_attack: int = -1
## The swing (PlayerCombat.attack_id) that has already stopped the player.
var _stopped_attack: int = -1

func _ready() -> void:
	player = get_parent() as PlayerController
	effects = CombatEffects.new()
	effects.name = "CombatEffects"
	add_child(effects)
	player.ready.connect(_bind_player, CONNECT_ONE_SHOT)
	get_tree().node_added.connect(_added)

func _bind_player() -> void:
	player.combat.attack_started.connect(_on_attack_started)
	player.combat.hit_confirmed.connect(_on_hit_confirmed)
	player.life.damaged.connect(_on_damaged)
	player.life.respawned.connect(func() -> void: effects.spawn("revive", _chest(player)))
	player.possibility.gained.connect(func(_amount: int, at: Vector2) -> void: effects.spawn("gain", at))
	_dodge_serial = player.possibility.dodge_serial
	# Enemies already in the scene, then every one added later.
	for node: Node in _actors_under(get_tree().root):
		_bind_actor(node)

func _added(node: Node) -> void:
	if _is_enemy(node):
		node.ready.connect(_bind_actor.bind(node), CONNECT_ONE_SHOT)

static func _is_enemy(node: Node) -> bool:
	return node is ColorlessEntity or node is OverlookBoss or node is ParasiteBoss

func _actors_under(root_node: Node) -> Array[Node]:
	var found: Array[Node] = []
	for child: Node in root_node.get_children():
		if _is_enemy(child):
			found.append(child)
		found.append_array(_actors_under(child))
	return found

func _bind_actor(actor: Node) -> void:
	if not is_instance_valid(actor) or actor.has_meta(&"fx_bound"):
		return
	actor.set_meta(&"fx_bound", true)
	var hurtbox: CombatHurtbox = actor.get_node_or_null("GameplayRoot/Hurtbox") as CombatHurtbox
	if hurtbox != null:
		hurtbox.hit_received.connect(func(damage: int, _impulse: Vector2, _source: Node2D, _id: int) -> void:
			if damage > 0 and is_instance_valid(actor):
				effects.spawn("enemy_hurt", _chest(actor)))
	# Ordinary enemies report a reward; the two Bosses report nothing.
	if actor is ColorlessEntity:
		(actor as ColorlessEntity).defeated.connect(func(_reward: int) -> void: _defeated(actor))
	else:
		actor.connect("defeated", func() -> void: _defeated(actor))

func _defeated(actor: Node) -> void:
	if is_instance_valid(actor):
		effects.spawn("enemy_death", _chest(actor))

static func _chest(body: Node2D) -> Vector2:
	return body.global_position + CombatEffects.CHEST

# --- player events -----------------------------------------------------------

func _on_attack_started(direction: Vector2, _combo: int) -> void:
	effects.spawn("swing", _chest(player), direction, player)

func _on_hit_confirmed(target: CombatHurtbox, _damage: int, _impulse: Vector2) -> void:
	var owner_node: Node = target.get_parent()
	if owner_node is ColorlessProjectile:
		var projectile: ColorlessProjectile = owner_node as ColorlessProjectile
		effects.spawn("reflect", projectile.global_position, projectile.velocity)
		return
	effects.spawn("hit", target.global_position, player.combat.direction)
	if player.combat.direction == Vector2.DOWN and _bounce_attack != player.combat.attack_id:
		_bounce_attack = player.combat.attack_id
		effects.spawn("bounce", _chest(player))
	var actor: Node = owner_node.get_parent() if owner_node != null else null
	if _is_enemy(actor):
		_stop(actor)
	_kick(config.hit_shake)

## The blade bites (user, 2026-10-23): the player and every target this swing
## met stop together; the swing trail stays where it met them, then sweeps on.
## However many targets one swing meets, at once or one after another, the
## player and the trail stop once (review R1); each target still gets its own.
func _stop(actor: Node) -> void:
	var seconds: float = config.hit_stop_seconds
	var swing: int = player.combat.attack_id
	if swing != _stopped_attack and HitStop.start(player, seconds):
		_stopped_attack = swing
		stops += 1
		effects.hold("swing", seconds)
	if HitStop.start(actor, seconds):
		var visual: Node2D = actor.get_node_or_null("VisualRoot") as Node2D
		if visual != null:
			_struck.append({"actor": weakref(actor), "visual": weakref(visual), "rest": visual.position})

func _on_damaged(_amount: int, _impulse: Vector2) -> void:
	effects.spawn("hurt", _chest(player))
	_kick(config.hurt_shake)

func _kick(power: float) -> void:
	if power <= 0.0:
		return
	last_shake = {"power": power, "frame": Engine.get_physics_frames()}
	if shake_left <= 0.0:
		_camera = get_viewport().get_camera_2d()
		_camera_rest = _camera.offset if _camera != null else Vector2.ZERO
	shake_left = config.shake_seconds
	shake_power = power

# --- polled states (no extra gameplay signals needed) ------------------------

func _physics_process(_delta: float) -> void:
	if get_tree().paused or player == null or not player.is_node_ready():
		return
	var actions: PlayerPossibility = player.possibility
	if actions.dodge_serial != _dodge_serial:
		_dodge_serial = actions.dodge_serial
		effects.spawn("spend", _chest(player))
		effects.spawn("poor_dodge" if actions.poor_dodge else "dodge", _chest(player), Vector2(actions.dodge_direction, 0), player)
	var healing: bool = actions.state == PlayerPossibility.State.HEALING
	if healing and not _healing:
		_heal_health = player.life.health
		effects.spawn("spend", _chest(player))
		effects.spawn("heal_loop", _chest(player), Vector2.RIGHT, player)
	elif _healing and not healing:
		effects.stop("heal_loop")
		if player.life.health > _heal_health:
			effects.spawn("heal_done", _chest(player))
	_healing = healing
	var invulnerable: bool = player.life.is_alive() and (actions.invincible_remaining > 0.0 or player.life.protection_remaining > 0.0)
	if invulnerable and not effects.active("invuln"):
		effects.spawn("invuln", _chest(player), Vector2.RIGHT, player)
	elif not invulnerable and effects.active("invuln"):
		effects.stop("invuln")

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	# Struck targets shiver in place while their stop lasts.
	for entry: Dictionary in _struck.duplicate():
		var actor: Node = (entry["actor"] as WeakRef).get_ref() as Node
		var visual: Node2D = (entry["visual"] as WeakRef).get_ref() as Node2D
		if visual == null:
			_struck.erase(entry)
		elif actor == null or HitStop.remaining(actor) <= HitStop.EPSILON:
			visual.position = entry["rest"]
			_struck.erase(entry)
		else:
			var phase: float = effects.clock * 90.0
			visual.position = (entry["rest"] as Vector2) + Vector2(sin(phase), cos(phase * 0.8)) * config.stop_jitter
	if shake_left > 0.0:
		shake_left = maxf(0.0, shake_left - delta)
		if is_instance_valid(_camera):
			var k: float = shake_power * shake_left / config.shake_seconds
			# A turning direction scaled by what is left: never beyond the power,
			# and exactly back at rest on the last frame.
			_camera.offset = _camera_rest + Vector2.from_angle(effects.clock * 83.0) * k

func _exit_tree() -> void:
	for entry: Dictionary in _struck:
		var visual: Node2D = (entry["visual"] as WeakRef).get_ref() as Node2D
		if visual != null:
			visual.position = entry["rest"]
	_struck.clear()
	if is_instance_valid(_camera) and shake_left > 0.0:
		_camera.offset = _camera_rest
