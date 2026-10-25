class_name CinematicDirector
extends RefCounted
## Session-owned flow, never an autoload and never saved into player data.
signal changed
signal started(state: Dictionary)
signal completed(state: Dictionary)
var overrides: Dictionary = {}
var history: Array[Dictionary] = []
var _host: WeakRef
var _sequence: CinematicSequence
var _content: RefCounted
var _phase: String = ""
var _remaining: float = 0.0
var _duration: float = 0.0
var _status: String = "idle"
var _frame: int = -1
var _values: Dictionary = {}
var _flags: Dictionary = {}
func bind(host: Node) -> void:
	_host = weakref(host)
func host() -> Node:
	return _host.get_ref() as Node if _host != null else null
func active(id: StringName = &"") -> bool:
	return _sequence != null and (id == &"" or _sequence.id == id)
func begin(id: StringName, entry_committed: bool = false) -> bool:
	if active(id): return false
	var next: CinematicSequence = (overrides[id] as CinematicSequence).duplicate(true) if overrides.has(id) else CinematicCatalog.sequence(id)
	assert(not next.skippable, "No new cinematic skipping has been approved")
	var owner: Node = host()
	var data: Variant = owner.get("data") if owner != null else null
	if data is Dictionary and not next.completion_events.is_empty():
		var saved: bool = bool(data.get("events",{}).get(next.completion_events[0],false))
		if saved and not (next.commit_point == &"entry" and entry_committed): return false
	if active(): finish()
	_sequence = next
	_phase = _sequence.phases[0] if not _sequence.phases.is_empty() else "content"
	_remaining = 0.0
	_duration = 0.0
	_values = {}
	_frame = -1
	_status = "playing"
	_content = _sequence.presentation.new() if _sequence.presentation != null else null
	if _content != null and _content.has_method("begin"): _content.call("begin", host(), self)
	_remember("begin")
	changed.emit()
	started.emit(state())
	return true
func finish(id: StringName = &"") -> void:
	if not active(id): return
	var done: Dictionary = state()
	if _content != null and _content.has_method("finish"): _content.call("finish", host(), self)
	_remember("finish")
	_sequence = null
	_content = null
	_phase = ""
	_remaining = 0.0
	_duration = 0.0
	_status = "idle"
	_values = {}
	changed.emit()
	completed.emit(done)
func reset() -> void:
	finish()
	_flags.clear()
func duration(id: StringName, seconds: float) -> void:
	if not active(id):
		if seconds <= 0.0: return
		if not begin(id): return
	if seconds <= 0.0:
		_remaining = 0.0
		return
	_duration = _sequence.duration_override if _sequence.duration_override >= 0.0 else maxf(0.0, seconds)
	_remaining = _duration
func remaining(id: StringName) -> float:
	return _remaining if active(id) else 0.0
func phase(id: StringName) -> int:
	return _sequence.phases.find(_phase) + 1 if active(id) else 0
func set_phase(id: StringName, index: int) -> void:
	if index == 0:
		finish(id)
		return
	if not active(id) and not begin(id): return
	assert(index <= _sequence.phases.size())
	_phase = _sequence.phases[index-1]
	_remaining = 0.0
	_duration = 0.0
	_status = "playing"
	if _content != null and _content.has_method("phase_started"): _content.call("phase_started", host(), self)
	_remember("phase")
	changed.emit()
func advance(delta: float) -> void:
	var owner: Node = host()
	if not active() or owner == null or owner.get_tree().paused: return
	var frame: int = Engine.get_physics_frames()
	if _frame == frame: return
	_frame = frame
	if _content != null and _content.has_method("ready_to_tick") and not _content.call("ready_to_tick", owner, self): return
	_remaining = maxf(0.0, _remaining - delta)
	if _content != null and _content.has_method("physics"): _content.call("physics", owner, self, delta)
func render_frame(delta: float) -> void:
	if active() and _content != null and _content.has_method("frame") and host() != null and not host().get_tree().paused:
		_content.call("frame", host(), self, delta)
func attempt_commit(id: StringName, write: Callable) -> bool:
	if host() == null or host().get_tree().paused: return false
	var result: bool = bool(write.call())
	if active(id):
		_status = "playing" if result else "waiting_save"
		if not result and _content != null and _content.has_method("save_failed"): _content.call("save_failed", host(), self)
		_remember("saved" if result else "save_failed")
		changed.emit()
	return result
func flag(key: String) -> bool:
	return bool(_flags.get(key, false))
func set_flag(key: String, value: bool) -> void:
	_flags[key] = value
func value(key: String, fallback: Variant = null) -> Variant:
	return _values.get(key, fallback)
func set_value(key: String, value: Variant) -> void:
	_values[key] = value
func state() -> Dictionary:
	return {"id":String(_sequence.id) if active() else "", "active":active(), "phase":_phase,
		"remaining":_remaining, "duration":_duration, "status":_status,
		"locks_control":_sequence.locks_control if active() else false,
		"hides_hud":_sequence.hides_hud if active() else false,
		"pauses_clock":_sequence.pauses_clock if active() else false,
		"story_music":_sequence.story_music if active() else false,
		"can_skip":false, "events":Array(_sequence.completion_events) if active() else [],
		"continuation":String(_sequence.continuation) if active() else "",
		"commit_point":String(_sequence.commit_point) if active() else ""}
func request_skip() -> bool:
	# No existing key sequence permits a skip. Replay and dialogue advance do not grant one.
	return false
func _remember(action: String) -> void:
	var row: Dictionary = state()
	row["action"] = action
	history.append(row)
	if history.size() > 128: history.pop_front()
