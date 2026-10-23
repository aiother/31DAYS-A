class_name TianSession
extends TrenchSession
const TIAN_INTRO: String = "NSZC_10002_1_N001"
var _tian_intro_retry: bool = false

func _bind_room() -> void:
	super._bind_room()
	if room is TrenchRoom:
		for actor: Node in room.get_node("Enemies").get_children():
			if actor is TianWarrior:
				actor.set_physics_process(bool(data.get("events",{}).get(TIAN_INTRO,false)))

func _on_encounter() -> void:
	if not room is TrenchRoom:
		super._on_encounter()
		return
	if not has_session() or not player.life.can_control() or bool(data["events"].get(TIAN_INTRO,false)):
		return
	data["events"][TIAN_INTRO] = true
	if not save_current("天人战士首次遭遇已记录"):
		data["events"].erase(TIAN_INTRO)
		_tian_intro_retry = true
		return
	_tian_intro_retry = false
	_bind_room()
	ui.call("save_failed","")
	ui.call("show_enemy_card",4.0,"天人战士","精英","这里不安全。\n留意连击、瞬移与格挡反击。\n从侧后方或上下攻击，抓住重击后摇。")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _interaction_input() and _can_tian_retry():
		_on_encounter()

func _process(delta: float) -> void:
	super._process(delta)
	if room is TrenchRoom and (not has_session() or data["checkpoint"] == TRENCH_CHECKPOINT):
		$Instructions/Help.text = "天人：连击 / 长前摇重击 / 格挡反击 · 上下攻击寻找破绽\nE / RB 拾取珍珠 · 沿平台向上到达本阶段边界"
		if _tian_intro_retry:
			$Instructions/Help.text = "首次介绍尚未保存 · 在战斗区域按 E / RB 重试"

func _can_tian_retry() -> bool:
	return _tian_intro_retry and room is TrenchRoom and not _world_dialogue_blocked() and has_session() and player.life.can_control() and not bool(data["events"].get(TIAN_INTRO,false)) and (room as WorldRoom)._currently_overlaps(room.get_node("Encounter") as Area2D,player)

func interaction_targets() -> Array[Dictionary]:
	var result: Array[Dictionary] = super.interaction_targets()
	if _tian_intro_retry and room is TrenchRoom:
		var area: Area2D = room.get_node("Encounter") as Area2D
		var shape: CollisionShape2D = area.get_node("CollisionShape2D") as CollisionShape2D
		var target: Dictionary = _target(TIAN_INTRO, "重试", "保存首次介绍", area.global_position, null,
			room._currently_overlaps(area,player), not get_tree().paused and _can_tian_retry(), false, "area")
		target["bounds"] = shape.global_transform * Rect2(-(shape.shape as RectangleShape2D).size/2, (shape.shape as RectangleShape2D).size)
		result.append(target)
	return result
