class_name AudioEventService
extends Node
## Always-process mixer. Observers never advance or alter game state.
signal event_emitted(record: Dictionary)
signal context_changed(region: String, music: String)
var mapping: AudioEventMap = preload("res://systems/audio/default_audio_map.tres")
var history: Array[Dictionary] = []
var region: String = ""
var music: String = ""
var _world: WeakRef
var _world_id: int = 0
var _tracks: Array[Dictionary] = []
var _tones: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_added)

func _added(node: Node) -> void:
	# Bind only after @onready and the actor's normal _ready have completed.
	if node is PlayerController or node is ColorlessEntity or node is OverlookBoss or node is ParasiteBoss or node is WorldRoom or node is CheckpointLab or node is Control:
		node.ready.connect(_bind.bind(node), CONNECT_ONE_SHOT)

func _bind(node: Node) -> void:
	if node is PlayerController:
		var player := node as PlayerController
		player.landed.connect(func(_speed: float, hard: bool) -> void: GameAudio.emit_from(player, &"player.hard_land" if hard else &"player.land", player.global_position))
		player.combat.attack_started.connect(func(_direction: Vector2, _combo: int) -> void: GameAudio.emit_from(player, &"combat.swing", player.global_position))
		player.combat.hit_confirmed.connect(_confirmed.bind(player))
		player.life.damaged.connect(func(_amount: int, _impulse: Vector2) -> void: GameAudio.emit_from(player, &"player.hurt", player.global_position))
		player.life.died.connect(func() -> void: GameAudio.emit_from(player, &"player.death", player.global_position))
		player.possibility.gained.connect(func(_amount: int, at: Vector2) -> void: GameAudio.emit_from(player, &"possibility.gain", at))
		player.possibility.shortfall.connect(func(_kind: int) -> void: GameAudio.emit_from(player, &"possibility.shortfall", player.global_position))
	elif node is ColorlessEntity:
		var enemy := node as ColorlessEntity
		enemy.attack_started.connect(func(_ranged: bool) -> void: GameAudio.emit_from(enemy, &"enemy.windup", enemy.global_position))
		enemy.defeated.connect(func(_reward: int) -> void: GameAudio.emit_from(enemy, &"enemy.death", enemy.global_position))
		enemy.hurtbox.hit_received.connect(_enemy_hit.bind(enemy))
	elif node is OverlookBoss or node is ParasiteBoss:
		node.get_node("GameplayRoot/Hurtbox").hit_received.connect(_enemy_hit.bind(node))
		node.defeated.connect(func() -> void: GameAudio.emit_from(node, &"boss.defeated", node.global_position))
	elif node is WorldRoom:
		stop_game()
		_world = weakref(node)
		_world_id = node.get_instance_id()
		node.tree_exiting.connect(_world_exited.bind(_world_id))
	elif node is CheckpointLab:
		node.item_obtained.connect(func(_kind: String, _name: String) -> void: GameAudio.emit_from(node, &"interaction.pickup"))
	elif node is Control:
		node.focus_entered.connect(func() -> void: GameAudio.emit_from(node, &"ui.focus"))
		if node is BaseButton:
			node.pressed.connect(_button.bind(node))

func _confirmed(target: CombatHurtbox, _damage: int, _impulse: Vector2, player: PlayerController) -> void:
	var reflected: bool = target.get_parent() is ColorlessProjectile and (target.get_parent() as ColorlessProjectile).reflected
	GameAudio.emit_from(player, &"combat.reflect" if reflected else &"combat.hit", target.global_position)

func _enemy_hit(damage: int, _impulse: Vector2, _source: Node2D, _serial: int, enemy: Node2D) -> void:
	# The normal health handler ran first; no sound for rejected/zero/dead hits.
	if damage > 0 and bool(enemy.get("flash") if enemy is OverlookBoss or enemy is ParasiteBoss else enemy.get("_flash")):
		GameAudio.emit_from(enemy, &"enemy.hurt", enemy.global_position)

func _button(button: BaseButton) -> void:
	var back: bool = button is Button and (button as Button).text in ["返回", "取消", "留下", "返回主界面"]
	GameAudio.emit_from(button, &"ui.back" if back else &"ui.confirm")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo() and (get_tree().paused or get_viewport().gui_get_focus_owner() != null):
		play(&"ui.back")

func play(event: StringName, at: Vector2 = Vector2.INF, source: Node = null) -> Dictionary:
	var ui: bool = String(event).begins_with("ui.")
	if get_tree().paused and not ui:
		return {}
	var clip: AudioStream = mapping.clips.get(String(event)) as AudioStream
	if clip == null and String(event) in mapping.placeholders:
		if not _tones.has(event):
			_tones[event] = PlaceholderTone.make(330.0 if event == &"enemy.windup" else 700.0)
		clip = _tones[event]
	var voice: AudioStreamPlayer
	if clip != null:
		if voices.size() >= 32:
			_dispose(voices[0])
		voice = AudioStreamPlayer.new()
		voice.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		voice.bus = &"效果音"
		voice.process_mode = Node.PROCESS_MODE_ALWAYS if ui else Node.PROCESS_MODE_PAUSABLE
		voice.set_meta("ui", ui)
		voice.set_meta("source", weakref(source) if is_instance_valid(source) else null)
		voice.stream = clip
		voice.volume_db = -18.0
		add_child(voice)
		voices.append(voice)
		voice.finished.connect(_dispose.bind(voice))
		voice.play()
	var record: Dictionary = {"event":String(event), "bus":voice.bus if voice != null else &"效果音", "stream":voice.stream if voice != null else null,
		"voice":weakref(voice) if voice != null else null, "position":at, "physics_frame":Engine.get_physics_frames(), "audible":voice != null}
	history.append(record)
	if history.size() > 512: history.pop_front()
	event_emitted.emit(record)
	return record

func _dispose(voice: AudioStreamPlayer) -> void:
	voices.erase(voice)
	if is_instance_valid(voice):
		voice.stop()
		voice.stream = null
		voice.queue_free()

func stop_game() -> void:
	for voice: AudioStreamPlayer in voices.duplicate():
		if not bool(voice.get_meta("ui", false)): _dispose(voice)

func _world_exited(id: int) -> void:
	if id != _world_id: return
	_world = null
	_world_id = 0
	stop_game()
	set_context("", "")

func _process(delta: float) -> void:
	for voice: AudioStreamPlayer in voices.duplicate():
		var source: WeakRef = voice.get_meta("source") as WeakRef if voice.has_meta("source") else null
		if source != null and source.get_ref() == null:
			_dispose(voice)
		else:
			voice.stream_paused = get_tree().paused and not bool(voice.get_meta("ui", false))
	var room: WorldRoom = _world.get_ref() as WorldRoom if _world != null else null
	if is_instance_valid(room): _context(room)
	for track: Dictionary in _tracks.duplicate():
		var player: AudioStreamPlayer = track["player"]
		player.stream_paused = get_tree().paused
		if not get_tree().paused:
			track["gain"] = move_toward(float(track["gain"]), float(track["target"]), delta / maxf(0.01, mapping.fade_seconds))
			player.volume_db = linear_to_db(maxf(0.0001, track["gain"]))
			if track["gain"] == 0.0 and track["target"] == 0.0:
				player.stop()
				player.stream = null
				player.queue_free()
				_tracks.erase(track)

func _context(room: WorldRoom) -> void:
	var session: Node = room.get_parent()
	if session.has_method("has_session") and not session.call("has_session"):
		stop_game()
		set_context("", "")
		return
	var mode: String = "exploration"
	var dialogue: Node = session.get_node_or_null("FieldDialogue")
	if (dialogue != null and (dialogue.get("active") or dialogue.get("confirming"))) or session.get("intro_active") == true or (session.get("cinematic") != null and int(session.get("cinematic")) != 0):
		mode = "story"
	elif room.config.room_id in ["HD_10004_1", "HD_20003_1", "NSZC_10003_1"]:
		mode = "large_battle"
	elif room.has_node("Enemies"):
		for enemy: Node in room.get_node("Enemies").get_children():
			if enemy is ColorlessEntity and enemy.state not in [ColorlessEntity.State.IDLE, ColorlessEntity.State.DEAD]:
				mode = "combat"
				break
	set_context(room.config.region_id, mode)

func set_context(next_region: String, next_music: String) -> void:
	if region == next_region and music == next_music: return
	var old_region: String = region
	var old_music: String = music
	region = next_region
	music = next_music
	if region != old_region: _slot("environment", mapping.environments.get(region) as AudioStream)
	if music != old_music: _slot("music", mapping.music.get(music) as AudioStream)
	context_changed.emit(region, music)

func _slot(kind: String, clip: AudioStream) -> void:
	for track: Dictionary in _tracks:
		if track["kind"] == kind: track["target"] = 0.0
	if clip == null: return
	var player := AudioStreamPlayer.new()
	player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	player.bus = &"背景音"
	player.stream = clip
	player.volume_db = -80.0
	add_child(player)
	_tracks.append({"kind":kind, "player":player, "gain":0.0, "target":1.0})
	player.play()

func stop_all() -> void:
	for voice: AudioStreamPlayer in voices.duplicate(): _dispose(voice)
	for track: Dictionary in _tracks:
		var player: AudioStreamPlayer = track["player"]
		player.stop()
		player.stream = null
		player.queue_free()
	_tracks.clear()
	_world = null
	_world_id = 0
	region = ""
	music = ""

func _exit_tree() -> void:
	stop_all()
	history.clear()
	_tones.clear()
	# The mixer thread may still own a final WAV playback after stop().
	# Only application/autoload teardown waits; never block gameplay/room changes.
	OS.delay_msec(200)
