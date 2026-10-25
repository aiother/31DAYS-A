class_name StartRoomSession
extends CheckpointLab
const BIRTH: String = "HD_10001_1_N001"
const GUIDE: String = "HD_10001_1_N002"
const CHECKPOINT: String = "HD_10001_1_N003"
var cinematics: CinematicDirector = CinematicDirector.new()
## Compatibility projection for existing scene/UI/test clients. No second flag.
var intro_active: bool:
	get: return bool(cinematics.state()["locks_control"])
	set(value):
		if value and not intro_active: cinematics.begin(&"legacy.lock")
		elif not value and intro_active: cinematics.finish()
var _on_ground: bool:
	get: return bool(cinematics.value("on_ground",false))
	set(value): cinematics.set_value("on_ground",value)
var _get_up_remaining: float:
	get: return cinematics.remaining(&"opening")
	set(value): cinematics.duration(&"opening", value)
var _fall_speed: float:
	get: return float(cinematics.value("fall_speed",0.0))
	set(value): cinematics.set_value("fall_speed",value)
var _guide_remaining: float = 0.0
var _exit_shown: bool = false
@onready var room: WorldRoom = $Room

func _ready() -> void:
	cinematics.bind(self)
	cinematics.changed.connect(_apply_cinematic_state)
	store.initial_checkpoint = CHECKPOINT
	room.checkpoint_requested.connect(activate_checkpoint)
	room.exit_requested.connect(_on_room_exit)
	room.exit_left.connect(func() -> void: _exit_shown = false)
	super._ready()
	var camera: Camera2D = player.get_node("Camera2D") as Camera2D
	camera.limit_left = int(room.config.bounds.position.x)
	camera.limit_top = int(room.config.bounds.position.y)
	camera.limit_right = int(room.config.bounds.end.x)
	camera.limit_bottom = int(room.config.bounds.end.y)

func _build_ground() -> void:
	# PackedScene WorldRoom owns its geometry; debug arena generation is skipped.
	pass

func _draw() -> void:
	pass

func _restore(snapshot: Dictionary, revive: bool) -> void:
	# Isolated namespace rejects debug checkpoint IDs before attempting a teleport.
	if _checkpoint(str(snapshot.get("checkpoint", ""))) == null:
		ui.call("save_failed", "此存档不属于起始Room，请选择新游戏")
		return
	cinematics.reset()
	super._restore(snapshot, revive)
	_exit_shown = false
	if room.config.room_id == "HD_10001_1" and not bool(data["events"].get(BIRTH, false)) and not revive:
		cinematics.begin(&"opening")
		_on_ground = false
		_fall_speed = 0.0
		_get_up_remaining = room.config.get_up_duration
		player.position = room.config.fall_start
		player.reset_kinematics()
		(player.get_node("Camera2D") as Camera2D).reset_smoothing()
	else:
		intro_active = false

func _physics_process(delta: float) -> void:
	if not has_session() or not cinematics.active(&"opening"):
		return
	if not player.life.is_alive():
		cinematics.finish(&"opening")
		return
	cinematics.advance(delta)
	if _get_up_remaining > 0.0:
		return
	if not bool(cinematics.value("attempted",false)) or _interaction_input():
		cinematics.set_value("attempted",true)
		_finish_birth()

func _finish_birth() -> bool:
	var before: Dictionary = data.duplicate(true)
	data["events"][BIRTH] = true
	data["events"][CHECKPOINT] = true
	var guide: bool = not bool(data["events"].get(GUIDE,false))
	if guide: data["events"][GUIDE] = true
	if not cinematics.attempt_commit(&"opening", func() -> bool: return save_current("深谷检查点已记录")):
		data = before
		return false
	cinematics.finish(&"opening")
	player.reset_kinematics()
	if guide: _guide_remaining = room.config.guide_duration
	return true

func _process(delta: float) -> void:
	super._process(delta)
	_guide_remaining = maxf(0.0, _guide_remaining - delta)
	$Instructions/EnemyStatus.text = "" if _notice_remaining <= 0.0 else _notice
	if intro_active:
		$Instructions/Help.text = "挣扎起身……" if _on_ground else "坠落……"
	elif _guide_remaining > 0.0:
		$Instructions/Help.text = "A / D 或 ← / → 移动 · 空格跳跃（长按更高）\n手柄：左摇杆 / 十字键移动 · A 跳跃"
	else:
		$Instructions/Help.text = "向右探索裂缝 · Esc 暂停 / 存档槽 / 保存并退出"
	# Visual-only placeholder get-up; physics/collision stay unchanged.
	var sprite: Sprite2D = player.get_node("VisualRoot/PlaceholderSprite") as Sprite2D
	if cinematics.active(&"opening"):
		cinematics.render_frame(delta)
	elif player.life.is_alive():
		sprite.rotation = 0.0

func _on_room_exit(target: String) -> void:
	if not has_session() or intro_active or not player.life.can_control() or _exit_shown:
		return
	_exit_shown = true
	if not save_current("起始区进度已保存"):
		_exit_shown = false
		return
	ui.call("show_room_boundary", target)

func _checkpoint_retry_in_range(id: String, correct_room: bool = true) -> bool:
	return correct_room and has_session() and player.life.can_control() and player.position.distance_to(_checkpoint(id).config.spawn_position) <= 96

func _checkpoint_target(id: String) -> Dictionary:
	var point: Vector2 = _checkpoint(id).config.spawn_position
	var needed: bool = str(data["checkpoint"]) != id
	# Ravine additionally settles its permanent flag and day on the same retry.
	if id == "HD_20001_1_N001":
		needed = needed or not bool(data["events"].get(id, false)) or (bool(data["events"].get("TY_10001_1_N002", false)) and int(data.get("day",1)) < 2)
	return _target(id, "检查点", "记录检查点", to_global(point), 96.0,
		player.position.distance_to(point) <= 96, not get_tree().paused and not _world_dialogue_blocked() and _checkpoint_retry_in_range(id) and needed)

## Single read-only policy query for clocks, HUD, controls and music.
func cinematic_state() -> Dictionary:
	var result: Dictionary = cinematics.state()
	var dialogue: Node = get_node_or_null("FieldDialogue")
	var talking: bool = dialogue != null and (bool(dialogue.get("active")) or bool(dialogue.get("confirming")))
	result["pauses_clock"] = bool(result["pauses_clock"]) or get_tree().paused or talking
	result["story_music"] = bool(result["story_music"]) or talking
	return result

func _apply_cinematic_state() -> void:
	if not is_instance_valid(player) or not is_instance_valid(ui): return
	var state: Dictionary = cinematic_state()
	player.life.scripted_control_locked = bool(state["locks_control"])
	$Instructions.visible = not bool(state["hides_hud"])
	var health: Label = ui.get("_health") as Label
	if health != null: health.visible = not bool(state["hides_hud"])
