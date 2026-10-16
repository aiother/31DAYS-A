class_name ParasiteSession
extends CampWavesSession
const PARASITE_ID: String = "HD_20003_1"
const PARASITE_CHECKPOINT: String = "HD_20003_1_N003"
const PARASITE_INTRO: String = "HD_20003_1_N001:intro"
const PARASITE_DEFEATED: String = "HD_20003_1_N001:defeated"
const PARASITE_PASSAGE: String = "HD_20003_1_N002"
const DODGE_PENDING: String = "HD_20003_1:dodge_growth_pending"
const PARASITE_ROOM: PackedScene = preload("res://world/rooms/hd_20003_1.tscn")
var _parasite_intro_remaining: float = 0.0
var _parasite_victory_pending: bool = false

func _room_scenes() -> Dictionary:
	var scenes: Dictionary = super._room_scenes().duplicate()
	scenes[PARASITE_ID] = PARASITE_ROOM
	return scenes

func _supports_checkpoint(id: String) -> bool:
	return id == PARASITE_CHECKPOINT or super._supports_checkpoint(id)

func _checkpoint_room(id: String) -> String:
	return PARASITE_ID if id == PARASITE_CHECKPOINT else super._checkpoint_room(id)

func _bind_room() -> void:
	super._bind_room()
	if room is ParasiteRoom:
		var actor: ParasiteBoss = room.get_node("Boss") as ParasiteBoss
		actor.target = player
		if not actor.defeated.is_connected(_on_parasite_defeated):
			actor.defeated.connect(_on_parasite_defeated)

func _restore(snapshot: Dictionary, revive: bool) -> void:
	super._restore(snapshot, revive)
	if room is ParasiteRoom and has_session():
		_enter_parasite()

func _change_room(target: String) -> void:
	super._change_room(target)
	if room is ParasiteRoom and has_session():
		_enter_parasite()

func activate_checkpoint(id: String) -> bool:
	# Boss entry must remain retryable if its first write fails.
	var previous: String = str(data.get("checkpoint", ""))
	var result: bool = super.activate_checkpoint(id)
	if not result and id == PARASITE_CHECKPOINT and previous != id and has_session():
		data["checkpoint"] = previous
		_update_flags()
	return result

func _enter_parasite() -> void:
	var arena: ParasiteRoom = room as ParasiteRoom
	var actor: ParasiteBoss = arena.get_node("Boss") as ParasiteBoss
	if data["checkpoint"] != PARASITE_CHECKPOINT and not activate_checkpoint(PARASITE_CHECKPOINT):
		return
	if bool(data["events"].get(PARASITE_DEFEATED, false)):
		actor.mark_defeated()
		arena.set_opened(true)
		return
	if actor.state != ParasiteBoss.State.WAITING:
		return
	if bool(data["events"].get(PARASITE_INTRO, false)):
		actor.start_combat()
		return
	data["events"][PARASITE_INTRO] = true
	if not save_current("Boss首次演出已记录"):
		data["events"].erase(PARASITE_INTRO)
		return
	intro_active = true
	_parasite_intro_remaining = actor.config.intro_duration
	player.reset_kinematics()
	player.life.scripted_control_locked = true
	ui.call("show_enemy_intro", actor.config.intro_duration, "寄生同伴者\n\n弹反连续投射物。\n被命中会让Boss恢复生命。")

func _physics_process(delta: float) -> void:
	if _parasite_intro_remaining > 0.0:
		if not player.life.is_alive():
			_end_parasite_intro(false)
			return
		_parasite_intro_remaining = maxf(0.0, _parasite_intro_remaining - delta)
		var actor: ParasiteBoss = room.get_node("Boss") as ParasiteBoss
		var elapsed: float = actor.config.intro_duration - _parasite_intro_remaining
		var camera: Camera2D = player.get_node("Camera2D") as Camera2D
		camera.offset = Vector2(sin(elapsed*75)* (5 if elapsed>2 else 1),0)
		var throw_progress: float = clampf((elapsed-2.0)/2.0,0,1)
		(room.get_node("Corpse") as Node2D).position = actor.position+Vector2(-60-throw_progress*200,-64-sin(throw_progress*PI)*120)
		(actor.get_node("VisualRoot") as Node2D).rotation = sin(elapsed*16)*0.025 if elapsed<2 else 0
		(actor.get_node("VisualRoot") as Node2D).scale = Vector2(1,0.72) if elapsed<2 else Vector2.ONE
		if _parasite_intro_remaining == 0.0:
			_end_parasite_intro(true)
		return
	super._physics_process(delta)
	if room is ParasiteRoom and has_session() and Input.is_action_just_pressed("interact"):
		if _parasite_victory_pending:
			save_current("胜利状态已保存")
		else:
			_enter_parasite()

func _end_parasite_intro(start: bool) -> void:
	_parasite_intro_remaining = 0.0
	intro_active = false
	player.life.scripted_control_locked = false
	(player.get_node("Camera2D") as Camera2D).offset = Vector2.ZERO
	(room.get_node("Boss/VisualRoot") as Node2D).scale = Vector2.ONE
	(room.get_node("Boss/VisualRoot") as Node2D).rotation = 0
	if start:
		(room.get_node("Boss") as ParasiteBoss).start_combat()

func _on_parasite_defeated() -> void:
	(room as ParasiteRoom).clear_projectiles()
	_parasite_victory_pending = true
	save_current("寄生同伴者已击败 · 木板落下")

func _on_death() -> void:
	if room is ParasiteRoom:
		(room as ParasiteRoom).clear_projectiles()
	super._on_death()

func restart_challenge() -> void:
	if _parasite_victory_pending and not save_current("胜利状态已保存"):
		return
	super.restart_challenge()

func save_current(message: String = "已自动保存") -> bool:
	if not _parasite_victory_pending:
		return super.save_current(message)
	var before: Dictionary = data["events"].duplicate()
	var old_day: int = int(data.get("day",1))
	data["day"] = maxi(old_day,3)
	for key: String in [PARASITE_DEFEATED, PARASITE_PASSAGE, DODGE_PENDING]:
		data["events"][key] = true
	if not super.save_current(message):
		data["events"] = before
		data["day"] = old_day
		return false
	_parasite_victory_pending = false
	if room is ParasiteRoom:
		(room as ParasiteRoom).set_opened(true,true)
	ui.call("save_failed", "")
	return true

func _on_room_exit(target: String) -> void:
	if room is ParasiteRoom and not bool(data.get("events", {}).get(PARASITE_DEFEATED, false)):
		_notify("击败寄生同伴者后通路开启")
		return
	super._on_room_exit(target)

func _process(delta: float) -> void:
	super._process(delta)
	if room is ParasiteRoom and has_session():
		$Instructions/Help.text = "左右/向上攻击弹反投射物 · 被命中会让Boss吸血\n击败后木板落下 · 沿平台寻找逆时战场破洞"
		if _parasite_intro_remaining > 0.0:
			$Instructions/Help.text = "寄生同伴者 · 首次登场"
		elif _parasite_victory_pending or (room.get_node("Boss") as ParasiteBoss).state == ParasiteBoss.State.WAITING:
			$Instructions/Help.text = "进度保存尚未完成 · 按 E / RB 重试"
