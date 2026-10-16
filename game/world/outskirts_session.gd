class_name OutskirtsSession
extends ParasiteSession
const OUTSKIRTS_ID: String = "NSZC_10001_1"
const OUTSKIRTS_ROOM: PackedScene = preload("res://world/rooms/nszc_10001_1.tscn")

func _room_scenes() -> Dictionary:
	var scenes: Dictionary = super._room_scenes().duplicate()
	scenes[OUTSKIRTS_ID] = OUTSKIRTS_ROOM
	return scenes

func _process(delta: float) -> void:
	super._process(delta)
	if room is OutskirtsRoom:
		$Instructions/Title.text = "逆时战场 / 战场外围"
		$Instructions/Help.text = "空格跨越高台 · 两端道路可往返\n上层能力门尚未开启 · 向右前往堑壕"
