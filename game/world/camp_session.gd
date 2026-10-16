class_name CampSession
extends RavineDepthSession
const CAMP_ID: String = "HD_20002_1"
const CAMP_ROOM: PackedScene = preload("res://world/rooms/hd_20002_1.tscn")

func _room_scenes() -> Dictionary:
	var scenes: Dictionary = super._room_scenes().duplicate()
	scenes[CAMP_ID] = CAMP_ROOM
	return scenes

func _process(delta: float) -> void:
	super._process(delta)
	if room is CampRoom:
		$Instructions/Help.text = "空格跨越高台 · 沿平台寻找珍珠 · E / RB 拾取\n两端道路无清敌限制 · 向左返回沟壑，向右继续探索"
