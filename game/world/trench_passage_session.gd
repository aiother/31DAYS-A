class_name TrenchPassageSession
extends TianSession
const PASSAGE_ID: String = "NSZC_10002_2"
const PASSAGE_CHECKPOINT: String = "NSZC_10002_2_N001"
const PASSAGE_ROOM: PackedScene = preload("res://world/rooms/nszc_10002_2.tscn")

func _room_scenes() -> Dictionary:
	var scenes: Dictionary = super._room_scenes().duplicate()
	scenes[PASSAGE_ID] = PASSAGE_ROOM
	return scenes

func _supports_checkpoint(id: String) -> bool:
	return id == PASSAGE_CHECKPOINT or super._supports_checkpoint(id)

func _checkpoint_room(id: String) -> String:
	return PASSAGE_ID if id == PASSAGE_CHECKPOINT else super._checkpoint_room(id)

func _passage() -> TrenchPassageRoom:
	return room as TrenchPassageRoom

func _bind_room() -> void:
	super._bind_room()
	var area: TrenchPassageRoom = _passage()
	if area != null:
		area.target = player
		if not area.challenge_requested.is_connected(_on_challenge_passed):
			area.challenge_requested.connect(_on_challenge_passed)
		if not area.rubble.break_requested.is_connected(_on_rubble_broken):
			area.rubble.break_requested.connect(_on_rubble_broken)
		area.refresh(data.get("events",{}))

func _change_room(target_id: String) -> void:
	super._change_room(target_id)
	if _passage() != null:
		activate_checkpoint(PASSAGE_CHECKPOINT)

func activate_checkpoint(id: String) -> bool:
	if id != PASSAGE_CHECKPOINT:
		return super.activate_checkpoint(id)
	if not has_session() or _loading or not player.life.is_alive() or _checkpoint(id)==null or data["checkpoint"]==id:
		return false
	var previous: String = str(data["checkpoint"])
	data["checkpoint"] = id
	_update_flags()
	if not save_current("堑壕第二间检查点已记录"):
		data["checkpoint"] = previous
		_update_flags()
		return false
	ui.call("save_failed","")
	return true

func _save_passage_flag(key: String, message: String) -> bool:
	if not has_session() or _passage()==null or not player.life.is_alive():
		return false
	if bool(data["events"].get(key,false)):
		return true
	var before: Dictionary = data["events"].duplicate()
	data["events"][key] = true
	if not save_current(message):
		data["events"] = before
		return false
	_passage().refresh(data["events"])
	ui.call("save_failed","")
	return true

func _on_room_enemy_defeated(reward: int) -> void:
	super._on_room_enemy_defeated(reward)
	if _passage()!=null and _cleared():
		_save_passage_flag(TrenchPassageRoom.CLEARED,"清敌完成 · 返回通路永久开启")

func _on_challenge_passed() -> void:
	_save_passage_flag(TrenchPassageRoom.CHALLENGE,"落石通道通过状态已保存")

func _on_rubble_broken() -> void:
	if _passage()!=null and _passage().return_open and _passage().challenge_saved and _passage().rubble.pending_break:
		_save_passage_flag(TrenchPassageRoom.FORWARD,"碎石堆已打碎 · 前路永久开启")

func _retry_passage() -> void:
	if _passage()==null or not has_session() or not player.life.can_control():
		return
	if _cleared():
		_save_passage_flag(TrenchPassageRoom.CLEARED,"清敌状态已保存")
	if _passage().challenge_earned:
		_on_challenge_passed()
	_on_rubble_broken()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _passage()!=null and has_session() and _interaction_input() and player.life.can_control():
		if _checkpoint_retry_in_range(PASSAGE_CHECKPOINT):
			activate_checkpoint(PASSAGE_CHECKPOINT)
		_retry_passage()

func _on_room_exit(target: String) -> void:
	var area: TrenchPassageRoom = _passage()
	if area != null:
		if not has_session() or get_tree().paused or not player.life.can_control() or _transitioning:
			return
		_retry_passage()
		if target==area.config.previous_room_id and not area.return_open:
			_notify("消灭本间敌人并保存后开启返回路")
			return
		if target==area.config.next_room_id and not area.forward_open:
			_notify("清敌并通过落石通道后，攻击打碎碎石堆")
			return
	super._on_room_exit(target)

func _on_death() -> void:
	if _passage()!=null:
		_passage().clear_rocks()
	super._on_death()

func _process(delta: float) -> void:
	super._process(delta)
	var area: TrenchPassageRoom = _passage()
	if area != null:
		$Instructions/Title.text = "逆时战场 / 堑壕第二间"
		$Instructions/Help.text = "清敌后返回 · 上层落石预警0.6秒 · 可等待或走跳躲避\n通过通道后攻击碎石堆开前路 · 状态未保存可 E / RB 重试"
		if has_session() and data["checkpoint"]!=PASSAGE_CHECKPOINT:
			$Instructions/Help.text = "入口检查点尚未保存 · 靠近旗帜按 E / RB 重试"

func _passage_retry_pending() -> bool:
	var area: TrenchPassageRoom = _passage()
	return area != null and has_session() and player.life.can_control() and ((_cleared() and not bool(data["events"].get(TrenchPassageRoom.CLEARED,false))) or (area.challenge_earned and not area.challenge_saved) or (area.return_open and area.challenge_saved and area.rubble.pending_break))

func interaction_targets() -> Array[Dictionary]:
	var result: Array[Dictionary] = super.interaction_targets()
	if has_session() and _passage() != null:
		result.append(_checkpoint_target(PASSAGE_CHECKPOINT))
		if _passage_retry_pending():
			result.append(_target("passage:retry", "重试", "保存通路", player.global_position, null, true,
				not get_tree().paused and not _world_dialogue_blocked(), true, "unlimited"))
	return result
