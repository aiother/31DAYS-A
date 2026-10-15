class_name CheckpointLab
extends EnemyLab
@export var save_directory: String = "user://saves"
var store: SlotStore = SlotStore.new()
var slot: int = 0
var data: Dictionary = {}
var _death_settled: bool = false
var _loading: bool = false
var _reloading: bool = false
var _notice: String = ""
var _notice_remaining: float = 0.0
@onready var ui: CanvasLayer = $LifeUI

func _ready() -> void:
	super._ready()
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
	ui.call("show_slots")

func has_session() -> bool:
	return slot > 0 and not data.is_empty()

func _process(delta: float) -> void:
	super._process(delta)
	if has_session() and player.life.is_alive():
		data["play_seconds"] = float(data["play_seconds"]) + delta
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
	_death_settled = false
	player.reset_kinematics()
	if revive:
		player.life.revive()
	else:
		player.life.start_new_run()
		player.life.health = int(data["health"])
		player.life.health_changed.emit(player.life.health, player.life.config.max_health)
	player.possibility.balance = int(data["balance"])
	player.possibility.balance_changed.emit(player.possibility.balance, player.possibility.config.maximum)
	player.position = _checkpoint(str(data["checkpoint"])).config.spawn_position
	_update_flags()
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
	if not store.save_slot(slot, data):
		ui.call("save_failed", store.last_error)
		return false
	_notify(message)
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
