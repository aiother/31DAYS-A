class_name BattlefieldSession
extends TrenchPassageSession
const BATTLEFIELD_ID: String = "NSZC_10003_1"
const BATTLEFIELD_ROOM: PackedScene = preload("res://world/rooms/nszc_10003_1.tscn")
var stage_notified: bool = false

func _room_scenes() -> Dictionary:
	var scenes: Dictionary = super._room_scenes().duplicate()
	scenes[BATTLEFIELD_ID] = BATTLEFIELD_ROOM
	return scenes

func _bind_room() -> void:
	super._bind_room()
	if room is BattlefieldRoom:
		var area: BattlefieldRoom = room as BattlefieldRoom
		area.target = player
		for child: Node in area.get_node("Enemies").get_children():
			if child is ColorlessEntity:
				child.set_physics_process(area.started and not area.stopped)
		if not area.stage_completed.is_connected(_on_stage_completed):
			area.stage_completed.connect(_on_stage_completed)

func _change_room(id: String) -> void:
	stage_notified = false
	super._change_room(id)

func _on_stage_completed() -> void:
	if stage_notified or not player.life.is_alive():
		return
	if save_current("中心战场首段已完成 · 当前资源已保存"):
		stage_notified = true
		ui.call("save_failed","")
		ui.call("show_battle_banner",6.0,"中心战场 · 首段完成\n\n本轮混战验证完成。\n10救场、最终波次、时限及结局将在下一阶段接入。\n本提示不代表最终胜利。")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if room is BattlefieldRoom and (room as BattlefieldRoom).completed and _interaction_input():
		_on_stage_completed()

func _on_room_exit(id: String) -> void:
	if room is BattlefieldRoom:
		_notify("战场返回路等待完整战斗胜利后开启 · 首段完成不判最终胜利")
		return
	super._on_room_exit(id)

func _on_death() -> void:
	if room is BattlefieldRoom:
		(room as BattlefieldRoom).stop_attempt()
	super._on_death()

func _process(delta: float) -> void:
	super._process(delta)
	if room is BattlefieldRoom:
		$Instructions/Title.text = "逆时战场 / 中心战场 · 首段混战"
		$Instructions/Help.text = "向右越过安全区开战 · 首名天人阵亡后两批幸存者加入 · 绿色为友军\n首段清空仅为阶段完成；资源保存失败可 E / RB 重试 · 沿用堑壕第二间检查点"

func interaction_targets() -> Array[Dictionary]:
	var result: Array[Dictionary] = super.interaction_targets()
	if _stage_retry_pending():
		result.append(_target("battlefield:retry", "重试", "保存阶段结算", player.global_position, null, true,
			not get_tree().paused and not _world_dialogue_blocked() and player.life.is_alive(), false, "unlimited"))
	return result

func _stage_retry_pending() -> bool:
	return has_session() and room is BattlefieldRoom and (room as BattlefieldRoom).completed and not stage_notified and player.life.is_alive()
