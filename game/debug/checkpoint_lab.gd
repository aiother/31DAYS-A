class_name CheckpointLab
extends EnemyLab
## UI-003: a save just wrote a checkpoint different from the last one on disk
## (save feedback). Periodic, resource and event autosaves, loads and failed
## writes never emit it.
signal checkpoint_saved(id: String)
signal quest_changed(kind: String, state: Dictionary)
signal item_obtained(kind: String, display_name: String)
var _quest_previous: Dictionary = {}
var _quest_restoring: bool = false
var _item_saved_snapshot: Dictionary = {}
var _item_epoch: int = 0

@export var save_directory: String = "user://saves"
var store: SlotStore = SlotStore.new()
var slot: int = 0
var data: Dictionary = {}
var _death_settled: bool = false
var _loading: bool = false
var _reloading: bool = false
var _notice: String = ""
var _notice_remaining: float = 0.0
var _saved_checkpoint: String = ""
@onready var ui: CanvasLayer = $LifeUI

func _ready() -> void:
	super._ready()
	# Carry isolated/custom save directories across a title reload as well.
	if get_tree().has_meta("checkpoint_title"):
		save_directory = str(get_tree().get_meta("checkpoint_title"))
		get_tree().remove_meta("checkpoint_title")
	store.directory = save_directory
	player.life.health_changed.connect(_on_health_changed)
	player.possibility.balance_changed.connect(_on_balance_changed)
	player.life.died.connect(_on_death)
	get_tree().auto_accept_quit = false
	if not get_tree().root.close_requested.is_connected(_on_close_requested):
		get_tree().root.close_requested.connect(_on_close_requested)
	if get_tree().has_meta("checkpoint_reload"):
		var pending: Dictionary = get_tree().get_meta("checkpoint_reload")
		get_tree().remove_meta("checkpoint_reload")
		save_directory = str(pending["directory"])
		store.directory = save_directory
		slot = int(pending["slot"])
		_restore(pending["data"], bool(pending["revive"]))
		return
	ui.call("show_title")

func has_session() -> bool:
	return slot > 0 and not data.is_empty()

func slot_summaries() -> Array[Dictionary]:
	return SlotSummaries.read(store,player.life.config.max_health)

func has_any_save() -> bool:
	for summary: Dictionary in slot_summaries():
		if summary["state"] != "empty": return true
	return false

## Accepted returns are deferred like existing slot/death reloads. Saving uses
## the virtual save_current, preserving settlement, ending and timeout rules.
func return_to_title() -> bool:
	if _reloading: return false
	if not has_session():
		ui.call("show_title")
		return true
	if not save_current("正在返回标题"):
		return false
	_reloading = true
	_return_title.call_deferred()
	return true

func _return_title() -> void:
	var tree: SceneTree = get_tree()
	var was_paused: bool = tree.paused
	tree.set_meta("checkpoint_title",save_directory)
	tree.paused = false
	if tree.reload_current_scene() != OK:
		tree.remove_meta("checkpoint_title")
		_reloading = false
		tree.paused = was_paused
		ui.call("save_failed","场景重载失败，尚未离开当前进度")

func _process(delta: float) -> void:
	super._process(delta)
	if has_session() and player.life.is_alive():
		data["play_seconds"] = float(data["play_seconds"]) + delta
	_publish_quest_changes()
	_notice_remaining = maxf(0.0, _notice_remaining - delta)
	$Instructions/EnemyStatus.text = $Instructions/EnemyStatus.text.replace(" · R 开发重置", "")
	$Instructions/EnemyStatus.text += " · %s" % (_notice if _notice_remaining > 0.0 else ("存档槽 %d" % slot if has_session() else "请选择存档槽"))

func _checkpoint(id: String) -> GrayboxCheckpoint:
	for child: GrayboxCheckpoint in _all_checkpoints():
		if child.config.checkpoint_id == id:
			return child as GrayboxCheckpoint
	return null

func _supports_checkpoint(id: String) -> bool:
	return _checkpoint(id) != null

func _all_checkpoints() -> Array[GrayboxCheckpoint]:
	var result: Array[GrayboxCheckpoint] = []
	for child: Node in get_tree().get_nodes_in_group("checkpoints"):
		if child is GrayboxCheckpoint and is_ancestor_of(child):
			result.append(child as GrayboxCheckpoint)
	return result

func start_slot(selected: int, new_game: bool) -> bool:
	if _reloading or not store.valid_slot(selected):
		return false
	var next: Dictionary = store.fresh() if new_game else store.load_slot(selected)
	if next.is_empty():
		ui.call("save_failed", store.last_error if not store.last_error.is_empty() else "此槽没有存档")
		return false
	# A-013: reject before checkpoint restoration, reload or any save rotation.
	# load_slot may read a valid backup; that snapshot follows the same rule.
	if not new_game and SlotStore.is_completed(next):
		ui.call("save_failed", "游戏已通关")
		return false
	if not _supports_checkpoint(str(next.get("checkpoint", ""))):
		ui.call("save_failed", "此存档不属于当前场景，请选择新游戏")
		return false
	if new_game and not store.save_slot(selected, next):
		ui.call("save_failed", store.last_error)
		return false
	var recovered: bool = store.used_backup and not new_game
	if has_session():
		_queue_reload(selected, next, false)
	else:
		slot = selected
		_restore(next, false)
	if recovered:
		_notify("主存档不可用，已读取备份")
	return true

func _restore(snapshot: Dictionary, revive: bool) -> void:
	_loading = true
	data = snapshot.duplicate(true)
	_quest_restoring = true
	_item_saved_snapshot = data.duplicate(true)
	_item_epoch += 1
	_seed_quest_changes.call_deferred()
	_death_settled = false
	player.reset_kinematics()
	if revive:
		player.life.revive()
	else:
		player.life.start_new_run()
		player.life.health = int(data["health"])
		player.life.health_changed.emit(player.life.health, player.life.config.max_health)
	player.possibility.balance = int(data["balance"])
	player.possibility.maximum = int(data["maximum"])
	player.possibility.balance_changed.emit(player.possibility.balance, player.possibility.maximum)
	player.position = _checkpoint(str(data["checkpoint"])).config.spawn_position
	_update_flags()
	_saved_checkpoint = str(data["checkpoint"])
	_loading = false
	ui.call("resume_game")

func _update_flags() -> void:
	for child: GrayboxCheckpoint in _all_checkpoints():
		child.set_active(child.config.checkpoint_id == str(data["checkpoint"]))

func activate_checkpoint(id: String) -> bool:
	if not has_session() or _loading or not player.life.is_alive() or _checkpoint(id) == null or data["checkpoint"] == id:
		return false
	data["checkpoint"] = id
	_update_flags()
	return save_current("检查点已记录")

func record_event(id: String, value: bool = true) -> bool:
	if not has_session() or id.is_empty() or id.length() > 128:
		return false
	# Storage contract for future permanent Nodes; no NPC/event gameplay added here.
	data["events"][id] = value
	return save_current("进度已保存")

func _on_health_changed(_current: int, _maximum: int) -> void:
	_autosave_resources()

func _on_balance_changed(_current: int, _maximum: int) -> void:
	_autosave_resources()

func _autosave_resources() -> void:
	if has_session() and not _loading and player.life.is_alive():
		save_current()

func save_current(message: String = "已自动保存") -> bool:
	if not has_session():
		return true
	if player.life.is_alive():
		data["health"] = player.life.health
		data["balance"] = player.possibility.balance
	data["maximum"] = player.possibility.maximum
	if not store.save_slot(slot, data):
		ui.call("save_failed", store.last_error)
		return false
	var before_items: Dictionary = _obtained_items(_item_saved_snapshot)
	var after_items: Dictionary = _obtained_items(data)
	_item_saved_snapshot = data.duplicate(true)
	var obtained: Array[Dictionary] = []
	for id: String in after_items:
		if not before_items.has(id): obtained.append(after_items[id].duplicate(true))
	# Outer session overrides finish growth synchronization after this durable write.
	if not obtained.is_empty(): _emit_obtained.call_deferred(obtained, _item_epoch)
	_publish_quest_changes()
	_notify(message)
	if str(data["checkpoint"]) != _saved_checkpoint:
		_saved_checkpoint = str(data["checkpoint"])
		checkpoint_saved.emit(_saved_checkpoint)
	return true

func _on_death() -> void:
	if not has_session() or _death_settled:
		return
	_death_settled = true
	data["health"] = player.life.config.max_health
	# Producer confirmed floor rounding; negative debt clears to zero.
	data["balance"] = floori(maxi(0, player.possibility.balance) * 0.5)
	save_current("死亡结算已保存")

func restart_challenge() -> void:
	if not has_session() or not _death_settled or player.life.state != PlayerLife.State.DEATH_MENU:
		return
	_queue_reload(slot, data, true)

func _queue_reload(selected: int, snapshot: Dictionary, revive: bool) -> void:
	if _reloading:
		return
	_reloading = true
	_reload.call_deferred(selected, snapshot.duplicate(true), revive)

func _reload(selected: int, snapshot: Dictionary, revive: bool) -> void:
	var tree: SceneTree = get_tree()
	tree.set_meta("checkpoint_reload", {"directory": save_directory, "slot": selected, "data": snapshot, "revive": revive})
	tree.paused = false
	if tree.reload_current_scene() != OK:
		tree.remove_meta("checkpoint_reload")
		_reloading = false
		ui.call("save_failed", "场景重载失败，尚未离开当前进度")

func debug_restart() -> void:
	_notify("存档模式请在存档槽确认新游戏；R不重置进度")

func _notify(message: String) -> void:
	_notice = message
	_notice_remaining = 3.0

func _on_close_requested() -> void:
	ui.call("confirm_quit")

## Read-only UI data hooks; subclasses add existing rules, never persist UI caches.
func quest_state() -> Dictionary:
	return {"id":"", "title":"", "objective":"", "state":"无"}

func _quest_records() -> Dictionary:
	return {}

func _seed_quest_changes() -> void:
	_quest_previous = _quest_records().duplicate(true)
	_quest_restoring = false

func _publish_quest_changes() -> void:
	if not has_session() or _loading or _quest_restoring: return
	var records: Dictionary = _quest_records()
	for id: String in records:
		var current: Dictionary = records[id]
		var previous: Dictionary = _quest_previous.get(id, {"state":"无"})
		if current == previous: continue
		_quest_previous[id] = current.duplicate(true)
		if current["state"] == "无": continue
		var kind: String = {"已完成":"完成", "已放弃":"放弃", "已过期":"过期"}.get(current["state"], "开始" if previous["state"] == "无" else "进展")
		# A completed rescue gaining its deferred settlement is progress, not a second completion.
		if current["state"] == previous["state"]: kind = "进展"
		quest_changed.emit(kind, current.duplicate(true))

func _obtained_items(_snapshot: Dictionary) -> Dictionary:
	return {}

func _emit_obtained(items: Array[Dictionary], epoch: int) -> void:
	if epoch != _item_epoch: return
	for item: Dictionary in items:
		item_obtained.emit(item["kind"], item["display_name"])

func interaction_targets() -> Array[Dictionary]:
	return []

## The user approved this ordinary-dialogue gate for world E/RB interactions.
## Dialogue advancement and cinematic/transaction save retries use their own paths.
func _world_dialogue_blocked() -> bool:
	return false

func _interaction_input() -> bool:
	return not _world_dialogue_blocked() and Input.is_action_just_pressed("interact")

func _target(id: String, kind: String, action: String, position: Vector2, radius: Variant, in_range: bool, available: bool, key_item: bool = false, range_kind: String = "circle") -> Dictionary:
	return {"id":id, "kind":kind, "action":action, "position":position, "radius":radius,
		"range_kind":range_kind, "in_range":in_range, "available":available and not get_tree().paused and not _world_dialogue_blocked() and player.life.can_control(), "key_item":key_item}
