# verify-suite: {"name": "checkpoint and resume integration", "path": "res://tests/test_checkpoints.gd", "marker": "CHECKPOINT_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var lab: CheckpointLab
var directory: String

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error(message)

func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func open_lab() -> void:
	lab = (load("res://debug/checkpoint_lab.tscn") as PackedScene).instantiate() as CheckpointLab
	lab.save_directory = directory
	root.add_child(lab)
	current_scene = lab
	await ticks(2)

func close_lab() -> void:
	paused = false
	lab.queue_free()
	await process_frame
	await process_frame

func run() -> void:
	directory = "user://tests/checkpoints_%d" % Time.get_ticks_usec()
	await open_lab()
	check(paused and not lab.has_session(), "launch waits for slot selection without starting gameplay")
	check(lab.start_slot(1, true), "new game creates selected slot")
	await ticks(10)
	check(not paused and lab.player.life.health == 3 and lab.player.possibility.balance == 3, "new game uses frozen initial resources")
	check(lab.player.life.protection_remaining == 0, "new game has no free revive protection")
	check(not lab.activate_checkpoint("unknown") and not lab.activate_checkpoint("graybox_start"), "invalid or duplicate activation ignored")
	lab.player.life.take_hit(1)
	lab.player.possibility.gain(5)
	check(lab.store.load_slot(1)["health"] == 2 and lab.store.load_slot(1)["balance"] == 8, "resource changes autosave immediately")
	lab.player.position = Vector2(608, 880)
	lab.player.velocity = Vector2.ZERO
	await ticks(8)
	check(lab.data["checkpoint"] == "graybox_forward", "real trigger automatically activates forward checkpoint")
	check(lab.player.life.health == 2 and lab.player.possibility.balance == 8, "checkpoint does not refill resources")
	check(lab.store.load_slot(1)["checkpoint"] == "graybox_forward", "checkpoint ID is on disk")
	check(lab.record_event("fixture_completed") and lab.store.load_slot(1)["events"]["fixture_completed"], "permanent event storage writes immediately")
	# Normal close/open preserves resources, spawns at checkpoint, no protection.
	check(lab.save_current(), "normal exit snapshot saves")
	await close_lab()
	await open_lab()
	check(lab.start_slot(1, false), "normal load reads selected slot")
	await ticks(2)
	check(lab.player.life.health == 2 and lab.player.possibility.balance == 8, "normal load preserves current resources without death penalty")
	check(lab.player.position.distance_to(Vector2(608, 896)) < 2 and lab.player.life.protection_remaining == 0, "normal load enters last checkpoint without invulnerability")
	check(lab.data["events"]["fixture_completed"], "event survives process-like scene close/open")
	(lab.get_node("StartCheckpoint") as GrayboxCheckpoint)._on_entered(lab.player)
	check(lab.data["checkpoint"] == "graybox_forward", "stale pre-teleport trigger cannot overwrite loaded checkpoint")
	# Enemy dies and emits actual reward before death settlement.
	var enemy: ColorlessEntity = lab.get_node("Enemies/GroundEntity") as ColorlessEntity
	var receiver: CombatHurtbox = enemy.get_node("GameplayRoot/Hurtbox") as CombatHurtbox
	receiver.receive_attack(20, Vector2.ZERO, lab.player, 900)
	check(enemy.state == ColorlessEntity.State.DEAD and lab.player.possibility.balance == 10, "production enemy defeat still awards possibility")
	lab.player.possibility.balance = 9
	lab.player.possibility.balance_changed.emit(9, 10)
	lab.player.life.take_hit(3)
	check(lab.store.load_slot(1)["balance"] == 4 and lab.store.load_slot(1)["health"] == 5, "death commits odd balance floor rounding and full respawn health")
	lab.player.life.take_hit(3)
	check(lab.store.load_slot(1)["balance"] == 4, "repeated damage cannot settle death twice")
	await ticks(90)
	check(paused and lab.player.life.state == PlayerLife.State.DEATH_MENU, "death feedback completes before menu pauses")
	var previous_id: int = lab.get_instance_id()
	lab.ui.call("restart_challenge")
	await ticks(3)
	lab = current_scene as CheckpointLab
	check(lab.get_instance_id() != previous_id and not paused, "death return reloads actual scene")
	check(lab.player.position.distance_to(Vector2(608, 896)) < 2, "death returns to last checkpoint rather than start: %s / %s" % [lab.player.position, lab.data["checkpoint"]])
	check(lab.player.life.health == 5 and lab.player.possibility.balance == 4, "revive applies stored settlement without a second penalty")
	check(lab.player.life.protection_remaining > 2.9, "death revive gives three-second protection")
	check(lab.data["events"]["fixture_completed"], "death keeps permanent event flags")
	enemy = lab.get_node("Enemies/GroundEntity") as ColorlessEntity
	check(enemy.health == 13 and enemy.state != ColorlessEntity.State.DEAD, "ordinary enemy instance resets on death")
	Input.action_press("attack")
	await ticks(1)
	Input.action_release("attack")
	check(lab.player.combat.is_attacking() and lab.player.life.protection_remaining > 2.8, "attacking preserves respawn protection")
	# Stop AI while exercising immediate resource/death policies.
	for actor: Node in lab.get_node("Enemies").get_children():
		actor.set_physics_process(false)
	lab.player.life.protection_remaining = 0
	lab.player.possibility.balance = -7
	lab.player.possibility.balance_changed.emit(-7, 10)
	check(lab.save_current() and lab.store.load_slot(1)["balance"] == -7, "normal save retains negative debt")
	lab.player.life.take_hit(5)
	check(lab.store.load_slot(1)["balance"] == 0, "death clears negative balance")
	# Closing during death and loading cannot restore pre-death resources.
	await close_lab()
	await open_lab()
	lab.start_slot(1, false)
	check(lab.player.life.health == 5 and lab.player.possibility.balance == 0 and lab.player.life.protection_remaining == 0, "reload after committed death cannot evade loss or gain free protection")
	# New game affects only chosen slot; loaded enemies are fresh.
	var slot_one: Dictionary = lab.store.load_slot(1)
	check(lab.start_slot(2, true), "new second slot accepted")
	await ticks(3)
	lab = current_scene as CheckpointLab
	check(lab.slot == 2 and lab.player.life.health == 3 and lab.player.possibility.balance == 3, "slot switch reloads a fresh challenge")
	check(lab.store.load_slot(1) == slot_one, "creating another slot preserves first slot")
	lab.ui.call("_confirm_new_slot", 1, true)
	check(paused and lab.ui.get("_mode") == "confirm_new" and lab.store.load_slot(1) == slot_one, "new game asks confirmation before overwriting existing slot")
	lab.ui.call("show_slots")
	var menu: VBoxContainer = lab.ui.get("_menu") as VBoxContainer
	check(menu.get_child(3).get_child_count() == 2, "empty slot displays label and new game without continue")
	lab.ui.call("resume_game")
	lab.ui.call("show_pause")
	var position_before: Vector2 = lab.player.position
	await ticks(3)
	check(paused and lab.player.position == position_before, "pause still freezes checkpoint scene")
	lab.ui.call("confirm_quit")
	check(paused and lab.ui.get("_mode") == "confirm_quit", "quit requires confirmation")
	lab.ui.call("_return_from_quit")
	lab.ui.call("resume_game")
	var before_reset: Dictionary = lab.data.duplicate(true)
	lab.debug_restart()
	check(lab.data == before_reset, "developer reset cannot silently destroy active slot")
	var real_directory: String = lab.store.directory
	lab.store.directory = real_directory.path_join("slot_2.json")
	lab.ui.call("confirm_quit")
	lab.ui.call("_save_and_quit")
	check(paused and not str(lab.ui.get("_error_label").text).is_empty(), "failed save-and-quit stays in menu with error feedback")
	lab.store.directory = real_directory
	await close_lab()
	var cleanup: SlotStore = SlotStore.new()
	cleanup.directory = directory
	for selected: int in range(1, 4):
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = ProjectSettings.globalize_path(cleanup.path_for(selected) + suffix)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	print("CHECKPOINT_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
