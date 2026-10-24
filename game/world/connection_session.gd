class_name ConnectionSession
extends ExplorationSession
const CONNECTION_ID: String = "HD_10003_1"
const CONNECTION_ROOMS: Dictionary = {
	START_ID: preload("res://world/rooms/hd_10001_1.tscn"),
	ENTRY_ID: preload("res://world/rooms/hd_10002_1.tscn"),
	TOWER_ID: preload("res://world/rooms/hd_10002_2.tscn"),
	EXPLORATION_ID: preload("res://world/rooms/hd_10002_3.tscn"),
	CONNECTION_ID: preload("res://world/rooms/hd_10003_1.tscn")
}

func _room_scenes() -> Dictionary:
	return CONNECTION_ROOMS

func _connection() -> ConnectionRoom:
	return room as ConnectionRoom

func _cleared() -> bool:
	for enemy: Node in room.get_node("Enemies").get_children():
		if enemy is ColorlessEntity and (enemy as ColorlessEntity).health > 0:
			return false
	return true

func _persist_gate(key: String) -> bool:
	if bool(data["events"].get(key, false)):
		return true
	var existed: bool = data["events"].has(key)
	data["events"][key] = true
	if not save_current("通路已永久开启"):
		if existed:
			data["events"][key] = false
		else:
			data["events"].erase(key)
		return false
	ui.call("save_failed", "")
	GameAudio.emit_from(self, &"interaction.gate")
	return true

func _on_room_enemy_defeated(reward: int) -> void:
	super._on_room_enemy_defeated(reward)
	if _connection() != null and _cleared():
		_persist_gate(_connection().return_key)

func _switch_in_range() -> bool:
	var area: ConnectionRoom = _connection()
	return area != null and (player.global_position + Vector2(0,-44)).distance_to(area.get_node("Switch").global_position) <= area.interaction_radius

func _switch_actor_ready() -> bool:
	return not _world_dialogue_blocked() and _connection() != null and has_session() and not get_tree().paused and not intro_active and player.life.can_control() and not player.combat.is_attacking() and not player.possibility.busy() and _switch_in_range()

func _can_connection_switch() -> bool:
	return _switch_actor_ready() and _cleared() and not bool(data["events"].get(_connection().forward_key, false))

func activate_switch() -> bool:
	if not _switch_actor_ready(): return false
	if not _cleared():
		_notify("先消灭当前区域的敌人")
		return false
	if not _can_connection_switch(): return false
	return _persist_gate(_connection().return_key) and _persist_gate(_connection().forward_key)

func interaction_targets() -> Array[Dictionary]:
	var result: Array[Dictionary] = super.interaction_targets()
	var area: ConnectionRoom = _connection()
	if has_session() and area != null:
		result.append(_target(area.forward_key, "开关", "开启", area.get_node("Switch").global_position,
			area.interaction_radius, _switch_in_range(), _can_connection_switch(), true))
	return result

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _interaction_input():
		activate_switch()

func _on_room_exit(target: String) -> void:
	if not has_session() or get_tree().paused or intro_active or _transitioning or not player.life.can_control():
		return
	var area: ConnectionRoom = _connection()
	if area != null and has_session():
		if target == area.config.previous_room_id:
			if not bool(data["events"].get(area.return_key, false)):
				if not _cleared() or not _persist_gate(area.return_key):
					_notify("清敌后开启返回通路")
					return
		elif target == area.config.next_room_id and not bool(data["events"].get(area.forward_key, false)):
			_notify("清敌后靠近开关，按 E / RB 开启前路")
			return
	super._on_room_exit(target)

func _process(delta: float) -> void:
	super._process(delta)
	var area: ConnectionRoom = _connection()
	if area != null and has_session():
		area.refresh(player, data["events"], _cleared())
		$Instructions/Help.text = "清敌后返回通路永久开启 · 清敌后 E / RB 操作开关\n已开启通路会保存 · 死亡仍返回瓦砾塔入口检查点"
