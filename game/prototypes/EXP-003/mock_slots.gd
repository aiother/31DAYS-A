extends RefCounted
## EXP-003 mock save slots. Shapes follow SlotStore snapshots closely enough to
## show every state the formal slot screen needs: in progress, completed
## (A-013), empty and unreadable. Nothing here touches real saves.
const CHECKPOINT_NAMES: Dictionary = {
	"graybox_start": "无顶深谷 · 起始区", "HD_20001_1_N001": "沟壑入口",
	"NSZC_10002_1_N001": "堑壕第二间", "HD_10002_1_N002": "麦秆镇外",
}

## Each entry: {} empty, {"unreadable": true}, or a snapshot-like dictionary.
var slots: Array[Dictionary] = []

func _init() -> void:
	reset()

func reset() -> void:
	slots = [
		{"day": 2, "day_progress": 0.4, "play_seconds": 5025.0, "health": 4, "max_health": 5, "balance": 6, "maximum": 12, "pearls": 2, "checkpoint": "HD_20001_1_N001", "completed": false},
		{"day": 3, "day_progress": 1.0, "play_seconds": 11890.0, "health": 5, "max_health": 5, "balance": 3, "maximum": 12, "pearls": 4, "checkpoint": "NSZC_10002_1_N001", "completed": true},
		{},
	]

func has_any() -> bool:
	for slot: Dictionary in slots:
		if not slot.is_empty():
			return true
	return false

func clear_all() -> void:
	slots = [{}, {}, {}]

func toggle_unreadable() -> void:
	slots[2] = {} if slots[2].has("unreadable") else {"unreadable": true}

func state(index: int) -> String:
	var slot: Dictionary = slots[index]
	if slot.is_empty():
		return "empty"
	if slot.has("unreadable"):
		return "unreadable"
	return "completed" if bool(slot["completed"]) else "progress"

static func play_time(seconds: float) -> String:
	var total: int = int(seconds)
	return "%d:%02d:%02d" % [int(total / 3600.0), int(total / 60.0) % 60, total % 60]

static func checkpoint_name(id: String) -> String:
	return str(CHECKPOINT_NAMES.get(id, id))

func start_new(index: int) -> void:
	slots[index] = {"day": 1, "day_progress": 0.0, "play_seconds": 0.0, "health": 3, "max_health": 5, "balance": 3, "maximum": 10, "pearls": 0, "checkpoint": "graybox_start", "completed": false}

func complete(index: int) -> void:
	if state(index) == "progress":
		slots[index]["completed"] = true
		slots[index]["day"] = 3
