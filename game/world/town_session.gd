class_name TownSession
extends FieldSession
const TOWN_ID: String = "TY_10002_1"
const GAZE: String = "TY_10001_1_N005"
const SETTLEMENT: DialogueConfig = preload("res://data/world/seven_settlement.tres")
const TOWN_ROOMS: Dictionary = {
	START_ID: preload("res://world/rooms/hd_10001_1.tscn"),
	ENTRY_ID: preload("res://world/rooms/hd_10002_1.tscn"),
	TOWER_ID: preload("res://world/rooms/hd_10002_2.tscn"),
	EXPLORATION_ID: preload("res://world/rooms/hd_10002_3.tscn"),
	CONNECTION_ID: preload("res://world/rooms/hd_10003_1.tscn"),
	BOSS_ID: preload("res://world/rooms/hd_10004_1.tscn"),
	FIELD_ID: preload("res://world/rooms/ty_10001_1.tscn"),
	TOWN_ID: preload("res://world/rooms/ty_10002_1.tscn")
}
var _dialogue_kind: String = ""
var _gaze_active: bool = false
var _gaze_remaining: float = 0.0
var _gaze_dialogue_done: bool = false

func _room_scenes() -> Dictionary:
	return TOWN_ROOMS

func _near_survivor() -> bool:
	return room is TownRoom and player.position.distance_to((room.get_node("Survivor") as Node2D).position) <= (room as TownRoom).dialogue.interaction_radius

func _can_rescue() -> bool:
	return bool(data["events"].get(HEAL_GUIDE, false)) and not bool(data["events"].get(RESCUE_FAILED, false)) and not bool(data["events"].get(RESCUE_DONE, false))

func interact_survivor() -> bool:
	if not has_session() or get_tree().paused or not _near_survivor() or dialogue_ui.active or intro_active or not player.life.can_control() or player.combat.is_attacking() or player.possibility.busy():
		return false
	var config: DialogueConfig = (room as TownRoom).dialogue
	_dialogue_kind = "rescue" if _can_rescue() else "survivor"
	dialogue_ui.start(config, config.first_lines if _can_rescue() else (config.repeat_lines if bool(data["events"].get(RESCUE_DONE, false)) else config.failed_lines))
	return true

func interact_seven() -> bool:
	if has_session() and bool(data["events"].get(GAZE, false)):
		if not super.interact_seven():
			return false
		_dialogue_kind = "seven_done"
		dialogue_ui.start(SETTLEMENT, SETTLEMENT.repeat_lines)
		return true
	if not has_session() or not bool(data["events"].get(RESCUE_DONE, false)) or bool(data["events"].get(GAZE, false)):
		return super.interact_seven()
	if get_tree().paused or not _near_seven() or dialogue_ui.active or intro_active or not player.life.can_control() or player.combat.is_attacking() or player.possibility.busy():
		return false
	_dialogue_kind = "gaze"
	_gaze_active = true
	_gaze_remaining = SETTLEMENT.opening_duration
	_gaze_dialogue_done = false
	_forced_dialogue = true
	intro_active = true
	_field_opening = 0
	player.reset_kinematics()
	player.life.scripted_control_locked = true
	_story_hud(true)
	dialogue_ui.start(SETTLEMENT, SETTLEMENT.first_lines)
	return true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _gaze_active:
		_gaze_remaining = maxf(0, _gaze_remaining - delta)
		if room is FieldRoom:
			(room as FieldRoom).gaze_progress = 1.0 - _gaze_remaining / maxf(0.001, SETTLEMENT.opening_duration)
			(room as FieldRoom).gaze_target = player.position + Vector2(0, -44)
		if _gaze_dialogue_done and _gaze_remaining == 0:
			_commit_gaze()
		return
	if not room is TownRoom or not has_session():
		return
	if dialogue_ui.active:
		if not _near_survivor():
			_end_dialogue()
		return
	if _interaction_cooldown == 0 and Input.is_action_just_pressed("interact"):
		interact_survivor()

func _on_dialogue_finished() -> void:
	if not has_session() or get_tree().paused or not player.life.is_alive() or not dialogue_ui.active or dialogue_ui.confirming:
		return
	if _dialogue_kind == "gaze":
		_gaze_dialogue_done = true
		if _gaze_remaining == 0:
			_commit_gaze()
		return
	if _dialogue_kind == "rescue":
		_commit_rescue()
		return
	if _dialogue_kind in ["survivor", "seven_done"]:
		_end_dialogue()
		return
	super._on_dialogue_finished()

func _commit_rescue() -> bool:
	if not room is TownRoom or not _near_survivor() or not _can_rescue():
		return false
	var before: Dictionary = data["events"].duplicate()
	var old_balance: int = player.possibility.balance
	data["events"][RESCUE_DONE] = true
	_set_balance(mini(player.possibility.maximum, old_balance + 4))
	if not save_current("救助完成 · 返回7"):
		data["events"] = before
		_set_balance(old_balance)
		data["balance"] = old_balance
		return false
	var gained: int = player.possibility.balance - old_balance
	_end_dialogue()
	dialogue_ui.show_notice("救助完成 · 可能性 +%d · 返回7" % gained)
	ui.call("save_failed", "")
	return true

func _commit_gaze() -> bool:
	if not _gaze_active or not room is FieldRoom or not bool(data["events"].get(RESCUE_DONE, false)) or bool(data["events"].get(GAZE, false)):
		return false
	var before: Dictionary = data["events"].duplicate()
	var old_maximum: int = player.possibility.maximum
	data["events"][GAZE] = true
	data["events"][SEVEN] = true
	_set_maximum(12)
	if not save_current("已获得7的注视 · 可能性上限12"):
		data["events"] = before
		_set_maximum(old_maximum)
		data["maximum"] = old_maximum
		_gaze_dialogue_done = false
		return false
	_end_dialogue()
	dialogue_ui.show_notice("获得泥粪中的理想家的注视 · 可能性上限12")
	ui.call("save_failed", "")
	return true

func _set_maximum(value: int) -> void:
	_loading = true
	player.possibility.maximum = value
	player.possibility.balance_changed.emit(player.possibility.balance, value)
	_loading = false

func _end_dialogue() -> void:
	if room is FieldRoom:
		(room as FieldRoom).gaze_progress = -1
	_dialogue_kind = ""
	_gaze_active = false
	_gaze_remaining = 0
	_gaze_dialogue_done = false
	super._end_dialogue()

func _on_death() -> void:
	if room is TownRoom:
		_end_dialogue()
	super._on_death()

func _on_room_exit(target: String) -> void:
	if room is TownRoom:
		if not has_session() or get_tree().paused or intro_active or _transitioning or not player.life.can_control() or (target != room.config.previous_room_id and target != room.config.next_room_id):
			return
		_end_dialogue()
	super._on_room_exit(target)

func quest_status_text() -> String:
	if has_session() and bool(data["events"].get(GAZE, false)):
		return "已获得7的注视 · 可能性上限12"
	if has_session() and bool(data["events"].get(RESCUE_DONE, false)):
		return "救助完成：返回黄金麦湖与7交谈"
	return super.quest_status_text()

func _process(delta: float) -> void:
	super._process(delta)
	if room is FieldRoom and has_session() and bool(data["events"].get(RESCUE_DONE, false)) and not intro_active:
		$Instructions/Help.text = "E / RB 与7交谈 · 救助已完成，可往返田野与荒地" if bool(data["events"].get(GAZE, false)) else "E / RB 与7交谈，完成注视结算\n救助已完成，返回7领取你的成长"
	if room is TownRoom and has_session():
		var done: bool = bool(data["events"].get(RESCUE_DONE, false))
		var failed: bool = bool(data["events"].get(RESCUE_FAILED, false))
		(room as TownRoom).refresh_rescue(done, failed, _near_survivor() and not dialogue_ui.active)
		$Instructions/Title.text = "田野 / 麦秆镇"
		$Instructions/Help.text = "E / RB 与幸存者互动 · 救助后返回黄金麦湖寻找7\n向左返回麦田 · 向右探索前路"
