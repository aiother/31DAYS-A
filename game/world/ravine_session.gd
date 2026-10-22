class_name RavineSession
extends TownSession
const RAVINE_ID: String = "HD_20001_1"
const RAVINE_CHECKPOINT: String = "HD_20001_1_N001"
const RAVINE_ROOMS: Dictionary = {
	START_ID: preload("res://world/rooms/hd_10001_1.tscn"),
	ENTRY_ID: preload("res://world/rooms/hd_10002_1.tscn"),
	TOWER_ID: preload("res://world/rooms/hd_10002_2.tscn"),
	EXPLORATION_ID: preload("res://world/rooms/hd_10002_3.tscn"),
	CONNECTION_ID: preload("res://world/rooms/hd_10003_1.tscn"),
	BOSS_ID: preload("res://world/rooms/hd_10004_1.tscn"),
	FIELD_ID: preload("res://world/rooms/ty_10001_1.tscn"),
	TOWN_ID: preload("res://world/rooms/ty_10002_1.tscn"),
	RAVINE_ID: preload("res://world/rooms/hd_20001_1.tscn")
}

func _room_scenes() -> Dictionary:
	return RAVINE_ROOMS

func _supports_checkpoint(id: String) -> bool:
	return id == RAVINE_CHECKPOINT or super._supports_checkpoint(id)

func _checkpoint_room(id: String) -> String:
	return RAVINE_ID if id == RAVINE_CHECKPOINT else super._checkpoint_room(id)

func _restore(snapshot: Dictionary, revive: bool) -> void:
	var normalized: Dictionary = snapshot.duplicate(true)
	normalized["day"] = int(snapshot.get("day", 1))
	super._restore(normalized, revive)
	if room is RavineRoom and has_session():
		activate_checkpoint(RAVINE_CHECKPOINT)

func _change_room(target: String) -> void:
	super._change_room(target)
	if room is RavineRoom:
		activate_checkpoint(RAVINE_CHECKPOINT)

func activate_checkpoint(id: String) -> bool:
	if id != RAVINE_CHECKPOINT:
		return super.activate_checkpoint(id)
	if not has_session() or _loading or not player.life.is_alive() or _checkpoint(id) == null:
		return false
	var old_checkpoint: String = str(data["checkpoint"])
	var old_events: Dictionary = data["events"].duplicate()
	var old_day: int = int(data.get("day", 1))
	var old_time: float = DayClock.remaining(data)
	var next_day: int = maxi(old_day, 2) if bool(data["events"].get(FIELD_STORY, false)) else old_day
	if old_checkpoint == id and bool(data["events"].get(id, false)) and next_day == old_day:
		return false
	data["checkpoint"] = id
	data["events"][id] = true
	DayClock.advance_to(data,next_day)
	_update_flags()
	if not save_current("巢都入口检查点已记录"):
		data["checkpoint"] = old_checkpoint
		data["events"] = old_events
		data["day"] = old_day
		data["day3_remaining" if old_day==3 else "day_remaining"] = old_time
		_update_flags()
		return false
	ui.call("save_failed", "")
	if next_day > old_day:
		_announce_day(next_day)
	return true

func _announce_day(day: int) -> void:
	dialogue_ui.show_notice("第 %d 日"%day)

func _valid_departure_target(target: String) -> bool:
	return (room is TownRoom and target == RAVINE_ID) or super._valid_departure_target(target)

func _on_room_exit(target: String) -> void:
	if room is TownRoom and target == RAVINE_ID:
		if not has_session() or get_tree().paused or intro_active or _transitioning or not player.life.can_control() or dialogue_ui.confirming:
			return
		if not rescue_expired(TOWN_ID) and bool(data["events"].get(HEAL_GUIDE, false)) and not bool(data["events"].get(RESCUE_DONE, false)) and not bool(data["events"].get(RESCUE_FAILED, false)):
			_end_dialogue()
			_departure_target = target
			player.reset_kinematics()
			player.life.scripted_control_locked = true
			dialogue_ui.show_departure()
			return
	super._on_room_exit(target)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _interaction_input() and _checkpoint_retry_in_range(RAVINE_CHECKPOINT, room is RavineRoom):
		activate_checkpoint(RAVINE_CHECKPOINT)

func _process(delta: float) -> void:
	super._process(delta)
	$DayUI.visible = has_session() and not intro_active
	if has_session():
		$DayUI/Day.text = "第 %d 日" % int(data.get("day", 1))
	if room is RavineRoom:
		$Instructions/Help.text = "普通跳跃跨过高台 · 空中 S + J 下攻击\n向左返回麦秆镇 · 沿右侧平台继续探索"
		if has_session() and data["checkpoint"] != RAVINE_CHECKPOINT:
			$Instructions/Help.text = "入口检查点尚未保存 · 靠近旗帜按 E / RB 重试"

func interaction_targets() -> Array[Dictionary]:
	var result: Array[Dictionary] = super.interaction_targets()
	if has_session() and room is RavineRoom:
		result.append(_checkpoint_target(RAVINE_CHECKPOINT))
	return result
