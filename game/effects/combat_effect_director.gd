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
## FX-002: enemies watched for their wind-up, and the cue each one is showing.
var _watched: Array[WeakRef] = []
var _cues: Dictionary = {}
## Bosses are drawn about 2.5 times the player (T6-E); their cues match.
const BOSS_SIZE: float = 2.5
const BOSS_CENTER: Vector2 = Vector2(0, -120)
## T2 §11: a wave's units appear after their arrival effect has ended. The
## effect is played inside the existing warning before the wave (between waves
## and after the 10 rescue), starting this long before the units appear, so it
## is over 0.1 s before they do. Spawn times, AI and waves are unchanged.
const ARRIVAL_LEAD: float = 0.8
## Battlefield Rooms whose next wave is watched, and the ones already announced.
var _fields: Array[WeakRef] = []

func _ready() -> void:
	# After the actors' own physics step, so a Boss's wind-up is seen in the
	# same physics frame it starts (its warning sound is sent in that frame).
	process_physics_priority = 200
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
	for node: Node in get_tree().root.find_children("*", "RescueBattlefieldRoom", true, false):
		_fields.append(weakref(node))

func _added(node: Node) -> void:
	if node is RescueBattlefieldRoom:
		_fields.append(weakref(node))
		return
	var enemy: bool = _is_enemy(node)
	if not enemy and not node is SurvivorFighter:
		return
	# A unit that joins a Room which is already running is a reinforcement or
	# a new wave; units placed while the Room itself loads are not.
	var room: Node = node.get_parent()
	while room != null and not room is WorldRoom:
		room = room.get_parent()
	if room != null and room.is_node_ready() and not room.has_meta(&"fx_wave_announced"):
		node.set_meta(&"fx_arrival", true)
	if enemy:
		node.ready.connect(_bind_actor.bind(node), CONNECT_ONE_SHOT)
	else:
		node.ready.connect(_arrive.bind(node, "arrival_ally"), CONNECT_ONE_SHOT)

func _arrive(actor: Node, kind: String) -> void:
	if is_instance_valid(actor) and actor.has_meta(&"fx_arrival"):
		actor.remove_meta(&"fx_arrival")
		effects.spawn(kind, _chest(actor))

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
		# The cue starts on the very signal the warning sound uses (same frame).
		(actor as ColorlessEntity).attack_started.connect(func(_ranged: bool) -> void: _cue_start(actor))
	else:
		actor.connect("defeated", func() -> void: _defeated(actor))
	_watched.append(weakref(actor))
	_arrive(actor, "arrival_enemy")

func _defeated(actor: Node) -> void:
	if not is_instance_valid(actor):
		return
	_cue_stop(actor)
	if _is_boss(actor):
		var burst: Dictionary = effects.spawn("boss_death", _center(actor), Vector2.RIGHT, null, BOSS_SIZE)
		burst["style"] = _style(actor)
	else:
		effects.spawn("enemy_death", _chest(actor))

static func _is_boss(node: Node) -> bool:
	return node is OverlookBoss or node is ParasiteBoss

static func _center(actor: Node2D) -> Vector2:
	return actor.global_position + (BOSS_CENTER if _is_boss(actor) else CombatEffects.CHEST)

# --- enemy wind-up cues (FX-002, G-07 visual) --------------------------------

static func _winding(actor: Node) -> bool:
	if actor is ColorlessEntity: return (actor as ColorlessEntity).state == ColorlessEntity.State.WINDUP
	if actor is OverlookBoss: return (actor as OverlookBoss).state == OverlookBoss.State.WINDUP
	if actor is ParasiteBoss: return (actor as ParasiteBoss).state == ParasiteBoss.State.WINDUP
	return false

## Strong single-colour attacks, Tian heavy blows and every Boss blow use the
## heavy cue, matching the separate heavy warning sounds of SYS-011.
static func _heavy(actor: Node) -> bool:
	if actor is MonochromeEntity: return (actor as MonochromeEntity).strong_attack
	if actor is TianWarrior: return (actor as TianWarrior).attack_kind == TianWarrior.Attack.HEAVY
	return _is_boss(actor)

func _cue_start(actor: Node) -> void:
	if not is_instance_valid(actor) or _cues.has(actor.get_instance_id()):
		return
	var boss: bool = _is_boss(actor)
	var dir: Vector2 = Vector2.RIGHT if boss else (actor as ColorlessEntity)._attack_direction
	var entry: Dictionary = effects.spawn("windup_heavy" if _heavy(actor) else "windup", _center(actor), dir, actor, BOSS_SIZE if boss else 1.0)
	entry["heavy"] = _heavy(actor)
	entry["frame"] = Engine.get_physics_frames()
	# What the drawing needs to be this enemy's own (G4 2026-10-25).
	entry["style"] = _style(actor)
	entry["attack"] = _attack(actor)
	entry["expect"] = _time_left(actor)
	entry["facing"] = float(actor.get("facing")) if actor is ColorlessEntity else 1.0
	entry["count"] = int(actor.get("combo_total")) if actor is TianWarrior else ((actor as ParasiteBoss).config.burst_count if actor is ParasiteBoss else 1)
	_aim(actor, entry)
	_cues[actor.get_instance_id()] = entry

static func _style(actor: Node) -> String:
	if actor is OverlookBoss: return "overlook"
	if actor is ParasiteBoss: return "parasite"
	if actor is TianWarrior: return "tian"
	if actor is MonochromeEntity: return "mono"
	return "colorless"

static func _attack(actor: Node) -> String:
	if actor is TianWarrior:
		return ["combo", "heavy", "ranged"][(actor as TianWarrior).attack_kind] if (actor as TianWarrior).attack_kind <= TianWarrior.Attack.RANGED else "combo"
	if actor is ColorlessEntity:
		return "ranged" if (actor as ColorlessEntity)._ranged else "melee"
	return "dive" if actor is OverlookBoss else "burst"

## Seconds the wind-up still has as it starts (the cue's mark fills over it).
static func _time_left(actor: Node) -> float:
	if actor is ColorlessEntity: return (actor as ColorlessEntity)._remaining
	return float(actor.get("remaining"))

## Where the blow is going, kept current (a Boss moves while it winds up).
func _aim(actor: Node, entry: Dictionary) -> void:
	var parent: Node2D = actor.get_parent() as Node2D
	if actor is OverlookBoss:
		var boss: OverlookBoss = actor as OverlookBoss
		var spot: Vector2 = Vector2(boss.impact_x, boss.config.floor_y)
		entry["aim_to"] = parent.to_global(spot) if parent != null else spot
		entry["dir"] = ((entry["aim_to"] as Vector2) - _center(boss)).normalized()
	elif actor is ParasiteBoss:
		var leech: ParasiteBoss = actor as ParasiteBoss
		if is_instance_valid(leech.target):
			# The muzzle and aim of ParasiteBoss._fire().
			var origin: Vector2 = leech.position + Vector2(-80 if leech.target.position.x < leech.position.x else 80, -64)
			entry["aim_from"] = parent.to_global(origin) if parent != null else origin
			entry["aim_to"] = leech.target.global_position + Vector2(0, -44)
			entry["dir"] = ((entry["aim_to"] as Vector2) - (entry["aim_from"] as Vector2)).normalized()
	elif actor is ColorlessEntity:
		var enemy: ColorlessEntity = actor as ColorlessEntity
		entry["dir"] = enemy._attack_direction
		entry["facing"] = enemy.facing
		if is_instance_valid(enemy.target):
			entry["aim_to"] = enemy.target.global_position + CombatEffects.CHEST

func _cue_stop(actor: Node) -> void:
	var id: int = actor.get_instance_id()
	if _cues.has(id):
		effects.stop_entry(_cues[id])
		_cues.erase(id)

## The cue an enemy is showing now (tests), or an empty dictionary.
func cue_for(actor: Node) -> Dictionary:
	return _cues.get(actor.get_instance_id(), {}) if is_instance_valid(actor) else {}

func _update_cues() -> void:
	for ref: WeakRef in _watched.duplicate():
		var actor: Node = ref.get_ref() as Node
		if actor == null:
			_watched.erase(ref)
			continue
		var winding: bool = _winding(actor)
		if winding and not _cues.has(actor.get_instance_id()):
			_cue_start(actor)
		elif not winding:
			_cue_stop(actor)
		else:
			_aim(actor, _cues[actor.get_instance_id()])
	# Cues of enemies that are gone.
	for id: int in _cues.keys():
		if not is_instance_id_valid(id):
			effects.stop_entry(_cues[id])
			_cues.erase(id)

## Seconds until `room`'s next wave appears and which wave it is, or empty.
func _wave_lead(room: RescueBattlefieldRoom) -> Dictionary:
	if room is FinalBattlefieldRoom and (room as FinalBattlefieldRoom).arrival_lead() >= 0.0:
		return {"lead": (room as FinalBattlefieldRoom).arrival_lead(), "index": (room as FinalBattlefieldRoom).wave_index}
	# The first wave after the 10 rescue (RescueBattlefieldSession REINFORCEMENTS).
	var session: RescueBattlefieldSession = get_tree().current_scene as RescueBattlefieldSession
	if session != null and session.cinematic == RescueBattlefieldSession.Cinematic.REINFORCEMENTS and session._arena() == room:
		return {"lead": session.cinematic_remaining, "index": 0}
	return {}

func _update_arrivals() -> void:
	for ref: WeakRef in _fields.duplicate():
		var room: RescueBattlefieldRoom = ref.get_ref() as RescueBattlefieldRoom
		if room == null or not room.is_inside_tree():
			_fields.erase(ref)
			continue
		var wave: Dictionary = _wave_lead(room)
		if wave.is_empty():
			# The wave has appeared (its units were added before this step).
			if room.has_meta(&"fx_wave_announced"):
				room.remove_meta(&"fx_wave_announced")
		elif float(wave["lead"]) <= ARRIVAL_LEAD and not room.has_meta(&"fx_wave_announced"):
			room.set_meta(&"fx_wave_announced", true)
			for slot: Dictionary in room.upcoming_arrivals(int(wave["index"])):
				effects.spawn("arrival_ally" if slot["ally"] else "arrival_enemy", slot["at"] + CombatEffects.CHEST)

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
	_update_cues()
	_update_arrivals()
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
			# and exactly back at rest on the last frame. Power is in screen
			# pixels; the offset is in world units, so it is divided by the zoom.
			_camera.offset = _camera_rest + Vector2.from_angle(effects.clock * 83.0) * k / _camera.zoom.x

func _exit_tree() -> void:
	for entry: Dictionary in _struck:
		var visual: Node2D = (entry["visual"] as WeakRef).get_ref() as Node2D
		if visual != null:
			visual.position = entry["rest"]
	_struck.clear()
	if is_instance_valid(_camera) and shake_left > 0.0:
		_camera.offset = _camera_rest
