class_name BossSession
extends ConnectionSession
const BOSS_ID: String = "HD_10004_1"
const BOSS_CHECKPOINT: String = "HD_10004_1_N003"
const BOSS_INTRO: String = "HD_10004_1_N001:intro"
const BOSS_DEFEATED: String = "HD_10004_1_N001:defeated"
const BOSS_PASSAGE: String = "HD_10004_1_N002"
const GROWTH_PENDING: String = "HD_10004_1:combat_growth_pending"
const COMBAT_GROWTH: String = "HD_10004_1:combat_growth_claimed"
const BOSS_ROOMS: Dictionary = {
	START_ID: preload("res://world/rooms/hd_10001_1.tscn"),
	ENTRY_ID: preload("res://world/rooms/hd_10002_1.tscn"),
	TOWER_ID: preload("res://world/rooms/hd_10002_2.tscn"),
	EXPLORATION_ID: preload("res://world/rooms/hd_10002_3.tscn"),
	CONNECTION_ID: preload("res://world/rooms/hd_10003_1.tscn"),
	BOSS_ID: preload("res://world/rooms/hd_10004_1.tscn")
}
var _boss_intro_remaining: float = 0.0
var _victory_pending: bool = false

func _room_scenes() -> Dictionary:
	return BOSS_ROOMS

func _supports_checkpoint(id: String) -> bool:
	return id == BOSS_CHECKPOINT or super._supports_checkpoint(id)

func _checkpoint_room(id: String) -> String:
	return BOSS_ID if id == BOSS_CHECKPOINT else super._checkpoint_room(id)

func _bind_room() -> void:
	super._bind_room()
	RemnantPossibilitySpawner.attach(self, room, player)
	if room is BossRoom:
		var actor: OverlookBoss = room.get_node("Boss") as OverlookBoss
		actor.target = player
		if not actor.defeated.is_connected(_on_boss_defeated):
			actor.defeated.connect(_on_boss_defeated)
		if not actor.platforms_requested.is_connected((room as BossRoom).summon_platforms):
			actor.platforms_requested.connect((room as BossRoom).summon_platforms)
		if not actor.reinforcement_warning.is_connected((room as BossRoom).prepare_reinforcement):
			actor.reinforcement_warning.connect((room as BossRoom).prepare_reinforcement)
		if not actor.reinforcement_requested.is_connected((room as BossRoom).spawn_reinforcement):
			actor.reinforcement_requested.connect((room as BossRoom).spawn_reinforcement)
		if not (room as BossRoom).reinforcement_spawned.is_connected(_on_reinforcement_spawned):
			(room as BossRoom).reinforcement_spawned.connect(_on_reinforcement_spawned)

func _on_reinforcement_spawned(enemy: ColorlessEntity) -> void:
	enemy.defeated.connect(_on_room_enemy_defeated)

func _restore(snapshot: Dictionary, revive: bool) -> void:
	super._restore(snapshot, revive)
	_sync_combat_growth()
	if _needs_combat_growth():
		save_current("旧档战斗强化已补领")
	if room is BossRoom and has_session():
		_enter_boss()

func _needs_combat_growth() -> bool:
	return has_session() and bool(data["events"].get(BOSS_DEFEATED,false)) and (not bool(data["events"].get(COMBAT_GROWTH,false)) or bool(data["events"].get(GROWTH_PENDING,false)))

func _sync_combat_growth() -> void:
	player.combat.range_upgraded = has_session() and bool(data["events"].get(BOSS_DEFEATED,false)) and bool(data["events"].get(COMBAT_GROWTH,false))

func _change_room(target: String) -> void:
	super._change_room(target)
	if room is BossRoom and has_session():
		_enter_boss()

func activate_checkpoint(id: String) -> bool:
	# Boss entry must remain retryable if its first write fails.
	var previous: String = str(data.get("checkpoint", ""))
	var result: bool = super.activate_checkpoint(id)
	if not result and id == BOSS_CHECKPOINT and previous != id and has_session():
		data["checkpoint"] = previous
		_update_flags()
	return result

func _enter_boss() -> void:
	var arena: BossRoom = room as BossRoom
	var actor: OverlookBoss = arena.get_node("Boss") as OverlookBoss
	if data["checkpoint"] != BOSS_CHECKPOINT and not activate_checkpoint(BOSS_CHECKPOINT):
		return
	if bool(data["events"].get(BOSS_DEFEATED, false)):
		actor.mark_defeated()
		arena.set_opened(true)
		return
	if actor.state != OverlookBoss.State.WAITING:
		return
	if bool(data["events"].get(BOSS_INTRO, false)):
		actor.start_combat()
		arena.start_ordinary(player)
		return
	data["events"][BOSS_INTRO] = true
	if not save_current("Boss首次演出已记录"):
		data["events"].erase(BOSS_INTRO)
		return
	intro_active = true
	_boss_intro_remaining = actor.config.intro_duration
	player.reset_kinematics()
	player.life.scripted_control_locked = true
	ui.call("show_enemy_card", actor.config.intro_duration, "渴望俯视", "首领", "留意落击提示。\n利用召唤平台接近高空目标。")

func _physics_process(delta: float) -> void:
	if _needs_combat_growth() and _interaction_input():
		save_current("战斗强化已补领")
		return
	if _boss_intro_remaining > 0.0:
		if not player.life.is_alive():
			_end_boss_intro(false)
			return
		_boss_intro_remaining = maxf(0.0, _boss_intro_remaining - delta)
		var actor: OverlookBoss = room.get_node("Boss") as OverlookBoss
		var elapsed: float = actor.config.intro_duration - _boss_intro_remaining
		var camera: Camera2D = player.get_node("Camera2D") as Camera2D
		camera.offset = Vector2(0, -600 * clampf((3.5 - elapsed) / 1.5, 0, 1))
		if elapsed > actor.config.intro_duration - 0.8:
			actor.position.y = move_toward(actor.position.y, actor.config.floor_y, 1200 * delta)
			camera.offset.x = sin(elapsed * 80) * 5
		if _boss_intro_remaining == 0.0:
			_end_boss_intro(true)
		return
	super._physics_process(delta)
	if room is BossRoom and has_session() and _interaction_input():
		if _victory_pending:
			save_current("胜利状态已保存")
		else:
			_enter_boss()

func _end_boss_intro(start: bool) -> void:
	_boss_intro_remaining = 0.0
	intro_active = false
	player.life.scripted_control_locked = false
	(player.get_node("Camera2D") as Camera2D).offset = Vector2.ZERO
	if start:
		(room.get_node("Boss") as OverlookBoss).start_combat()
		(room as BossRoom).start_ordinary(player)

func _on_boss_defeated() -> void:
	(room as BossRoom).clear_reinforcements()
	_victory_pending = true
	save_current("渴望俯视已击败 · 天窗开启 · 获得攻击范围强化")

func _on_death() -> void:
	if room is BossRoom:
		(room as BossRoom).clear_reinforcements()
	super._on_death()

func restart_challenge() -> void:
	if _victory_pending and not save_current("胜利状态已保存"):
		return
	super.restart_challenge()

func save_current(message: String = "已自动保存") -> bool:
	if not _victory_pending and not _needs_combat_growth():
		return super.save_current(message)
	var before: Dictionary = data["events"].duplicate()
	var victory: bool = _victory_pending
	if victory:
		for key: String in [BOSS_DEFEATED, BOSS_PASSAGE]:
			data["events"][key] = true
	data["events"][COMBAT_GROWTH] = true
	data["events"].erase(GROWTH_PENDING)
	if not super.save_current(message):
		data["events"] = before
		_sync_combat_growth()
		return false
	_sync_combat_growth()
	_victory_pending = false
	if victory and room is BossRoom:
		(room as BossRoom).set_opened(true)
	ui.call("save_failed", "")
	return true

func _on_room_exit(target: String) -> void:
	if room is BossRoom and not bool(data.get("events", {}).get(BOSS_DEFEATED, false)):
		_notify("击败渴望俯视后通路开启")
		return
	super._on_room_exit(target)

func _process(delta: float) -> void:
	super._process(delta)
	if room is BossRoom and has_session():
		$Instructions/Help.text = "留意落击与召唤提示 · 借平台跳跃攻击\n击败后天窗开启 · 向上寻找通路"
		if _boss_intro_remaining > 0.0:
			$Instructions/Help.text = "渴望俯视 · 首次登场"
		elif _victory_pending or (room.get_node("Boss") as OverlookBoss).state == OverlookBoss.State.WAITING:
			$Instructions/Help.text = "进度保存尚未完成 · 按 E / RB 重试"
		elif player.combat.range_upgraded:
			$Instructions/Help.text = "已获得攻击范围强化 · 四方向范围+20%\n天窗开启 · 向上寻找通路"
	if _needs_combat_growth():
		$Instructions/EnemyStatus.text += " · 战斗强化尚未补领（E / RB 重试保存）"

func _obtained_items(snapshot: Dictionary) -> Dictionary:
	var result: Dictionary = super._obtained_items(snapshot)
	if bool(snapshot.get("events", {}).get(COMBAT_GROWTH, false)):
		result[COMBAT_GROWTH] = {"kind":"成长", "display_name":"攻击范围强化"}
	return result

func interaction_targets() -> Array[Dictionary]:
	var result: Array[Dictionary] = super.interaction_targets()
	if _needs_combat_growth():
		for target: Dictionary in result: target["available"] = false
		result.append(_target(COMBAT_GROWTH, "补领", "重试保存", player.global_position, null, true,
			not get_tree().paused and not _world_dialogue_blocked() and player.life.can_control(), true, "unlimited"))
	if has_session() and room is BossRoom and (_victory_pending or room.get_node("Boss").state == OverlookBoss.State.WAITING):
		result.append(_target(room.config.room_id + ":retry", "重试", "重试保存", player.global_position, null, true,
			not intro_active, true, "unlimited"))
	return result
