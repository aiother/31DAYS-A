class_name RavineDepthSession
extends RavineRescueSession
const DEPTH_ID: String = "HD_20001_3"
const DEPTH_HELPED: String = "rescue:HD_20001_3:completed"
const DEPTH_FAILED: String = "rescue:HD_20001_3:failed"
const DEPTH_SEEN: String = "rescue:HD_20001_3:seen"
const DEPTH_ROOM: PackedScene = preload("res://world/rooms/hd_20001_3.tscn")

func _room_scenes() -> Dictionary:
	var scenes: Dictionary = super._room_scenes().duplicate()
	scenes[DEPTH_ID] = DEPTH_ROOM
	return scenes

func _gaze_maximum() -> int:
	return 12 + int(bool(data["events"].get(HELPED,false))) + int(bool(data["events"].get(DEPTH_HELPED,false)))

func _depth_pending() -> bool:
	return not rescue_expired(DEPTH_ID) and bool(data["events"].get(DEPTH_SEEN,false)) and not bool(data["events"].get(DEPTH_HELPED,false)) and not bool(data["events"].get(DEPTH_FAILED,false))

func _on_encounter() -> void:
	if room is RavineDepthRoom and has_session():
		if not bool(data["events"].get(DEPTH_SEEN,false)):
			record_event(DEPTH_SEEN)
		if _cleared():
			settle_depth()
		return
	super._on_encounter()

func _on_room_enemy_defeated(reward: int) -> void:
	super._on_room_enemy_defeated(reward)
	if room is RavineDepthRoom and _cleared():
		settle_depth()

func settle_depth() -> bool:
	if not room is RavineDepthRoom or not has_session() or get_tree().paused or not player.life.is_alive() or not _cleared():
		return false
	var rescue: bool = _depth_pending()
	if bool(data["events"].get(RavineDepthRoom.GATES,false)) and not rescue:
		return false
	var before: Dictionary = data["events"].duplicate()
	var balance: int = player.possibility.balance
	var maximum: int = player.possibility.maximum
	data["events"][RavineDepthRoom.GATES] = true
	if rescue:
		data["events"][DEPTH_HELPED] = true
		if bool(data["events"].get(GAZE,false)):
			_set_maximum(_gaze_maximum())
		_set_balance(mini(player.possibility.maximum,balance+4))
	if not save_current("清敌完成 · 通路已永久开启"):
		data["events"] = before
		_set_maximum(maximum)
		_set_balance(balance)
		data["maximum"] = maximum
		data["balance"] = balance
		return false
	ui.call("save_failed", "")
	if rescue:
		dialogue_ui.show_notice("清敌救助完成 · 可能性 +%d · 上限%d" % [player.possibility.balance-balance,player.possibility.maximum])
	return true

func _on_room_exit(target: String) -> void:
	if not room is RavineDepthRoom:
		super._on_room_exit(target)
		return
	if not has_session() or get_tree().paused or intro_active or _transitioning or not player.life.can_control() or dialogue_ui.confirming or (target != room.config.previous_room_id and target != room.config.next_room_id):
		return
	if _cleared():
		settle_depth()
	if not bool(data["events"].get(RavineDepthRoom.GATES,false)):
		if target != RESCUE_ID:
			_notify("消灭当前区域的敌人后开启前路")
			return
		# Explicitly approved early retreat: abandoning this NPC does not clear either gate.
		if not rescue_expired(DEPTH_ID) and not bool(data["events"].get(DEPTH_FAILED,false)):
			data["events"][DEPTH_SEEN] = true
			_end_dialogue()
			_departure_target = target
			player.reset_kinematics()
			player.life.scripted_control_locked = true
			dialogue_ui.show_departure()
			dialogue_ui.speaker.text = "沟壑深处的幸存者"
			dialogue_ui.text.text = "敌人还在，这里的人仍需要帮助。\n确认撤回将永久失去这次清敌救助机会，通路不会因此解锁。"
			return
		_end_dialogue()
		# Already abandoned; retrying retreat still saves current resources normally.
		super._on_room_exit(target)
		return
	super._on_room_exit(target)

func confirm_departure() -> bool:
	if not room is RavineDepthRoom:
		return super.confirm_departure()
	if get_tree().paused or not player.life.is_alive() or not dialogue_ui.confirming or _departure_target != RESCUE_ID:
		return false
	var before: Dictionary = data["events"].duplicate()
	data["events"][DEPTH_FAILED] = true
	if not save_current("已永久放弃沟壑深处救助"):
		data["events"] = before
		return false
	_departure_target = ""
	_end_dialogue()
	ui.call("save_failed", "")
	_transitioning = true
	_change_room.call_deferred(RESCUE_ID)
	return true

func _on_death() -> void:
	if room is RavineDepthRoom:
		_departure_target = ""
		_end_dialogue()
	super._on_death()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if room is RavineDepthRoom and has_session() and not dialogue_ui.confirming and _interaction_input():
		settle_depth()

func quest_status_text() -> String:
	if room is RavineDepthRoom and has_session(): return _depth_quest_objective()
	return super.quest_status_text()

func _depth_quest_objective() -> String:
	if rescue_expired(DEPTH_ID): return "沟壑深处救助已过期 · 清敌仍可开启通路"
	if bool(data["events"].get(DEPTH_HELPED,false)):
		return "清敌救助已完成" + (" · 成长待首次注视结算" if not bool(data["events"].get(GAZE,false)) else " · 可能性上限%d" % player.possibility.maximum)
	if bool(data["events"].get(DEPTH_FAILED,false)):
		return "本次救助已永久放弃 · 清敌仍可开启通路"
	return "消灭当前区域全部敌人，帮助幸存者"

func _rescue_objective(id: String) -> String:
	if id == DEPTH_ID: return _depth_quest_objective()
	return super._rescue_objective(id)

func _process(delta: float) -> void:
	super._process(delta)
	if room is RavineDepthRoom and has_session():
		(room as RavineDepthRoom).refresh(bool(data["events"].get(DEPTH_HELPED,false)),bool(data["events"].get(DEPTH_FAILED,false)) or rescue_expired(DEPTH_ID),bool(data["events"].get(RavineDepthRoom.GATES,false)))
		if rescue_expired(DEPTH_ID): (room.get_node("Survivor/Name") as Label).text = "幸存者 · 救助已过期"
		$Instructions/Help.text = "清敌后永久开启两端通路 · E / RB 拾取珍珠占位\n向左可确认放弃救助并撤回"
		if bool(data["events"].get(RavineDepthRoom.GATES,false)):
			$Instructions/Help.text = "两端通路已永久开启 · E / RB 拾取珍珠占位\n向左返回沟壑第二间 · 向右前往逃兵营帐"
		elif bool(data["events"].get(DEPTH_FAILED,false)):
			$Instructions/Help.text = "本次救助已放弃 · 清敌后永久开启两端通路\n向左可撤回 · 向右需先清敌"
		if rescue_expired(DEPTH_ID):
			$Instructions/Help.text = "救助已过期 · 清敌仍可永久开启通路\n两端已开启" if bool(data["events"].get(RavineDepthRoom.GATES,false)) else "救助已过期 · 清敌仍可永久开启通路\n向左可撤回 · 向右需先清敌"
		if _cleared() and not bool(data["events"].get(RavineDepthRoom.GATES,false)):
			$Instructions/Help.text = "结算尚未保存 · 按 E / RB 重试"

func interaction_targets() -> Array[Dictionary]:
	var result: Array[Dictionary] = super.interaction_targets()
	if has_session() and room is RavineDepthRoom and _cleared() and (not bool(data["events"].get(RavineDepthRoom.GATES,false)) or _depth_pending()):
		result.append(_target("depth:retry", "重试", "保存清敌结算", player.global_position, null, true,
			not get_tree().paused and not _world_dialogue_blocked() and player.life.is_alive(), true, "unlimited"))
	return result
