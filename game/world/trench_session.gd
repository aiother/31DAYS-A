class_name TrenchSession
extends OutskirtsSession
const TRENCH_ID: String = "NSZC_10002_1"
const TRENCH_CHECKPOINT: String = "NSZC_10002_1_N002"
const TRENCH_ROOM: PackedScene = preload("res://world/rooms/nszc_10002_1.tscn")

func _room_scenes() -> Dictionary:
	var scenes: Dictionary = super._room_scenes().duplicate()
	scenes[TRENCH_ID] = TRENCH_ROOM
	return scenes

func _supports_checkpoint(id: String) -> bool:
	return id == TRENCH_CHECKPOINT or super._supports_checkpoint(id)

func _checkpoint_room(id: String) -> String:
	return TRENCH_ID if id == TRENCH_CHECKPOINT else super._checkpoint_room(id)

func _change_room(target_id: String) -> void:
	super._change_room(target_id)
	if room is TrenchRoom:
		activate_checkpoint(TRENCH_CHECKPOINT)

func activate_checkpoint(id: String) -> bool:
	if id != TRENCH_CHECKPOINT:
		return super.activate_checkpoint(id)
	if not has_session() or _loading or not player.life.is_alive() or _checkpoint(id) == null or data["checkpoint"] == id:
		return false
	var previous: String = str(data["checkpoint"])
	data["checkpoint"] = id
	_update_flags()
	if not save_current("堑壕入口检查点已记录"):
		data["checkpoint"] = previous
		_update_flags()
		return false
	ui.call("save_failed", "")
	return true

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if room is TrenchRoom and has_session() and Input.is_action_just_pressed("interact") and player.life.can_control() and player.position.distance_to(_checkpoint(TRENCH_CHECKPOINT).config.spawn_position) <= 96:
		activate_checkpoint(TRENCH_CHECKPOINT)

func _process(delta: float) -> void:
	super._process(delta)
	if room is TrenchRoom:
		$Instructions/Title.text = "逆时战场 / 堑壕第一间"
		$Instructions/Help.text = "沿平台向上探索 · E / RB 拾取珍珠：近战范围 +5%\n两端无清敌限制 · 沿上层道路继续探索"
		if has_session() and data["checkpoint"] != TRENCH_CHECKPOINT:
			$Instructions/Help.text = "检查点尚未保存 · 靠近旗帜按 E / RB 重试"
