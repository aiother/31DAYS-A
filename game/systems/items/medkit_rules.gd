class_name MedkitRules
extends RefCounted
const CONFIG: MedkitConfig = preload("res://data/world/medkit.tres")

static func count(data: Dictionary) -> int:
	return int(data.get("medkits", 0))

static func key(room_id: String) -> String:
	return "supply:%s:medkit_01" % room_id
