class_name CampWavesSession
extends CampSession
const WAVES_ID: String = "HD_20002_2"
const WAVES_CHECKPOINT: String = "HD_20002_2_N001"
const WAVES_ROOM: PackedScene = preload("res://world/rooms/hd_20002_2.tscn")

func _room_scenes() -> Dictionary:
	var scenes: Dictionary = super._room_scenes().duplicate()
	scenes[WAVES_ID] = WAVES_ROOM
	return scenes

func _supports_checkpoint(id: String) -> bool:
	return id == WAVES_CHECKPOINT or super._supports_checkpoint(id)

func _checkpoint_room(id: String) -> String:
	return WAVES_ID if id == WAVES_CHECKPOINT else super._checkpoint_room(id)

func _bind_room() -> void:
	super._bind_room()
	if room is CampWavesRoom:
		var arena: CampWavesRoom = room as CampWavesRoom
		arena.target = player
		if not arena.enemy_spawned.is_connected(_on_wave_enemy_spawned):
			arena.enemy_spawned.connect(_on_wave_enemy_spawned)

func _on_wave_enemy_spawned(enemy: ColorlessEntity) -> void:
	WorldDayRules.apply_enemy(enemy, int(data.get("day", 1)))
	enemy.defeated.connect(_on_room_enemy_defeated)

func _change_room(target_id: String) -> void:
	super._change_room(target_id)
	if room is CampWavesRoom:
		activate_checkpoint(WAVES_CHECKPOINT)

func activate_checkpoint(id: String) -> bool:
	if id != WAVES_CHECKPOINT:
		return super.activate_checkpoint(id)
	if not has_session() or _loading or not player.life.is_alive() or _checkpoint(id) == null or data["checkpoint"] == id:
		return false
	var previous: String = str(data["checkpoint"])
	data["checkpoint"] = id
	_update_flags()
	if not save_current("营帐入口检查点已记录"):
		data["checkpoint"] = previous
		_update_flags()
		return false
	ui.call("save_failed", "")
	return true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _interaction_input() and _checkpoint_retry_in_range(WAVES_CHECKPOINT, room is CampWavesRoom):
		activate_checkpoint(WAVES_CHECKPOINT)

func _on_room_exit(target_id: String) -> void:
	if room is CampWavesRoom and (room as CampWavesRoom).phase != CampWavesRoom.Phase.COMPLETE:
		_notify("完成全部围攻波次后才能离开")
		return
	super._on_room_exit(target_id)

func _process(delta: float) -> void:
	super._process(delta)
	if room is CampWavesRoom and has_session():
		var arena: CampWavesRoom = room as CampWavesRoom
		var status: String = "越过入口安全区开始战斗"
		match arena.phase:
			CampWavesRoom.Phase.WARNING:
				status = "第 %d / %d 波 · 即将出现" % [arena.wave,arena.waves.counts.size()]
			CampWavesRoom.Phase.ACTIVE:
				status = "第 %d / %d 波 · 剩余 %d" % [arena.wave,arena.waves.counts.size(),arena.living().size()]
			CampWavesRoom.Phase.INTERVAL:
				status = "第 %d 波已清空 · 准备下一波" % arena.wave
			CampWavesRoom.Phase.COMPLETE:
				status = "%d 波战斗完成 · 可继续前进" % arena.waves.counts.size()
		$Instructions/Help.text = status+"\n全部波次结束后开放两端 · 往返/死亡/读档重置整场"
		if data["checkpoint"] != WAVES_CHECKPOINT:
			$Instructions/Help.text = "入口检查点尚未保存 · 靠近旗帜按 E / RB 重试\n"+status

func interaction_targets() -> Array[Dictionary]:
	var result: Array[Dictionary] = super.interaction_targets()
	if has_session() and room is CampWavesRoom:
		result.append(_checkpoint_target(WAVES_CHECKPOINT))
	return result
