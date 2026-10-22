class_name FinalBattleSession
extends RescueBattlefieldSession
signal day_changed(day: int)
const FINAL_ROOM: PackedScene = preload("res://world/rooms/final_battlefield.tscn")
const FINAL_DIALOGUE: DialogueConfig = preload("res://data/dialogue/ten_victory.tres")
var _start_pending: bool = false
var _win_pending: bool = false
var _timeout_pending: bool = false
var _timeout_active: bool = false
var _final_resolution_room: int = 0
var _ending_pending: bool = false
var _ending_active: bool = false
var _ending_remaining: float = 0
var _ending_attempted: bool = false
var _final_talk: bool = false
var _clock_save_remaining: float = 0.5
var _exploration_timeout: bool = false
var _announced_day: int = 0
# Presentation-only history: deliberately unknown after loading existing saves.
var _ui_day: int = 0
var _final_start_day3_remaining: float = -1.0
@onready var final_ui: FinalBattleUI = $FinalBattleUI

func _ready() -> void:
	super._ready()
	process_physics_priority = -20
	final_ui.retry_requested.connect(retry_final_battle)
	final_ui.quit_requested.connect(_final_quit)
	final_ui.slots_requested.connect(func() -> void: ui.call("show_slots"))

func _room_scenes() -> Dictionary:
	var scenes: Dictionary = super._room_scenes().duplicate()
	scenes[BATTLEFIELD_ID] = FINAL_ROOM
	return scenes

func _final_arena() -> FinalBattlefieldRoom:
	return room as FinalBattlefieldRoom

func _restore(snapshot: Dictionary, revive: bool) -> void:
	_final_resolution_room = 0
	_final_start_day3_remaining = -1.0
	var normalized: Dictionary = snapshot.duplicate(true)
	DayClock.normalize(normalized)
	super._restore(normalized,revive)
	FinalClock.normalize(data)
	_announced_day = int(data.get("day",1))
	_publish_ui_day(_announced_day)
	if bool(data["events"].get(FinalClock.END,false)):
		_show_finished()
	elif bool(data["events"].get(FinalClock.TALK,false)):
		_begin_ending()
	elif bool(data["events"].get(FinalClock.TIMEOUT,false)):
		_show_timeout()
	elif bool(data["events"].get(DayClock.TIMEOUT,false)) or DayClock.expired(data):
		_expire_day()

func _bind_room() -> void:
	super._bind_room()
	var area: FinalBattlefieldRoom = _final_arena()
	if area!=null:
		if not area.battle_started.is_connected(_on_final_started):
			area.battle_started.connect(_on_final_started)
		if not area.wave_changed.is_connected(_on_wave_changed):
			area.wave_changed.connect(_on_wave_changed)
		if bool(data.get("events",{}).get(FinalClock.WON,false)):
			area.set_victory()

func _on_wave_changed(index: int) -> void:
	ui.call("show_enemy_intro",1.0,"敌方第%d波即将进入\n\n最后一波会有幸存者与平台支援。" % [index+1])

func _on_final_started() -> void:
	if bool(data["events"].get(FinalClock.STARTED,false)):
		return
	_start_pending = true
	_final_arena().stop_attempt()
	player.life.scripted_control_locked = true
	player.set_physics_process(false)
	intro_active = true
	_try_start_clock()

func _try_start_clock() -> bool:
	var before: Dictionary = data.duplicate(true)
	var starting_day3: float = float(data.get("day3_remaining",1800.0))
	FinalClock.start(data)
	if not save_current("最终战计时已保存"):
		data = before
		_notify("计时尚未保存 · E / RB 重试")
		return false
	_start_pending = false
	_final_start_day3_remaining = starting_day3
	intro_active = false
	player.life.scripted_control_locked = false
	player.set_physics_process(true)
	var area: FinalBattlefieldRoom = _final_arena()
	area.stopped = false
	for child: Node in area.get_node("Enemies").get_children():
		if child is ColorlessEntity and (child as ColorlessEntity).health>0:
			child.set_physics_process(true)
	for child: Node in area.get_node("Allies").get_children():
		if (child as SurvivorFighter).health>0:
			child.set_physics_process(true)
	ui.call("save_failed","")
	return true

func _clock_tick(delta: float) -> void:
	if get_tree().paused or not has_session() or _loading or _reloading or _transitioning or not player.life.is_alive() or intro_active or dialogue_ui.active or dialogue_ui.confirming or cinematic!=Cinematic.NONE or _start_pending or _win_pending or _timeout_active or _ending_active or _final_talk or bool(data["events"].get(FinalClock.WON,false)):
		return
	var elapsed: Dictionary = DayClock.tick(data,delta)
	if FinalClock.tick(data,float(elapsed["third_delta"])):
		_queue_final_resolution()
		return
	if DayClock.expired(data):
		_expire_day()
		return
	_clock_save_remaining -= delta
	if not (elapsed["days"] as Array).is_empty() or _clock_save_remaining<=0:
		_clock_save_remaining = DayClock.CONFIG.save_interval
		save_current("日期与剩余时间已保存" if not (elapsed["days"] as Array).is_empty() else "计时已保存")

func _expire_day() -> void:
	data["events"][DayClock.TIMEOUT] = true
	save_current("第三日探索时间已耗尽")
	_show_timeout(true)

func blocks_resume() -> bool:
	return _timeout_active or bool(data.get("events",{}).get(FinalClock.END,false))

# UI-002: the formal HUD shows the banner from day_changed.
func _announce_day(day: int) -> void:
	_announced_day = day
	_publish_ui_day(day)

func _publish_ui_day(day: int) -> void:
	if day != _ui_day:
		_ui_day = day
		day_changed.emit(day)

func ui_time_state() -> Dictionary:
	# Detached values only; never normalize, tick, save or drive a presentation.
	var active: bool = has_session()
	var day: int = int(data.get("day",1)) if active else 0
	var remaining: float = DayClock.remaining(data) if active else 0.0
	var events: Dictionary = data.get("events",{})
	var started: bool = active and bool(events.get(FinalClock.STARTED,false))
	var final_active: bool = started and not bool(events.get(FinalClock.WON,false)) and not bool(events.get(FinalClock.TIMEOUT,false)) and not bool(events.get(FinalClock.END,false))
	var warning: bool = active and day < 3 and remaining > 0.0 and remaining <= 180.0
	return {
		"has_session":active, "day":day, "day_remaining":remaining,
		"day_warning":warning, "day_warning_remaining":remaining if warning else 0.0,
		"day_progress":clampf(1.0 - remaining / DayClock.CONFIG.day_seconds,0.0,1.0) if active else 0.0,
		"final_started":started, "final_active":final_active,
		"final_remaining":float(data.get("final_remaining",900.0)) if started else 0.0,
		"final_start_known":_final_start_day3_remaining >= 0.0,
		"final_start_day3_remaining":_final_start_day3_remaining,
		"final_acceleration":final_active and _final_start_day3_remaining > 900.0,
	}

func _physics_process(delta: float) -> void:
	if _final_talk:
		return
	if _ending_active:
		_ending_remaining = maxf(0,_ending_remaining-delta)
		if _ending_remaining>0:
			final_ui.show_ending(1-_ending_remaining/3.0)
		if _ending_remaining==0:
			if not _ending_attempted or Input.is_action_just_pressed("interact"):
				_ending_attempted = true
				_ending_pending = true
				if not save_current("V0.1结局已保存"):
					final_ui.message.text = "结局保存失败 · E / RB 重试"
			if bool(data["events"].get(FinalClock.END,false)):
				_show_finished()
		return
	if _start_pending:
		if Input.is_action_just_pressed("interact"):
			_try_start_clock()
		return
	_clock_tick(delta)
	if _timeout_active:
		return
	super._physics_process(delta)
	var area: FinalBattlefieldRoom = _final_arena()
	if area!=null and bool(data["events"].get(FinalClock.WON,false)):
		if not area.victory:
			area.set_victory()
		if _interaction_input() and _can_final_conversation():
			_final_talk = true
			intro_active = true
			player.life.scripted_control_locked = true
			player.set_physics_process(false)
			_story_hud(true)
			ui.call("hide_enemy_intro")
			dialogue_ui.start(FINAL_DIALOGUE,FINAL_DIALOGUE.first_lines)

func _on_stage_completed() -> void:
	var area: FinalBattlefieldRoom = _final_arena()
	if area==null or area.phase!=RescueBattlefieldRoom.Phase.COOP:
		super._on_stage_completed()
		return
	if _timeout_active or bool(data["events"].get(FinalClock.TIMEOUT,false)) or bool(data["events"].get(FinalClock.WON,false)):
		return
	_queue_final_resolution()

func _queue_final_resolution() -> void:
	if _final_resolution_room!=0:
		return
	_final_resolution_room = room.get_instance_id()
	_resolve_final_frame.call_deferred(_final_resolution_room)

func _resolve_final_frame(room_id: int) -> void:
	if _final_resolution_room!=room_id:
		return
	_final_resolution_room = 0
	if not has_session() or room.get_instance_id()!=room_id or _timeout_active or bool(data["events"].get(FinalClock.TIMEOUT,false)) or bool(data["events"].get(FinalClock.WON,false)):
		return
	var area: FinalBattlefieldRoom = _final_arena()
	# Settle after this physics frame's actors: the Room (-10) may have checked
	# before the final enemy (0) died. Only the last complete wave can beat zero.
	if area!=null and area.phase==RescueBattlefieldRoom.Phase.COOP and area.wave_state!=FinalBattlefieldRoom.WaveState.WARNING and area.wave_index==area.battle.tian_counts.size()-1 and area.arrivals==2 and _wave_is_clear(area):
		area.completed = true
		area.wave_state = FinalBattlefieldRoom.WaveState.COMPLETE
		area.stop_attempt()
		_timeout_pending = false
		_win_pending = true
		if save_current("最终战胜利 · 靠近10对话"):
			area.set_victory()
		else:
			_notify("胜利尚未保存 · E / RB 重试")
	elif float(data.get("final_remaining",900))<=0 or float(data.get("day3_remaining",1800))<=0:
		_timeout_pending = true
		save_current("最终战超时")
		_show_timeout()
	elif area!=null and area.completed:
		area.advance_wave()

func _wave_is_clear(area: FinalBattlefieldRoom) -> bool:
	for child: Node in area.get_node("Enemies").get_children():
		if child is ColorlessEntity and (child as ColorlessEntity).health>0:
			return false
	return true

func save_current(message: String = "已自动保存") -> bool:
	var before: Dictionary = data.get("events",{}).duplicate()
	if _win_pending:
		data["events"][FinalClock.WON] = true
		data["events"].erase(FinalClock.TIMEOUT)
	if _timeout_pending:
		data["events"][FinalClock.TIMEOUT] = true
	if _ending_pending:
		data["events"][FinalClock.END] = true
	if not super.save_current(message):
		if has_session():
			data["events"] = before
		return false
	_win_pending = false
	_timeout_pending = false
	_ending_pending = false
	return true

func _show_timeout(exploration: bool = false) -> void:
	_timeout_active = true
	_exploration_timeout = exploration
	ui.call("hide_enemy_intro")
	if _final_arena()!=null:
		_final_arena().stop_attempt()
	player.life.scripted_control_locked = true
	if exploration:
		final_ui.show_day_timeout()
	else:
		final_ui.show_timeout(float(data.get("final_budget",0))>0,float(data.get("final_budget",0)))
	get_tree().paused = true

func retry_final_battle() -> bool:
	if _timeout_active and _exploration_timeout:
		return _retry_exploration()
	if not _timeout_active or float(data.get("final_budget",0))<=0:
		return false
	var before: Dictionary = data.duplicate(true)
	var pending: bool = _timeout_pending
	_timeout_pending = false
	FinalClock.retry(data)
	if not save_current("最终战重试预算已保存"):
		data = before
		_timeout_pending = pending
		return false
	_timeout_active = false
	final_ui.reset_panel()
	ui.call("save_failed","")
	get_tree().paused = false
	_restore(data.duplicate(true),false)
	_change_room(BATTLEFIELD_ID)
	return true

func _retry_exploration() -> bool:
	var before: Dictionary = data.duplicate(true)
	DayClock.retry(data)
	if not save_current("第三日探索重试已保存"):
		data = before
		return false
	_timeout_active = false
	_exploration_timeout = false
	final_ui.reset_panel()
	ui.call("save_failed","")
	get_tree().paused = false
	_queue_reload(slot,data,false)
	return true

func _on_dialogue_finished() -> void:
	if not _final_talk:
		super._on_dialogue_finished()
		return
	if get_tree().paused:
		return
	data["events"][FinalClock.TALK] = true
	if not save_current("胜利对话已完成"):
		data["events"].erase(FinalClock.TALK)
		return
	dialogue_ui.dismiss()
	_final_talk = false
	_begin_ending()

func _begin_ending() -> void:
	ui.call("save_failed","")
	_ending_active = true
	_ending_remaining = 3
	_ending_attempted = false
	intro_active = true
	player.life.scripted_control_locked = true
	player.set_physics_process(false)
	_story_hud(true)
	final_ui.show_ending(0)

func _show_finished() -> void:
	ui.call("save_failed","")
	_ending_active = false
	player.life.scripted_control_locked = true
	player.set_physics_process(false)
	_story_hud(true)
	if final_ui.mode!="finished":
		final_ui.show_finished()
	get_tree().paused = true

func _final_quit() -> void:
	if save_current():
		get_tree().paused = false
		get_tree().quit()

func _on_room_exit(id: String) -> void:
	if _final_arena()!=null and bool(data["events"].get(FinalClock.WON,false)) and id==room.config.previous_room_id:
		if not _transitioning and player.life.can_control() and save_current("正在返回堑壕"):
			_transitioning = true
			_change_room.call_deferred(id)
		return
	super._on_room_exit(id)

func _process(delta: float) -> void:
	super._process(delta)
	$DayUI.visible = false
	if has_session():
		var day: int = int(data.get("day",1))
		if _announced_day!=0 and _announced_day!=day:
			_announce_day(day)
		_announced_day = day
		if bool(data["events"].get(FinalClock.END,false)):
			_show_finished()
	if _final_arena()!=null:
		$Instructions/Title.text = "逆时战场 / 中心战场 · 最终战"
		$Instructions/Help.text = "三波敌军 · 最后一波幸存者与平台支援 · 击杀恢复可能性\n计时暂停于菜单和剧情；死亡/读档不回补 · 最终胜利后与10对话"

func _can_final_conversation() -> bool:
	var area: FinalBattlefieldRoom = _final_arena()
	return area != null and has_session() and bool(data["events"].get(FinalClock.WON,false)) and not _final_talk and not _world_dialogue_blocked() and player.life.can_control() and player.position.distance_to(area.ten.position) <= 110

func interaction_targets() -> Array[Dictionary]:
	var result: Array[Dictionary] = super.interaction_targets()
	var area: FinalBattlefieldRoom = _final_arena()
	if area != null and has_session() and bool(data["events"].get(FinalClock.WON,false)):
		result.append(_target("ten:victory", "交谈", "交谈", area.ten.global_position, 110.0,
			player.position.distance_to(area.ten.position) <= 110, not get_tree().paused and _can_final_conversation()))
	var supplement: String = DODGE_GROWTH if _needs_dodge_growth() else (COMBAT_GROWTH if _needs_combat_growth() else "")
	if not supplement.is_empty():
		for target: Dictionary in result:
			if target["id"] != supplement: target["available"] = false
	if _final_talk or _timeout_active or _ending_active or _start_pending or cinematic != Cinematic.NONE:
		for target: Dictionary in result: target["available"] = false
	# Save retries during deliberate settlement locks remain usable by their existing
	# raw E/RB paths, but are not offered as available world objects during a lock.
	var retry: String = ""
	if _start_pending: retry = "final:start"
	elif _ending_active and _ending_remaining == 0 and not bool(data["events"].get(FinalClock.END,false)): retry = "final:ending"
	elif cinematic == Cinematic.SAVE: retry = "rescue:save"
	if not retry.is_empty():
		var target: Dictionary = _target(retry, "重试", "重试保存", player.global_position, null, true, false, true, "unlimited")
		target["retry_available"] = not get_tree().paused
		result.append(target)
	return result

func _stage_retry_pending() -> bool:
	if _timeout_active or bool(data.get("events",{}).get(FinalClock.TIMEOUT,false)) or bool(data.get("events",{}).get(FinalClock.WON,false)): return false
	return super._stage_retry_pending()
