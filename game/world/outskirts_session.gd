class_name OutskirtsSession
extends ParasiteSession
const OUTSKIRTS_ID: String = "NSZC_10001_1"
const OUTSKIRTS_ROOM: PackedScene = preload("res://world/rooms/nszc_10001_1.tscn")
const SPIKES_OPEN: String = "gate:NSZC_10001_1:spikes_cleared"
const OUTSKIRTS_HELPED: String = "rescue:NSZC_10001_1:completed"
const OUTSKIRTS_FAILED: String = "rescue:NSZC_10001_1:failed"
const OUTSKIRTS_SEEN: String = "rescue:NSZC_10001_1:seen"
var _spike_pending: bool = false
var _spike_paused: Array[Node] = []

func _room_scenes() -> Dictionary:
	var scenes: Dictionary = super._room_scenes().duplicate()
	scenes[OUTSKIRTS_ID] = OUTSKIRTS_ROOM
	return scenes

func _gaze_maximum() -> int:
	return super._gaze_maximum()+int(bool(data["events"].get(OUTSKIRTS_HELPED,false)))

func _bind_room() -> void:
	super._bind_room()
	if room is OutskirtsRoom:
		var area: OutskirtsRoom = room as OutskirtsRoom
		area.bind_player(player)
		if not area.challenge_passed.is_connected(_on_spikes_passed): area.challenge_passed.connect(_on_spikes_passed)
		if not area.challenge_failed.is_connected(_on_spikes_failed): area.challenge_failed.connect(_on_spikes_failed)
		_refresh_outskirts()

func _near_outskirts_survivor() -> bool:
	return room is OutskirtsRoom and bool(data.get("events",{}).get(SPIKES_OPEN,false)) and player.position.distance_to((room.get_node("Survivor") as Node2D).position)<=(room as OutskirtsRoom).challenge.interaction_radius

func _outskirts_pending() -> bool:
	return not rescue_expired(OUTSKIRTS_ID) and bool(data["events"].get(OUTSKIRTS_SEEN,false)) and not bool(data["events"].get(OUTSKIRTS_HELPED,false)) and not bool(data["events"].get(OUTSKIRTS_FAILED,false))

func _sees_outskirts_survivor() -> bool:
	return room is OutskirtsRoom and bool(data["events"].get(SPIKES_OPEN,false)) and Rect2(2326,752,442,128).has_point(player.position)

func _refresh_outskirts() -> void:
	if room is OutskirtsRoom:
		(room as OutskirtsRoom).refresh(bool(data.get("events",{}).get(SPIKES_OPEN,false)),bool(data.get("events",{}).get(OUTSKIRTS_HELPED,false)),bool(data.get("events",{}).get(OUTSKIRTS_FAILED,false)) or rescue_expired(OUTSKIRTS_ID),_near_outskirts_survivor() and not dialogue_ui.active)
		if rescue_expired(OUTSKIRTS_ID): (room.get_node("Survivor/Name") as Label).text = "外围幸存者 · 救助已过期"

func _stop_spike_motion() -> void:
	# Returning to the retry marker does not reset the global 1/2/3 dodge costs.
	var chain: int = player.possibility.chain
	var since: float = player.possibility.since_dodge
	player.reset_kinematics()
	player.possibility.chain = chain
	player.possibility.since_dodge = since

func _on_spikes_failed() -> void:
	if not has_session() or not player.life.is_alive() or not room is OutskirtsRoom: return
	player.possibility.cancel()
	player.combat.interrupt()
	player.life.take_hit((room as OutskirtsRoom).challenge.damage)
	if player.life.is_alive():
		player.position = (room as OutskirtsRoom).challenge.retry_position
		_stop_spike_motion()
		(room as OutskirtsRoom).reset_attempt()
		_notify("尖刺挑战失败 · 回到入口，可再次尝试")

func _on_spikes_passed() -> void:
	if not has_session() or not player.life.is_alive(): return
	_spike_pending = true
	intro_active = true
	_stop_spike_motion()
	player.life.scripted_control_locked = true
	player.set_physics_process(false)
	_spike_paused.clear()
	for actor: Node in room.get_node("Enemies").get_children():
		if actor.is_physics_processing():
			_spike_paused.append(actor)
			actor.set_physics_process(false)
	_try_open_spikes()

func _thaw_spikes() -> void:
	_spike_pending = false
	intro_active = false
	player.life.scripted_control_locked = false
	player.set_physics_process(true)
	for actor: Node in _spike_paused:
		if is_instance_valid(actor) and (not actor is ColorlessEntity or (actor as ColorlessEntity).health>0): actor.set_physics_process(true)
	_spike_paused.clear()
	if room is OutskirtsRoom: (room as OutskirtsRoom).pending_open = false

func _try_open_spikes() -> bool:
	var before: Dictionary = data["events"].duplicate()
	data["events"][SPIKES_OPEN] = true
	if not save_current("尖刺已永久关闭"):
		data["events"] = before
		_notify("挑战通过，保存尚未完成 · E / RB 重试")
		return false
	_thaw_spikes()
	_refresh_outskirts()
	ui.call("save_failed","")
	return true

func interact_outskirts_survivor() -> bool:
	if not _can_outskirts_survivor():
		return false
	if not bool(data["events"].get(OUTSKIRTS_SEEN,false)): record_event(OUTSKIRTS_SEEN)
	_dialogue_kind = "outskirts_rescue"
	var config: DialogueConfig = (room as OutskirtsRoom).dialogue
	dialogue_ui.start(config,PackedStringArray([rescue_expired_text()]) if rescue_expired(OUTSKIRTS_ID) else (config.first_lines if _outskirts_pending() else (config.repeat_lines if bool(data["events"].get(OUTSKIRTS_HELPED,false)) else config.failed_lines)))
	return true

func _on_dialogue_finished() -> void:
	if _dialogue_kind!="outskirts_rescue":
		super._on_dialogue_finished()
		return
	if get_tree().paused or not player.life.is_alive() or not dialogue_ui.active or dialogue_ui.confirming or not _near_outskirts_survivor(): return
	if not _outskirts_pending():
		_end_dialogue()
		return
	var before: Dictionary = data["events"].duplicate()
	var balance: int = player.possibility.balance
	var maximum: int = player.possibility.maximum
	data["events"][OUTSKIRTS_HELPED] = true
	if bool(data["events"].get(GAZE,false)): _set_maximum(_gaze_maximum())
	_set_balance(mini(player.possibility.maximum,balance+4))
	if not save_current("外围救助完成"):
		data["events"] = before
		_set_maximum(maximum)
		_set_balance(balance)
		data["maximum"] = maximum
		data["balance"] = balance
		return
	_end_dialogue()
	ui.call("save_failed","")
	dialogue_ui.show_notice("救助完成 · 可能性 +%d · 上限%d" % [player.possibility.balance-balance,player.possibility.maximum])
	_refresh_outskirts()

func _physics_process(delta: float) -> void:
	if _spike_pending:
		if Input.is_action_just_pressed("interact"): _try_open_spikes()
		return
	super._physics_process(delta)
	if not room is OutskirtsRoom or not has_session() or dialogue_ui.confirming: return
	if _sees_outskirts_survivor() and not bool(data["events"].get(OUTSKIRTS_SEEN,false)): record_event(OUTSKIRTS_SEEN)
	if dialogue_ui.active:
		if not _near_outskirts_survivor(): _end_dialogue()
	elif _interaction_cooldown==0 and _interaction_input():
		interact_outskirts_survivor()

func _on_room_exit(target: String) -> void:
	if room is OutskirtsRoom:
		if not has_session() or get_tree().paused or intro_active or _transitioning or not player.life.can_control() or dialogue_ui.confirming or (target!=room.config.previous_room_id and target!=room.config.next_room_id): return
		if _room_scenes().has(target) and _outskirts_pending():
			_end_dialogue()
			_departure_target = target
			player.reset_kinematics()
			player.life.scripted_control_locked = true
			dialogue_ui.show_departure()
			dialogue_ui.speaker.text = "外围幸存者"
			dialogue_ui.text.text = "这里还有人等待帮助。\n确认离开后，将永久失去这次外围救助机会。"
			return
		_end_dialogue()
	super._on_room_exit(target)

func confirm_departure() -> bool:
	if not room is OutskirtsRoom: return super.confirm_departure()
	if get_tree().paused or not player.life.is_alive() or not dialogue_ui.confirming or not _room_scenes().has(_departure_target) or (_departure_target!=room.config.previous_room_id and _departure_target!=room.config.next_room_id): return false
	var before: Dictionary = data["events"].duplicate()
	data["events"][OUTSKIRTS_FAILED] = true
	if not save_current("外围救助机会已永久放弃"):
		data["events"] = before
		return false
	var target: String = _departure_target
	_departure_target = ""
	_end_dialogue()
	ui.call("save_failed","")
	_transitioning = true
	_change_room.call_deferred(target)
	return true

func _on_death() -> void:
	if room is OutskirtsRoom:
		if _spike_pending: _thaw_spikes()
		_departure_target = ""
		_end_dialogue()
	super._on_death()

func quest_status_text() -> String:
	if room is OutskirtsRoom and has_session(): return _outskirts_quest_objective()
	return super.quest_status_text()

func _outskirts_quest_objective() -> String:
	if rescue_expired(OUTSKIRTS_ID): return "外围救助已过期 · 更早抵达可帮助这里的人"
	if bool(data["events"].get(OUTSKIRTS_HELPED,false)): return "外围救助已完成"+(" · 成长待首次注视结算" if not bool(data["events"].get(GAZE,false)) else " · 可能性上限%d" % player.possibility.maximum)
	if bool(data["events"].get(OUTSKIRTS_FAILED,false)): return "外围救助机会已永久失去"
	return "上层尖刺后有人等待帮助 · 强化闪避可通过"

func _rescue_objective(id: String) -> String:
	if id == OUTSKIRTS_ID: return _outskirts_quest_objective()
	return super._rescue_objective(id)

func _process(delta: float) -> void:
	super._process(delta)
	if room is OutskirtsRoom:
		$Instructions/Title.text = "逆时战场 / 战场外围"
		$Instructions/Help.text = "上层支路：一次强化闪避无伤穿过尖刺 · 建议至少1可能性\n失败回支路入口，可重试 · 主路可普通走跳往返"
		_refresh_outskirts()

func _can_outskirts_survivor() -> bool:
	return not _world_dialogue_blocked() and not (not has_session() or get_tree().paused or not _near_outskirts_survivor() or intro_active or dialogue_ui.active or not player.life.can_control() or player.combat.is_attacking() or player.possibility.busy())

func interaction_targets() -> Array[Dictionary]:
	var result: Array[Dictionary] = super.interaction_targets()
	if has_session() and room is OutskirtsRoom:
		var actor: Node2D = room.get_node("Survivor") as Node2D
		result.append(_target(room.config.room_id + ":Survivor", "交谈", "交谈", actor.global_position,
			(room as OutskirtsRoom).challenge.interaction_radius, _near_outskirts_survivor(), _interaction_cooldown == 0 and _can_outskirts_survivor()))
	if _spike_pending:
		for target: Dictionary in result: target["available"] = false
		var retry: Dictionary = _target("spikes:retry", "重试", "保存挑战结果", player.global_position, null, true, false, true, "unlimited")
		retry["retry_available"] = not get_tree().paused
		result.append(retry)
	return result
