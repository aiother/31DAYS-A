class_name SlotStore
extends RefCounted
## JSON only: never deserialize executable resources or scene paths from saves.
const VERSION: int = 1
const SLOT_COUNT: int = 3
const CHECKPOINTS: PackedStringArray = ["graybox_start", "graybox_forward"]
var directory: String = "user://saves"
var last_error: String = ""
var used_backup: bool = false

func fresh() -> Dictionary:
	return {"version": VERSION, "checkpoint": "graybox_start", "health": 3, "balance": 3, "maximum": 10, "events": {}, "play_seconds": 0.0}

func path_for(slot: int) -> String:
	return directory.path_join("slot_%d.json" % slot)

func valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= SLOT_COUNT

func _integer(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and float(value) >= low and float(value) <= high

func valid(data: Dictionary) -> bool:
	if not _integer(data.get("version"), VERSION, VERSION) or not CHECKPOINTS.has(str(data.get("checkpoint", ""))):
		return false
	if not _integer(data.get("health"), 1, 5) or not _integer(data.get("balance"), -9, 10) or not _integer(data.get("maximum"), 10, 10):
		return false
	var events: Variant = data.get("events")
	if not events is Dictionary or events.size() > 1000:
		return false
	for key: Variant in events:
		if not key is String or key.is_empty() or key.length() > 128 or not events[key] is bool:
			return false
	var seconds: Variant = data.get("play_seconds")
	return (seconds is int or seconds is float) and is_finite(float(seconds)) and float(seconds) >= 0.0

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 1048576:
		return {}
	var parser: JSON = JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		return {}
	var data: Dictionary = parser.data
	if not valid(data):
		return {}
	for key: String in ["version", "health", "balance", "maximum"]:
		data[key] = int(data[key])
	data["play_seconds"] = float(data["play_seconds"])
	return data

func load_slot(slot: int) -> Dictionary:
	last_error = ""
	used_backup = false
	if not valid_slot(slot):
		last_error = "存档槽编号无效"
		return {}
	var path: String = path_for(slot)
	var data: Dictionary = _read(path)
	if not data.is_empty():
		return data
	data = _read(path + ".bak")
	if not data.is_empty():
		used_backup = true
		return data
	if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"):
		last_error = "存档损坏或版本不兼容，原文件已保留"
	return {}

func save_slot(slot: int, data: Dictionary) -> bool:
	last_error = ""
	if not valid_slot(slot) or not valid(data):
		last_error = "存档数据无效，未写入"
		return false
	var absolute_dir: String = ProjectSettings.globalize_path(directory)
	if DirAccess.make_dir_recursive_absolute(absolute_dir) != OK:
		last_error = "无法创建存档目录"
		return false
	var path: String = ProjectSettings.globalize_path(path_for(slot))
	var temporary: String = path + ".tmp"
	var backup: String = path + ".bak"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = "无法写入存档，请检查磁盘空间和权限"
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK or _read(temporary).is_empty():
		last_error = "存档写入校验失败，原存档保留"
		return false
	# Preserve the last valid primary. Never replace a good backup with corrupt data.
	if FileAccess.file_exists(path):
		if not _read(path).is_empty():
			if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup) != OK:
				last_error = "无法更新备份，原存档保留"
				return false
			if DirAccess.rename_absolute(path, backup) != OK:
				last_error = "无法轮换存档，原存档保留"
				return false
		elif DirAccess.remove_absolute(path) != OK:
			last_error = "无法替换损坏的存档"
			return false
	if DirAccess.rename_absolute(temporary, path) != OK:
		last_error = "无法完成存档替换，可从备份恢复"
		return false
	return true
