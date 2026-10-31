class_name ParasiteSession
extends CampWavesSession
const PARASITE_ID: String = "HD_20003_1"
const PARASITE_CHECKPOINT: String = "HD_20003_1_N003"
const PARASITE_INTRO: String = "HD_20003_1_N001:intro"
const PARASITE_DEFEATED: String = "HD_20003_1_N001:defeated"
const PARASITE_PASSAGE: String = "HD_20003_1_N002"
const DODGE_PENDING: String = "HD_20003_1:dodge_growth_pending"
const DODGE_GROWTH: String = "HD_20003_1:dodge_growth_claimed"
const PARASITE_ROOM: PackedScene = preload("res://world/rooms/hd_20003_1.tscn")
var _parasite_intro_remaining: float:
	get: return cinematics.remaining(&"boss.parasite")
	set(value): cinematics.duration(&"boss.parasite", value)
var _parasite_victory_pending: bool = false

func gameplay_camera_state() -> Dictionary:
	var state: Dictionary = super.gameplay_camera_state()
	if room is ParasiteRoom and has_session() and player.life.is_alive():
		var actor: ParasiteBoss = room.get_node("Boss") as ParasiteBoss
		state["battle"] = actor.state not in [ParasiteBoss.State.WAITING, ParasiteBoss.State.DEAD]
		state["focus"] = actor.global_position
	return state

func _room_scenes() -> Dictionary:
	var scenes: Dictionary = super._room_scenes().duplicate()
	scenes[PARASITE_ID] = PARASITE_ROOM
	return scenes

func _supports_checkpoint(id: String) -> bool:
	return id == PARASITE_CHECKPOINT or super._supports_checkpoint(id)

func _checkpoint_room(id: String) -> String:
	return PARASITE_ID if id == PARASITE_CHECKPOINT else super._checkpoint_room(id)

func _bind_room() -> void:
	super._bind_room()
	if room is ParasiteRoom:
		var actor: ParasiteBoss = room.get_node("Boss") as ParasiteBoss
		actor.target = player
		if not actor.defeated.is_connected(_on_parasite_defeated):
			actor.defeated.connect(_on_parasite_defeated)
		if not (room as ParasiteRoom).support_spawned.is_connected(_on_parasite_support_spawned):
			(room as ParasiteRoom).support_spawned.connect(_on_parasite_support_spawned)

func _on_parasite_support_spawned(enemy: ColorlessEntity) -> void:
	enemy.defeated.connect(_on_room_enemy_defeated)

func _restore(snapshot: Dictionary, revive: bool) -> void:
	super._restore(snapshot, revive)
	_sync_dodge_growth()
	if _needs_dodge_growth():
		save_current("旧档闪避强化已补领")
	if room is ParasiteRoom and has_session():
		_enter_parasite()

func _needs_dodge_growth() -> bool:
	return has_session() and bool(data["events"].get(PARASITE_DEFEATED,false)) and (not bool(data["events"].get(DODGE_GROWTH,false)) or bool(data["events"].get(DODGE_PENDING,false)))

func _sync_dodge_growth() -> void:
	player.possibility.dodge_upgraded = has_session() and bool(data["events"].get(PARASITE_DEFEATED,false)) and bool(data["events"].get(DODGE_GROWTH,false))

func _change_room(target: String) -> void:
	super._change_room(target)
	if room is ParasiteRoom and has_session():
		_enter_parasite()

func activate_checkpoint(id: String) -> bool:
	# Boss entry must remain retryable if its first write fails.
	var previous: String = str(data.get("checkpoint", ""))
	var result: bool = super.activate_checkpoint(id)
	if not result and id == PARASITE_CHECKPOINT and previous != id and has_session():
		data["checkpoint"] = previous
		_update_flags()
	return result

func _enter_parasite() -> void:
	var arena: ParasiteRoom = room as ParasiteRoom
	var actor: ParasiteBoss = arena.get_node("Boss") as ParasiteBoss
	if data["checkpoint"] != PARASITE_CHECKPOINT and not activate_checkpoint(PARASITE_CHECKPOINT):
		return
	if bool(data["events"].get(PARASITE_DEFEATED, false)):
		actor.mark_defeated()
		arena.set_opened(true)
		return
	if actor.state != ParasiteBoss.State.WAITING:
		return
	if bool(data["events"].get(PARASITE_INTRO, false)):
		actor.start_combat()
		arena.start_ordinary(player)
		return
	data["events"][PARASITE_INTRO] = true
	if not save_current("Boss首次演出已记录"):
		data["events"].erase(PARASITE_INTRO)
		return
	cinematics.begin(&"boss.parasite", true)
	_parasite_intro_remaining = actor.config.intro_duration
	player.reset_kinematics()
	ui.call("show_enemy_card", actor.config.intro_duration, "寄生同伴者", "首领", "弹反连续投射物。\n被命中会让Boss恢复生命。")

func _physics_process(delta: float) -> void:
	if _needs_dodge_growth() and _interaction_input():
		save_current("闪避强化已补领")
		return
	if _parasite_intro_remaining > 0.0:
		if not player.life.is_alive():
			_end_parasite_intro(false)
			return
		cinematics.advance(delta)
		if _parasite_intro_remaining == 0.0:
			_end_parasite_intro(true)
		return
	super._physics_process(delta)
	if room is ParasiteRoom and has_session() and _interaction_input():
		if _parasite_victory_pending:
			save_current("胜利状态已保存")
		else:
			_enter_parasite()

func _end_parasite_intro(start: bool) -> void:
	_parasite_intro_remaining = 0.0
	cinematics.finish(&"boss.parasite")
	if start:
		(room.get_node("Boss") as ParasiteBoss).start_combat()
		(room as ParasiteRoom).start_ordinary(player)

func _on_parasite_defeated() -> void:
	(room as ParasiteRoom).clear_projectiles()
	_parasite_victory_pending = true
	save_current("寄生同伴者已击败 · 木板落下 · 获得闪避强化")

func _on_death() -> void:
	if room is ParasiteRoom:
		(room as ParasiteRoom).clear_projectiles()
	super._on_death()

func restart_challenge() -> void:
	if _parasite_victory_pending and not save_current("胜利状态已保存"):
		return
	super.restart_challenge()

func save_current(message: String = "已自动保存") -> bool:
	if not _parasite_victory_pending and not _needs_dodge_growth():
		return super.save_current(message)
	var before: Dictionary = data["events"].duplicate()
	var old_day: int = int(data.get("day",1))
	var old_time: float = float(data.get("day_remaining",DayClock.CONFIG.day_seconds))
	var old_third_time: float = float(data.get("day3_remaining",DayClock.CONFIG.day_seconds))
	var victory: bool = _parasite_victory_pending
	if victory:
		DayClock.advance_to(data,3)
		for key: String in [PARASITE_DEFEATED, PARASITE_PASSAGE]:
			data["events"][key] = true
	data["events"][DODGE_GROWTH] = true
	data["events"].erase(DODGE_PENDING)
	if not super.save_current(message):
		data["events"] = before
		data["day"] = old_day
		data["day_remaining"] = old_time
		data["day3_remaining"] = old_third_time
		_sync_dodge_growth()
		return false
	_sync_dodge_growth()
	_parasite_victory_pending = false
	if victory and room is ParasiteRoom:
		(room as ParasiteRoom).set_opened(true,true)
	ui.call("save_failed", "")
	return true

func _on_room_exit(target: String) -> void:
	if room is ParasiteRoom and not bool(data.get("events", {}).get(PARASITE_DEFEATED, false)):
		_notify("击败寄生同伴者后通路开启")
		return
	super._on_room_exit(target)

func _process(delta: float) -> void:
	super._process(delta)
	if room is ParasiteRoom and has_session():
		$Instructions/Help.text = "攻击弹反投射物 · 飞行支援击杀可获得+2可能性\n被命中会让Boss吸血 · 击败后沿平台寻找破洞"
		if player.possibility.dodge_upgraded:
			$Instructions/Help.text = "已获得闪避强化 · 地面/空中速度900\n沿平台寻找破洞 · 可返回营帐"
		if _parasite_intro_remaining > 0.0:
			$Instructions/Help.text = "寄生同伴者 · 首次登场"
		elif _parasite_victory_pending or (room.get_node("Boss") as ParasiteBoss).state == ParasiteBoss.State.WAITING:
			$Instructions/Help.text = "进度保存尚未完成 · 按 E / RB 重试"
	if _needs_dodge_growth():
		$Instructions/EnemyStatus.text += " · 闪避强化尚未补领（E / RB 重试保存）"

func _obtained_items(snapshot: Dictionary) -> Dictionary:
	var result: Dictionary = super._obtained_items(snapshot)
	if bool(snapshot.get("events", {}).get(DODGE_GROWTH, false)):
		result[DODGE_GROWTH] = {"kind":"成长", "display_name":"闪避强化"}
	return result

func interaction_targets() -> Array[Dictionary]:
	var result: Array[Dictionary] = super.interaction_targets()
	if _needs_dodge_growth():
		for target: Dictionary in result: target["available"] = false
		result.append(_target(DODGE_GROWTH, "补领", "重试保存", player.global_position, null, true,
			not get_tree().paused and not _world_dialogue_blocked() and player.life.can_control(), true, "unlimited"))
	if has_session() and room is ParasiteRoom and (_parasite_victory_pending or room.get_node("Boss").state == ParasiteBoss.State.WAITING):
		result.append(_target(room.config.room_id + ":retry", "重试", "重试保存", player.global_position, null, true,
			not intro_active, true, "unlimited"))
	return result
