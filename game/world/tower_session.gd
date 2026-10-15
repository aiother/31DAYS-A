class_name TowerSession
extends TwoRoomSession
const TOWER_ID: String = "HD_10002_2"
const TOWER_ROOMS: Dictionary = {
	START_ID: preload("res://world/rooms/hd_10001_1.tscn"),
	ENTRY_ID: preload("res://world/rooms/hd_10002_1.tscn"),
	TOWER_ID: preload("res://world/rooms/hd_10002_2.tscn")
}

func _room_scenes() -> Dictionary:
	return TOWER_ROOMS

func _process(delta: float) -> void:
	super._process(delta)
	if room.config.room_id == TOWER_ID:
		$Instructions/Help.text = "沿断壁平台向上 · 空格长按跳高 · J 攻击 · K 闪避\n左下道路返回入口 · 检查点位于入口区域"
