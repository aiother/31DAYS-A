class_name RavineRescueSession
extends RavineSession
const RESCUE_ID: String = "HD_20001_2"
const HELPED: String = "rescue:HD_20001_2:completed"
const FAILED: String = "rescue:HD_20001_2:failed"
const SEEN: String = "rescue:HD_20001_2:seen"
const RESCUE_ROOM: PackedScene = preload("res://world/rooms/hd_20001_2.tscn")

func _room_scenes() -> Dictionary:
	var scenes: Dictionary = super._room_scenes().duplicate()
	scenes[RESCUE_ID] = RESCUE_ROOM
	return scenes

func _gaze_maximum() -> int:
	return 13 if bool(data["events"].get(HELPED, false)) else 12

func _near_ravine_survivor() -> bool:
	return room is RavineRescueRoom and player.position.distance_to((room.get_node("Survivor") as Node2D).position) <= (room as RavineRescueRoom).dialogue.interaction_radius

func _rescue_pending() -> bool:
	return bool(data["events"].get(SEEN, false)) and not bool(data["events"].get(HELPED, false)) and not bool(data["events"].get(FAILED, false))

func _on_encounter() -> void:
	if room is RavineRescueRoom and has_session():
		if not bool(data["events"].get(SEEN, false)):
			record_event(SEEN)
		return
	super._on_encounter()

func interact_ravine_survivor() -> bool:
	if not has_session() or get_tree().paused or not _near_ravine_survivor() or dialogue_ui.active or intro_active or not player.life.can_control() or player.combat.is_attacking() or player.possibility.busy():
		return false
	data["events"][SEEN] = true
	var config: DialogueConfig = (room as RavineRescueRoom).dialogue
	_dialogue_kind = "ravine_rescue"
	dialogue_ui.start(config, config.first_lines if _rescue_pending() else (config.repeat_lines if bool(data["events"].get(HELPED, false)) else config.failed_lines))
	return true

func _on_dialogue_finished() -> void:
	if _dialogue_kind != "ravine_rescue":
		super._on_dialogue_finished()
		return
	if get_tree().paused or not player.life.is_alive() or not dialogue_ui.active or dialogue_ui.confirming or not _near_ravine_survivor():
		return
	if not _rescue_pending():
		_end_dialogue()
		return
	var before: Dictionary = data["events"].duplicate()
	var balance: int = player.possibility.balance
	var maximum: int = player.possibility.maximum
	data["events"][HELPED] = true
	if bool(data["events"].get(GAZE, false)):
		_set_maximum(_gaze_maximum())
	_set_balance(mini(player.possibility.maximum, balance + 4))
	if not save_current("沟壑救助已完成"):
		data["events"] = before
		_set_maximum(maximum)
		_set_balance(balance)
		data["maximum"] = maximum
		data["balance"] = balance
		return
	_end_dialogue()
	ui.call("save_failed", "")
	dialogue_ui.show_notice("救助完成 · 可能性 +%d · 上限%d" % [player.possibility.balance - balance, player.possibility.maximum])

func _on_room_exit(target: String) -> void:
	if room is RavineRescueRoom:
		if not has_session() or get_tree().paused or intro_active or _transitioning or not player.life.can_control() or dialogue_ui.confirming or (target != room.config.previous_room_id and target != room.config.next_room_id):
			return
		# A future Room boundary is not an actual departure.
		if _room_scenes().has(target) and _rescue_pending():
			_end_dialogue()
			_departure_target = target
			player.reset_kinematics()
			player.life.scripted_control_locked = true
			dialogue_ui.show_departure()
			dialogue_ui.speaker.text = "沟壑幸存者"
			dialogue_ui.text.text = "这里还有人等待帮助。\n确认离开后，将永久失去这次沟壑救助机会。"
			return
		_end_dialogue()
	super._on_room_exit(target)

func confirm_departure() -> bool:
	if not room is RavineRescueRoom:
		return super.confirm_departure()
	if get_tree().paused or not player.life.is_alive() or not dialogue_ui.confirming or not _room_scenes().has(_departure_target) or (_departure_target != room.config.previous_room_id and _departure_target != room.config.next_room_id):
		return false
	var before: Dictionary = data["events"].duplicate()
	data["events"][FAILED] = true
	if not save_current("沟壑救助机会已永久放弃"):
		data["events"] = before
		return false
	var target: String = _departure_target
	_departure_target = ""
	_end_dialogue()
	ui.call("save_failed", "")
	_transitioning = true
	_change_room.call_deferred(target)
	return true

func _on_death() -> void:
	if room is RavineRescueRoom:
		_end_dialogue()
	super._on_death()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not room is RavineRescueRoom or not has_session() or dialogue_ui.confirming:
		return
	if dialogue_ui.active:
		if not _near_ravine_survivor():
			_end_dialogue()
		return
	if _interaction_cooldown == 0 and Input.is_action_just_pressed("interact"):
		interact_ravine_survivor()

func quest_status_text() -> String:
	if room is RavineRescueRoom and has_session():
		if bool(data["events"].get(HELPED, false)):
			return "沟壑救助已完成" + (" · 成长已记录，获得7的注视后结算" if not bool(data["events"].get(GAZE, false)) else " · 可能性上限13")
		if bool(data["events"].get(FAILED, false)):
			return "沟壑救助机会已永久失去"
		return "上层有人等待救助 · E / RB 互动"
	return super.quest_status_text()

func _process(delta: float) -> void:
	super._process(delta)
	if room is RavineRescueRoom and has_session():
		(room as RavineRescueRoom).refresh_rescue(bool(data["events"].get(HELPED, false)), bool(data["events"].get(FAILED, false)), _near_ravine_survivor() and not dialogue_ui.active)
		$Instructions/Help.text = "沿平台向上寻找幸存者 · E / RB 救助\n向左返回入口 · 向右继续探索"
		dialogue_ui.quest.text = quest_status_text()
