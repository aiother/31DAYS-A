class_name SlotSummaries
extends RefCounted
## Read-only presentation data. A separate reader preserves the active store's
## diagnostic state; load_slot already validates and never repairs a file.
const CHECKPOINT_CONFIGS: Array[CheckpointConfig] = [
	preload("res://data/checkpoints/graybox_start.tres"),
	preload("res://data/checkpoints/graybox_forward.tres"),
	preload("res://data/checkpoints/hd_10001_1_n003.tres"),
	preload("res://data/checkpoints/hd_10002_1_n002.tres"),
	preload("res://data/checkpoints/hd_10004_1_n003.tres"),
	preload("res://data/checkpoints/hd_20001_1_n001.tres"),
	preload("res://data/checkpoints/hd_20002_2_n001.tres"),
	preload("res://data/checkpoints/hd_20003_1_n003.tres"),
	preload("res://data/checkpoints/nszc_10002_1_n002.tres"),
	preload("res://data/checkpoints/nszc_10002_2_n001.tres")]
# The four permanent pearl sources consumed by ExplorationSession._sync_pearl_growth.
const PEARL_FLAGS: Array[String] = ["item:HD_10002_3:pearl_01", "keyitem:HD_20001_3:pearl_01",
	"keyitem:HD_20002_1:pearl_01", "item:NSZC_10002_1:pearl_01"]
const LABELS: Dictionary = {"empty":"空", "unreadable":"无法读取", "progress":"进行中", "completed":"已通关"}

static func read(source: SlotStore, max_health: int) -> Array[Dictionary]:
	var reader: SlotStore = SlotStore.new()
	reader.directory = source.directory
	reader.initial_checkpoint = source.initial_checkpoint
	var result: Array[Dictionary] = []
	for selected: int in range(1,SlotStore.SLOT_COUNT+1):
		var data: Dictionary = reader.load_slot(selected)
		var state: String = "empty" if reader.last_error.is_empty() else "unreadable"
		var row: Dictionary = {"slot":selected,"state":state,"state_text":LABELS[state],
			"day":0,"day_progress":0.0,"play_seconds":0.0,"health":0,"max_health":max_health,
			"balance":0,"maximum":0,"pearls":0,"checkpoint":"","checkpoint_name":"",
			"error":reader.last_error,"used_backup":reader.used_backup}
		if not data.is_empty():
			state = "completed" if SlotStore.is_completed(data) else "progress"
			row["state"] = state
			row["state_text"] = LABELS[state]
			row["day"] = int(data["day"])
			row["day_progress"] = clampf(1.0-DayClock.remaining(data)/DayClock.CONFIG.day_seconds,0.0,1.0)
			for key: String in ["play_seconds","health","balance","maximum","checkpoint"]:
				row[key] = data[key]
			for flag: String in PEARL_FLAGS:
				if bool(data["events"].get(flag,false)): row["pearls"] += 1
			for config: CheckpointConfig in CHECKPOINT_CONFIGS:
				if config.checkpoint_id == str(data["checkpoint"]):
					row["checkpoint_name"] = config.display_name
					break
		result.append(row)
	return result
