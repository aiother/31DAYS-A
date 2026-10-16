extends SceneTree
var checks: int = 0
var failures: int = 0
var session: RescueBattlefieldSession
var directory: String
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("PASS: "+message)
func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
func press_interact() -> void:
	Input.action_press("interact")
	await ticks(2)
	Input.action_release("interact")
	await ticks(2)
func live_ids() -> Array[int]:
	var result: Array[int] = []
	for child: Node in session.room.get_node("Enemies").get_children():
		if child is ColorlessEntity and (child as ColorlessEntity).health>0:
			result.append(child.get_instance_id())
	return result
func run() -> void:
	directory = "user://tests/ten_clear_presentation_%d" % Time.get_ticks_usec()
	session = (load("res://world/rescue_battlefield_session.tscn") as PackedScene).instantiate() as RescueBattlefieldSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	var snapshot: Dictionary = session.store.fresh()
	snapshot["checkpoint"] = TrenchPassageSession.PASSAGE_CHECKPOINT
	snapshot["day"] = 3
	snapshot["balance"] = -9
	for key: String in [TrenchPassageRoom.CLEARED,TrenchPassageRoom.CHALLENGE,TrenchPassageRoom.FORWARD]:
		snapshot["events"][key] = true
	check(session.store.save_slot(1,snapshot) and session.start_slot(1,false),"fresh checkpoint save loads for real input reproduction")
	session._change_room(BattlefieldSession.BATTLEFIELD_ID)
	session.player.position = Vector2(640,896)
	session.player.reset_kinematics()
	await ticks(3)
	for child: Node in session.room.get_node("Enemies").get_children():
		child.set_physics_process(false)
	var original: Array[int] = live_ids()
	check(original.size()==3,"original hostile instances are recorded before rescue")
	session.player.life.health = 1
	session.player.life.take_hit(1)
	await ticks(100)
	check(session.cinematic==RescueBattlefieldSession.Cinematic.DIALOGUE,"real-time entrance reaches first dialogue line")
	await press_interact()
	check(session.dialogue_ui.line_index==1,"real interact input advances to second line")
	await ticks(50)
	await press_interact()
	check(session.cinematic==RescueBattlefieldSession.Cinematic.SLASH and session.rescue_overlay.slash.visible,"real interact input completes dialogue and triggers slash")
	check(live_ids().is_empty() and (session.room as RescueBattlefieldRoom).rescue_kill_count==original.size(),"slash actually kills every recorded original enemy")
	var disabled: bool = true
	for child: Node in session.room.get_node("Enemies").get_children():
		if child is ColorlessEntity:
			var enemy: ColorlessEntity = child as ColorlessEntity
			disabled = disabled and enemy.health==0 and not enemy.hurtbox.accepts_hits and not enemy.health_label.visible and (enemy.get_node("BodyCollision") as CollisionShape2D).disabled
	check(disabled,"original enemy health collisions and health labels are disabled after kill")
	await ticks(26)
	check(session.cinematic==RescueBattlefieldSession.Cinematic.AFTERMATH and live_ids().is_empty(),"at old immediate-respawn moment arena now visibly stays cleared")
	check(session.rescue_overlay.caption.text.contains("已秒杀 3") and not session.rescue_overlay.slash.visible,"unobscured clear-result caption confirms the actual kill count")
	var remaining: float = session.cinematic_remaining
	paused = true
	await ticks(8)
	check(session.cinematic_remaining==remaining and live_ids().is_empty(),"pause cannot advance clear hold or spawn reinforcements")
	paused = false
	Input.action_press("interact")
	Input.action_press("attack")
	await ticks(8)
	Input.action_release("interact")
	Input.action_release("attack")
	check(session.cinematic==RescueBattlefieldSession.Cinematic.AFTERMATH and live_ids().is_empty(),"held or repeated actions cannot skip visible clear hold")
	await ticks(ceili(session.cinematic_remaining*60)+3)
	check(session.cinematic==RescueBattlefieldSession.Cinematic.REINFORCEMENTS and live_ids().is_empty(),"new-wave warning starts only after cleared hold and successful save")
	check(session.rescue_overlay.caption.text.contains("下一波") and session.data["events"].get(RescueBattlefieldSession.RESCUE_DONE_EVENT,false),"warning names a separate next wave and rescue is saved")
	await ticks(20)
	check(live_ids().is_empty() and session.cinematic==RescueBattlefieldSession.Cinematic.REINFORCEMENTS,"warning keeps arena empty before new enemies enter")
	await ticks(ceili(session.cinematic_remaining*60)+2)
	var newcomers: Array[int] = live_ids()
	var all_new: bool = newcomers.size()==3
	for id: int in newcomers:
		all_new = all_new and not original.has(id)
	check(all_new and session.cinematic==RescueBattlefieldSession.Cinematic.NONE,"only after warning three distinct new hostile instances arrive")
	var card: Control = session.ui.get("_enemy_intro") as Control
	check(card.visible and (card.get_child(0) as Label).text.contains("新一波"),"new-wave arrival is explicitly identified during restored gameplay")
	check(session.player.life.health==1 and session.player.possibility.balance==10 and not session.player.life.scripted_control_locked,"clear presentation preserves no-heal full-cap reward and control restoration")
	paused = false
	session.queue_free()
	await ticks(2)
	await create_timer(0.2).timeout
	for suffix: String in ["", ".bak", ".tmp"]:
		var path: String = directory.path_join("slot_1.json")+suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("TEN_CLEAR_PRESENTATION_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
