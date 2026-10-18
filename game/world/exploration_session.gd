class_name ExplorationSession
extends TowerSession
const EXPLORATION_ID: String = "HD_10002_3"
const PEARL_KEYS: Array[String] = [
	"item:HD_10002_3:pearl_01",
	"keyitem:HD_20001_3:pearl_01",
	"keyitem:HD_20002_1:pearl_01",
	"item:NSZC_10002_1:pearl_01"
]
const EXPLORATION_ROOMS: Dictionary = {
	START_ID: preload("res://world/rooms/hd_10001_1.tscn"),
	ENTRY_ID: preload("res://world/rooms/hd_10002_1.tscn"),
	TOWER_ID: preload("res://world/rooms/hd_10002_2.tscn"),
	EXPLORATION_ID: preload("res://world/rooms/hd_10002_3.tscn")
}

func _room_scenes() -> Dictionary:
	return EXPLORATION_ROOMS

func _restore(snapshot: Dictionary, revive: bool) -> void:
	super._restore(snapshot, revive)
	_sync_pearl_growth()

func _sync_pearl_growth() -> void:
	var count: int = 0
	if has_session():
		for key: String in PEARL_KEYS:
			if bool(data["events"].get(key, false)):
				count += 1
	player.combat.pearl_count = count

func _bind_room() -> void:
	super._bind_room()
	if has_session():
		if room.environment_hazard!=null:
			room.environment_hazard.refresh(player,data["events"])
		for pickup: RoomPickup in _pickups():
			pickup.refresh(player, bool(data["events"].get(pickup.config.persistence_key, false)))

func _pickups() -> Array[RoomPickup]:
	var result: Array[RoomPickup] = []
	for node: Node in get_tree().get_nodes_in_group("room_pickups"):
		if node is RoomPickup and room.is_ancestor_of(node):
			result.append(node as RoomPickup)
	return result

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not has_session() or intro_active:
		return
	if Input.is_action_just_pressed("interact"):
		if activate_environment_switch():
			return
		for pickup: RoomPickup in _pickups():
			if collect_pickup(pickup):
				break

func activate_environment_switch() -> bool:
	if not has_session() or get_tree().paused or intro_active or _transitioning or room.environment_hazard==null or not room.environment_hazard.can_interact(player):
		return false
	var hazard: RoomRockfall = room.environment_hazard
	var key: String = hazard.config.persistence_key
	var existed: bool = data["events"].has(key)
	data["events"][key] = true
	if not save_current("本间落石已永久关闭"):
		if existed: data["events"][key] = false
		else: data["events"].erase(key)
		return false
	hazard.refresh(player,data["events"])
	ui.call("save_failed","")
	return true

func collect_pickup(pickup: RoomPickup) -> bool:
	if get_tree().paused or not has_session() or intro_active or not is_instance_valid(pickup) or not room.is_ancestor_of(pickup) or not pickup.can_collect(player):
		return false
	var key: String = pickup.config.persistence_key
	if bool(data["events"].get(key, false)):
		return false
	var existed: bool = data["events"].has(key)
	data["events"][key] = true
	if not save_current("获得" + pickup.config.display_name):
		if existed:
			data["events"][key] = false
		else:
			data["events"].erase(key)
		return false
	pickup.refresh(player, true)
	_sync_pearl_growth()
	if key in PEARL_KEYS:
		_notify("珍珠 %d / 4 · 近战范围 %d%%" % [player.combat.pearl_count, roundi(player.combat.range_multiplier() * 100)])
	ui.call("save_failed", "")
	return true

func _process(delta: float) -> void:
	super._process(delta)
	if has_session():
		if room.environment_hazard!=null:
			room.environment_hazard.refresh(player,data["events"])
		for pickup: RoomPickup in _pickups():
			pickup.refresh(player, bool(data["events"].get(pickup.config.persistence_key, false)))
	if room.config.room_id == EXPLORATION_ID:
		$Instructions/Help.text = "沿平台上行 · 下层支路可探索珍珠 · E / RB 拾取\n空中 S + J 下攻击 · 主路线不要求珍珠或闪避"
