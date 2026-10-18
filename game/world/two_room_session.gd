class_name TwoRoomSession
extends StartRoomSession
const START_ID: String = "HD_10001_1"
const ENTRY_ID: String = "HD_10002_1"
const ENTRY_CHECKPOINT: String = "HD_10002_1_N002"
const ENCOUNTER: String = "HD_10002_1_N001"
# Both delivered Rooms are adjacent. Resources preload; only one instance is active.
const ROOMS: Dictionary = {
	START_ID: preload("res://world/rooms/hd_10001_1.tscn"),
	ENTRY_ID: preload("res://world/rooms/hd_10002_1.tscn")
}
var _transitioning: bool = false

func _room_scenes() -> Dictionary:
	return ROOMS

func _ready() -> void:
	super._ready()
	_bind_room()

func _supports_checkpoint(id: String) -> bool:
	return id == CHECKPOINT or id == ENTRY_CHECKPOINT

func _checkpoint_room(id: String) -> String:
	return ENTRY_ID if id == ENTRY_CHECKPOINT else START_ID

func _restore(snapshot: Dictionary, revive: bool) -> void:
	var id: String = str(snapshot.get("checkpoint", ""))
	if not _supports_checkpoint(id):
		ui.call("save_failed", "检查点不属于当前已开放区域")
		return
	_loading = true
	_mount_room(_checkpoint_room(id))
	super._restore(snapshot, revive)
	_bind_room()

func _mount_room(id: String) -> void:
	if room.config.room_id == id:
		return
	var old: WorldRoom = room
	remove_child(old)
	old.queue_free()
	room = (_room_scenes()[id] as PackedScene).instantiate() as WorldRoom
	room.name = "Room"
	add_child(room)
	move_child(room, 0)
	ground = room.get_node("Ground") as TileMapLayer
	_bind_room()
	var camera: Camera2D = player.get_node("Camera2D") as Camera2D
	camera.limit_left = int(room.config.bounds.position.x)
	camera.limit_top = int(room.config.bounds.position.y)
	camera.limit_right = int(room.config.bounds.end.x)
	camera.limit_bottom = int(room.config.bounds.end.y)

func _bind_room() -> void:
	if not room.checkpoint_requested.is_connected(activate_checkpoint):
		room.checkpoint_requested.connect(activate_checkpoint)
	if not room.exit_requested.is_connected(_on_room_exit):
		room.exit_requested.connect(_on_room_exit)
	if not room.encounter_requested.is_connected(_on_encounter):
		room.encounter_requested.connect(_on_encounter)
	if not room.exit_left.is_connected(_on_room_exit_left):
		room.exit_left.connect(_on_room_exit_left)
	if room.has_node("Enemies"):
		for child: Node in room.get_node("Enemies").get_children():
			if child is ColorlessEntity:
				var enemy: ColorlessEntity = child as ColorlessEntity
				if has_session() and not _loading and room.config.room_id not in ["HD_10004_1", "HD_20003_1", "NSZC_10003_1"]:
					WorldDayRules.apply_enemy(enemy, int(data.get("day", 1)))
				enemy.target = player
				enemy.coordinator = room.get_node("AttackCoordinator") as EnemyAttackCoordinator
				enemy.set_physics_process(room.config.room_id != ENTRY_ID or bool(data.get("events", {}).get(ENCOUNTER, false)))
				if not enemy.defeated.is_connected(_on_room_enemy_defeated):
					enemy.defeated.connect(_on_room_enemy_defeated)

func _on_room_enemy_defeated(reward: int) -> void:
	# Reset enemies still pay their configured reward (+2 colorless, +7 monochrome).
	_on_defeated(reward)

func _on_room_exit_left() -> void:
	_exit_shown = false

func _on_encounter() -> void:
	if not has_session() or intro_active or _transitioning or room.config.room_id != ENTRY_ID:
		return
	if bool(data["events"].get(ENCOUNTER, false)):
		return
	record_event(ENCOUNTER)
	ui.call("show_enemy_intro", room.config.encounter_duration)
	_bind_room()

func _on_room_exit(target: String) -> void:
	if not has_session() or intro_active or _transitioning or not player.life.can_control():
		return
	if target != room.config.previous_room_id and target != room.config.next_room_id:
		return
	if not _room_scenes().has(target):
		if not _exit_shown and save_current("当前进度已保存"):
			_exit_shown = true
			ui.call("show_room_boundary", target)
		return
	if not save_current("正在进入相邻区域"):
		return
	_transitioning = true
	_change_room.call_deferred(target)

func _change_room(target: String) -> void:
	if not player.life.is_alive():
		_transitioning = false
		return
	ui.call("hide_enemy_intro")
	var from_id: String = room.config.room_id
	_mount_room(target)
	player.reset_kinematics()
	player.position = room.config.entry_from_previous if room.config.previous_room_id == from_id else room.config.entry_from_next
	_exit_shown = false
	_transitioning = false
	_update_flags()
	(player.get_node("Camera2D") as Camera2D).reset_smoothing()
	_notify(room.config.display_name)

func _process(delta: float) -> void:
	super._process(delta)
	$Instructions/Title.text = "荒地 / " + room.config.display_name
	if not intro_active and _guide_remaining <= 0.0 and room.config.room_id == ENTRY_ID:
		$Instructions/Help.text = "空格跨越高台 · J 攻击 · K 闪避 · 长按 L 恢复\n向左返回深谷，向右探索道路"
