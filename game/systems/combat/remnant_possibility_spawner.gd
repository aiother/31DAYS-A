class_name RemnantPossibilitySpawner
extends Node2D
## A separate Room child: never counted by Enemies, summons, waves or allies.
const SETTINGS: RemnantPossibilityConfig = preload("res://data/enemies/remnant_possibility.tres")
const ENTITY: PackedScene = preload("res://enemies/remnant_possibility_entity.tscn")
@export var config: RemnantPossibilityConfig = SETTINGS
var session: Node
var room: WorldRoom
var player: PlayerController
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var remaining: float = -1.0

static func attach(owner_session: Node, area: WorldRoom, target: PlayerController) -> RemnantPossibilitySpawner:
	if not (area is CampWavesRoom or area is BossRoom or area is ParasiteRoom or area is RescueBattlefieldRoom):
		return null
	var existing: RemnantPossibilitySpawner = area.get_node_or_null("RemnantPossibility") as RemnantPossibilitySpawner
	if existing != null:
		return existing
	var component: RemnantPossibilitySpawner = RemnantPossibilitySpawner.new()
	component.name = "RemnantPossibility"
	component.session = owner_session
	component.room = area
	component.player = target
	area.add_child(component)
	return component

func _ready() -> void:
	# Observe ending/death even when the tree is paused; tick explicitly freezes time.
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_physics_priority = -5
	rng.randomize()
	player.life.died.connect(clear_entities)

func living() -> Array[RemnantPossibilityEntity]:
	var result: Array[RemnantPossibilityEntity] = []
	for child: Node in get_children():
		if child is RemnantPossibilityEntity and not child.is_queued_for_deletion() and child.health > 0:
			result.append(child as RemnantPossibilityEntity)
	return result

func encounter_active() -> bool:
	if not is_instance_valid(player) or not player.life.is_alive() or not bool(session.call("has_session")):
		return false
	if room is CampWavesRoom:
		return room.phase not in [CampWavesRoom.Phase.READY, CampWavesRoom.Phase.COMPLETE]
	if room is BossRoom:
		var boss: OverlookBoss = room.get_node("Boss") as OverlookBoss
		return not room.opened and boss.state not in [OverlookBoss.State.WAITING, OverlookBoss.State.DEAD]
	if room is ParasiteRoom:
		var boss: ParasiteBoss = room.get_node("Boss") as ParasiteBoss
		return not room.opened and boss.state not in [ParasiteBoss.State.WAITING, ParasiteBoss.State.DEAD]
	if room is FinalBattlefieldRoom:
		if room.victory or room.wave_state == FinalBattlefieldRoom.WaveState.COMPLETE:
			return false
		if room.phase == RescueBattlefieldRoom.Phase.COOP and room.wave_state == FinalBattlefieldRoom.WaveState.WARNING:
			return true
	if room is RescueBattlefieldRoom:
		return room.started and not room.completed and not room.stopped and room.phase != RescueBattlefieldRoom.Phase.RESCUE
	return false

func frozen() -> bool:
	var dialogue: FieldDialogue = session.get_node_or_null("FieldDialogue") as FieldDialogue
	return get_tree().paused or player.life.scripted_control_locked or bool(session.get("intro_active")) or bool(session.get("_loading")) or bool(session.get("_reloading")) or bool(session.get("_transitioning")) or (dialogue != null and (dialogue.active or dialogue.confirming))

func clear_entities() -> void:
	remaining = -1.0
	for child: Node in get_children():
		if child is RemnantPossibilityEntity:
			child.hurtbox.accepts_hits = false
			child.set_physics_process(false)
			remove_child(child)
			child.queue_free()

func _exit_tree() -> void:
	clear_entities()

func _physics_process(delta: float) -> void:
	tick(delta)

func tick(delta: float) -> void:
	if not encounter_active():
		clear_entities()
		return
	var stopped: bool = frozen()
	for entity: RemnantPossibilityEntity in living():
		entity.movement_enabled = not stopped
		entity.hurtbox.accepts_hits = not stopped
	if stopped:
		return
	if player.possibility.balance * 2 >= player.possibility.maximum:
		remaining = -1.0
		return
	if remaining < 0.0:
		remaining = rng.randf_range(config.interval_min, config.interval_max)
	remaining = maxf(0.0, remaining - delta)
	if remaining > 0.0:
		return
	var count: int = mini(rng.randi_range(config.batch_min, config.batch_max), maxi(0, config.live_limit - living().size()))
	for i: int in range(count):
		_spawn_one()
	remaining = rng.randf_range(config.interval_min, config.interval_max)

func _spawn_one() -> void:
	var capsule: CapsuleShape2D = CapsuleShape2D.new()
	capsule.radius = 24.0
	capsule.height = 80.0
	for attempt: int in range(config.spawn_attempts):
		var point: Vector2 = room.to_local(player.global_position) + Vector2(rng.randf_range(-config.horizontal_range, config.horizontal_range), -rng.randf_range(config.height_min, config.height_max))
		if not room.config.bounds.encloses(Rect2(point - Vector2(24, 80), Vector2(48, 80))):
			continue
		# A newly added body's broadphase may not be synchronized until next frame.
		# Check our own current batch directly as well as the physics world.
		var overlaps_remnant: bool = false
		for existing: RemnantPossibilityEntity in living():
			if Rect2(point - Vector2(24, 80), Vector2(48, 80)).intersects(Rect2(existing.position - Vector2(24, 80), Vector2(48, 80))):
				overlaps_remnant = true
				break
		if overlaps_remnant:
			continue
		var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		query.shape = capsule
		query.transform = Transform2D(0.0, room.to_global(point - Vector2(0, 40)))
		query.collision_mask = 1 | 2 | 4
		query.collide_with_areas = false
		if not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
			continue
		var entity: RemnantPossibilityEntity = ENTITY.instantiate() as RemnantPossibilityEntity
		entity.remnant = config
		entity.position = point
		entity.arena_bounds = room.config.bounds
		entity.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(entity)
		entity.defeated.connect(_on_defeated)
		return

func _on_defeated(reward: int) -> void:
	if encounter_active() and not frozen():
		session.call("_on_room_enemy_defeated", reward)
