class_name RescueBattlefieldSession
extends BattlefieldSession
const RESCUE_DONE_EVENT: String = "NSZC_10003_1_N002"
const TEN_RESCUE_ROOM: PackedScene = preload("res://world/rooms/rescue_battlefield.tscn")
const RESCUE_DIALOGUE: DialogueConfig = preload("res://data/dialogue/ten_rescue.tres")
enum Cinematic { NONE, DROP, DIALOGUE, SLASH, SAVE }
var cinematic: Cinematic = Cinematic.NONE
var cinematic_remaining: float = 0
var _rescue_commit_pending: bool = false
@onready var rescue_overlay: RescueOverlay = $RescueOverlay

func _room_scenes() -> Dictionary:
	var scenes: Dictionary = super._room_scenes().duplicate()
	scenes[BATTLEFIELD_ID] = TEN_RESCUE_ROOM
	return scenes

func _arena() -> RescueBattlefieldRoom:
	return room as RescueBattlefieldRoom

func _bind_room() -> void:
	super._bind_room()
	player.life.hit_interceptor = Callable()
	var area: RescueBattlefieldRoom = _arena()
	if area!=null:
		area.rescue_done = bool(data.get("events",{}).get(RESCUE_DONE_EVENT,false))
		player.life.hit_interceptor = _intercept_hit
		if not area.rescue_requested.is_connected(_begin_rescue):
			area.rescue_requested.connect(_begin_rescue)
		if not area.hostile_spawned.is_connected(_bind_hostile):
			area.hostile_spawned.connect(_bind_hostile)

func _bind_hostile(enemy: ColorlessEntity) -> void:
	if not enemy.defeated.is_connected(_on_room_enemy_defeated):
		enemy.defeated.connect(_on_room_enemy_defeated)

func _intercept_hit(amount: int) -> bool:
	var area: RescueBattlefieldRoom = _arena()
	if area==null or not has_session():
		return false
	if cinematic!=Cinematic.NONE:
		return true
	if not area.rescue_done and area.started and amount>=player.life.health:
		_begin_rescue("lethal")
		return true
	return false

func _begin_rescue(reason: String) -> void:
	var area: RescueBattlefieldRoom = _arena()
	if area==null or area.rescue_done or cinematic!=Cinematic.NONE or not has_session() or not player.life.is_alive():
		return
	area.begin_rescue(reason)
	intro_active = true
	player.reset_kinematics()
	player.life.scripted_control_locked = true
	player.set_physics_process(false)
	ui.call("hide_enemy_intro")
	_story_hud(true)
	rescue_overlay.show_drop()
	cinematic = Cinematic.DROP
	cinematic_remaining = RESCUE_DIALOGUE.opening_duration
	area.ten.position.y = 160

func _physics_process(delta: float) -> void:
	if cinematic!=Cinematic.NONE:
		if cinematic==Cinematic.DROP:
			cinematic_remaining = maxf(0,cinematic_remaining-delta)
			_arena().ten.position.y = lerpf(160,896,1-cinematic_remaining/RESCUE_DIALOGUE.opening_duration)
			if cinematic_remaining==0:
				cinematic = Cinematic.DIALOGUE
				dialogue_ui.start(RESCUE_DIALOGUE,RESCUE_DIALOGUE.first_lines)
		elif cinematic==Cinematic.SLASH:
			cinematic_remaining = maxf(0,cinematic_remaining-delta)
			if cinematic_remaining==0:
				cinematic = Cinematic.SAVE
				_rescue_commit_pending = true
				_finish_rescue()
		elif cinematic==Cinematic.SAVE and (Input.is_action_just_pressed("interact") or bool(data["events"].get(RESCUE_DONE_EVENT,false))):
			_finish_rescue()
		return
	super._physics_process(delta)

func _on_dialogue_finished() -> void:
	if cinematic!=Cinematic.DIALOGUE:
		super._on_dialogue_finished()
		return
	if get_tree().paused:
		return
	dialogue_ui.dismiss()
	cinematic = Cinematic.SLASH
	cinematic_remaining = 0.35
	rescue_overlay.show_slash()
	_arena().clear_hostiles()

func _on_room_enemy_defeated(reward: int) -> void:
	# Cinematic enemies are replaced by the single full-cap reward transaction.
	if cinematic!=Cinematic.NONE:
		return
	super._on_room_enemy_defeated(reward)

func save_current(message: String = "已自动保存") -> bool:
	if not _rescue_commit_pending:
		return super.save_current(message)
	var before: Dictionary = data["events"].duplicate()
	var old_balance: int = player.possibility.balance
	data["events"][RESCUE_DONE_EVENT] = true
	_set_balance(player.possibility.maximum)
	if not super.save_current(message):
		data["events"] = before
		_set_balance(old_balance)
		data["balance"] = old_balance
		return false
	_rescue_commit_pending = false
	return true

func _finish_rescue() -> void:
	if not save_current("10救场完成 · 可能性已补满"):
		rescue_overlay.show_save_retry()
		return
	cinematic = Cinematic.NONE
	intro_active = false
	rescue_overlay.hide()
	_story_hud(false)
	player.life.scripted_control_locked = false
	player.set_physics_process(true)
	_arena().start_coop()
	ui.call("save_failed","")

func _on_stage_completed() -> void:
	var area: RescueBattlefieldRoom = _arena()
	if area==null:
		super._on_stage_completed()
		return
	if area.phase==RescueBattlefieldRoom.Phase.OPENING:
		area.replace_wave()
		_begin_rescue("second_wave")
	elif area.phase==RescueBattlefieldRoom.Phase.COOP and not stage_notified and save_current("10协同测试已完成 · 当前资源已保存"):
		stage_notified = true
		area.get_node("StageLabel").text = "中心战场 · 10协同阶段完成\n最终波次、计时与结局待下一阶段\n返回通路尚未开启"
		ui.call("save_failed","")
		ui.call("show_enemy_intro",6.0,"中心战场 · 10协同阶段完成\n\n最终波次、15分钟时限与结局将在下一阶段接入。\n本提示不代表最终胜利。")

func _process(delta: float) -> void:
	var seconds: float = float(data.get("play_seconds",0))
	super._process(delta)
	if cinematic!=Cinematic.NONE and has_session():
		data["play_seconds"] = seconds
	if _arena()!=null:
		$Instructions/Title.text = "逆时战场 / 中心战场 · 10救场与协同"
		$Instructions/Help.text = "10首次救场：致命伤 / 两名幸存者全部倒下 / 第二波兜底\n救场补满可能性、不回血 · 协同清空仅为阶段完成 · 沿用堑壕第二间检查点"
