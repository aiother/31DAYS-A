class_name FieldSession
extends BossSession
const FIELD_ID: String = "TY_10001_1"
const SEVEN: String = "TY_10001_1_N001"
const FIELD_STORY: String = "TY_10001_1_N002"
const HEAL_GUIDE: String = "TY_10001_1_N004"
const RESCUE_FAILED: String = "TY_10002_1_N002:failed"
const RESCUE_DONE: String = "TY_10002_1_N002:completed"
const FIELD_ROOMS: Dictionary = {
	START_ID: preload("res://world/rooms/hd_10001_1.tscn"),
	ENTRY_ID: preload("res://world/rooms/hd_10002_1.tscn"),
	TOWER_ID: preload("res://world/rooms/hd_10002_2.tscn"),
	EXPLORATION_ID: preload("res://world/rooms/hd_10002_3.tscn"),
	CONNECTION_ID: preload("res://world/rooms/hd_10003_1.tscn"),
	BOSS_ID: preload("res://world/rooms/hd_10004_1.tscn"),
	FIELD_ID: preload("res://world/rooms/ty_10001_1.tscn")
}
var _field_opening: float = 0.0
var _forced_dialogue: bool = false
var _interaction_cooldown: float = 0.0
var _guide_time: float = 0.0
var _departure_target: String = ""
var _field_camera_offset: float = 0.0
@onready var dialogue_ui: FieldDialogue = $FieldDialogue

func _room_scenes() -> Dictionary:
	return FIELD_ROOMS

func _ready() -> void:
	super._ready()
	dialogue_ui.finished.connect(_on_dialogue_finished)
	dialogue_ui.departure_cancelled.connect(cancel_departure)
	dialogue_ui.departure_confirmed.connect(confirm_departure)

func _change_room(target: String) -> void:
	super._change_room(target)
	if room is FieldRoom:
		_enter_field()

func _enter_field() -> void:
	if bool(data["events"].get(FIELD_STORY, false)):
		return
	_forced_dialogue = true
	intro_active = true
	_field_opening = (room as FieldRoom).dialogue.opening_duration
	var half_width: float = 960.0
	var limits: Rect2 = room.config.bounds
	var base_center: float = clampf(player.position.x, limits.position.x + half_width, limits.end.x - half_width)
	var npc_center: float = clampf((room.get_node("Seven") as Node2D).position.x, limits.position.x + half_width, limits.end.x - half_width)
	_field_camera_offset = npc_center - base_center
	player.reset_kinematics()
	player.life.scripted_control_locked = true
	_story_hud(true)

func _story_hud(hidden: bool) -> void:
	$Instructions.visible = not hidden
	(ui.get("_health") as Label).visible = not hidden

func _near_seven() -> bool:
	return room is FieldRoom and player.position.distance_to((room.get_node("Seven") as Node2D).position) <= (room as FieldRoom).dialogue.interaction_radius

func _physics_process(delta: float) -> void:
	_interaction_cooldown = maxf(0, _interaction_cooldown - delta)
	_guide_time = maxf(0, _guide_time - delta)
	if room is FieldRoom and _forced_dialogue:
		if _field_opening > 0:
			_field_opening = maxf(0, _field_opening - delta)
			var camera: Camera2D = player.get_node("Camera2D") as Camera2D
			camera.offset.x = move_toward(camera.offset.x, _field_camera_offset, 600 * delta)
			if _field_opening == 0:
				var config: DialogueConfig = (room as FieldRoom).dialogue
				dialogue_ui.start(config, config.first_lines)
		return
	super._physics_process(delta)
	if not room is FieldRoom or not has_session():
		return
	if dialogue_ui.active:
		if not dialogue_ui.confirming and not _near_seven():
			_end_dialogue()
		return
	if _interaction_cooldown == 0 and Input.is_action_just_pressed("interact"):
		interact_seven()

func interact_seven() -> bool:
	if get_tree().paused or not has_session() or not _near_seven() or dialogue_ui.active or intro_active or not player.life.can_control() or player.combat.is_attacking() or player.possibility.busy():
		return false
	var config: DialogueConfig = (room as FieldRoom).dialogue
	dialogue_ui.start(config, config.failed_lines if bool(data["events"].get(RESCUE_FAILED, false)) else config.repeat_lines)
	return true

func _on_dialogue_finished() -> void:
	if not has_session() or get_tree().paused or not player.life.is_alive() or not room is FieldRoom or not dialogue_ui.active or dialogue_ui.confirming:
		return
	var before: Dictionary = data["events"].duplicate()
	var old_balance: int = player.possibility.balance
	if _forced_dialogue:
		data["events"][FIELD_STORY] = true
		data["events"][HEAL_GUIDE] = true
		_set_balance(player.possibility.maximum)
	else:
		data["events"][SEVEN] = true
	if not save_current("黄金麦湖进度已保存"):
		data["events"] = before
		_set_balance(old_balance)
		data["balance"] = old_balance
		return
	if _forced_dialogue:
		_guide_time = 6.0
	_end_dialogue()
	ui.call("save_failed", "")

func _set_balance(value: int) -> void:
	_loading = true
	player.possibility.balance = value
	player.possibility.balance_changed.emit(value, player.possibility.maximum)
	_loading = false

func _end_dialogue() -> void:
	dialogue_ui.dismiss()
	_forced_dialogue = false
	intro_active = false
	_field_opening = 0
	_interaction_cooldown = 0.2
	player.life.scripted_control_locked = false
	(player.get_node("Camera2D") as Camera2D).offset = Vector2.ZERO
	_story_hud(false)

func _on_death() -> void:
	# Returning to the saved HD checkpoint through death/load is not voluntary abandonment.
	if room is FieldRoom:
		_departure_target = ""
		_end_dialogue()
	super._on_death()

func _on_room_exit(target: String) -> void:
	if room is FieldRoom:
		if not has_session() or get_tree().paused or intro_active or _transitioning or not player.life.can_control() or dialogue_ui.confirming:
			return
		if target != room.config.previous_room_id and target != room.config.next_room_id:
			return
		if target == BOSS_ID and bool(data["events"].get(HEAL_GUIDE, false)) and not bool(data["events"].get(RESCUE_FAILED, false)) and not bool(data["events"].get(RESCUE_DONE, false)):
			_end_dialogue()
			_departure_target = target
			player.reset_kinematics()
			player.life.scripted_control_locked = true
			dialogue_ui.show_departure()
			return
		_end_dialogue()
	super._on_room_exit(target)

func cancel_departure() -> void:
	if _departure_target.is_empty() or get_tree().paused:
		return
	_departure_target = ""
	_end_dialogue()

func confirm_departure() -> bool:
	if _departure_target != BOSS_ID or get_tree().paused or not player.life.is_alive() or not room is FieldRoom or not dialogue_ui.confirming:
		return false
	var before: Dictionary = data["events"].duplicate()
	data["events"][RESCUE_FAILED] = true
	if not save_current("救助机会已永久放弃"):
		data["events"] = before
		return false
	var target: String = _departure_target
	_departure_target = ""
	_end_dialogue()
	dialogue_ui.show_notice("已放弃救助 · 此次机会无法恢复")
	ui.call("save_failed", "")
	_transitioning = true
	_change_room.call_deferred(target)
	return true

func quest_status_text() -> String:
	if not has_session() or not bool(data["events"].get(HEAL_GUIDE, false)):
		return ""
	if bool(data["events"].get(RESCUE_FAILED, false)):
		return "救助机会已失去"
	if bool(data["events"].get(RESCUE_DONE, false)):
		return "已完成救助"
	return "救助：前往麦秆镇，寻找需要帮助的人"

func _process(delta: float) -> void:
	super._process(delta)
	if not has_session():
		return
	dialogue_ui.quest.text = quest_status_text()
	dialogue_ui.quest.visible = not _forced_dialogue
	if room is FieldRoom:
		var field: FieldRoom = room as FieldRoom
		$Instructions/Title.text = "田野 / " + field.config.display_name
		field.player_position = player.position
		(room.get_node("Seven/Prompt") as Label).visible = _near_seven() and not dialogue_ui.active and not intro_active
		(room.get_node("Seven/Prompt") as Label).position.x = -184 if player.position.x < 1728 else 64
		$Instructions/Help.text = "E / RB 与7交谈 · 向右前往麦秆镇\n返回荒地将失去本次救助机会"
		if _guide_time > 0:
			$Instructions/Help.text = "长按 L / Y 恢复生命 · 消耗3可能性，持续2.8秒恢复2生命\n松键或被打断会取消恢复，已消耗的可能性不退还"
