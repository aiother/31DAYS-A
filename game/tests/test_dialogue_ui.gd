# verify-suite: {"name": "formal dialogue slip, departure question and G-08 missed-rescue tag on real rooms", "path": "res://tests/test_dialogue_ui.gd", "marker": "DIALOGUE_UI_TESTS checks=", "fixed_fps": 60, "timeout": 180}
extends SceneTree
## UI-008: the formal dialogue (EXP-004 variant D), the rescue departure
## question and the G-08 tag on the real session and real Rooms, driven by
## real E / RB, Esc, keys and mouse. Assertions read what was drawn.
## (The forced first scene hiding the HUD is covered by test_field_room.)
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String
var stayed: int = 0
var left: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> bool:
	checks += 1
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error(message)
	return ok

func frames(count: int = 2) -> void:
	for i: int in range(count):
		# Tests teleport the player; skip camera smoothing for screen geometry.
		if is_instance_valid(session) and session.player != null:
			var camera: Camera2D = session.player.get_node_or_null("Camera2D") as Camera2D
			if camera != null:
				camera.reset_smoothing()
		await physics_frame
		await process_frame

func key(code: Key, hold: int = 0) -> void:
	for down: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await frames(1 + (hold if down else 0))
	await frames(1)

func pad(button: JoyButton, hold: int = 0) -> void:
	for down: bool in [true, false]:
		var event: InputEventJoypadButton = InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = down
		Input.parse_input_event(event)
		await frames(1 + (hold if down else 0))
	await frames(1)

func click(target: Control) -> void:
	var point: Vector2 = target.get_global_rect().get_center()
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for down: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = down
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		root.push_input(event, true)
		await frames(1)
	await frames(1)

func dialogue() -> FieldDialogue:
	return session.dialogue_ui

func said() -> Dictionary:
	return dialogue().drawn

func shown_text() -> String:
	return str(said().get("text", {}).get("text", ""))

func focus_text() -> String:
	var owner: Control = root.gui_get_focus_owner()
	return (owner as Button).text if owner is Button else ""

func quiet() -> void:
	session.player.set_physics_process(false)
	session.player.life.protection_remaining = 1000.0
	for node: Node in session.room.find_children("*", "Node", true, false):
		if node is ColorlessEntity or node is RoomRockfall:
			node.set_physics_process(false)

func enter(id: String) -> void:
	session._mount_room(id)
	session._bind_room()
	session.intro_active = false
	session.player.life.scripted_control_locked = false
	quiet()
	await frames(3)

func open(expired: bool) -> void:
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	root.size = Vector2i(1920, 1080)
	var value: Dictionary = session.store.fresh()
	value["events"][StartRoomSession.BIRTH] = true
	value["events"][WorldDayRules.ENABLED] = true
	value["events"][RavineRescueSession.SEEN] = true
	if expired:
		value["events"][WorldDayRules.expired_key(RavineRescueSession.RESCUE_ID)] = true
	check(session.store.save_slot(1, value) and session.start_slot(1, false), "isolated real save starts")
	await frames(4)
	dialogue().departure_cancelled.connect(func() -> void: stayed += 1)
	dialogue().departure_confirmed.connect(func() -> void: left += 1)

func close() -> void:
	paused = false
	session.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	OS.delay_msec(500)

func run() -> void:
	directory = OS.get_cache_dir().path_join("31days_dialogue_ui_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	await open(true)
	await slip_cases()
	await departure_cases()
	await missed_cases()
	await layout_cases()
	await close()
	await open(false)
	await not_expired_cases()
	await close()
	for file: String in (DirAccess.get_files_at(directory) if DirAccess.dir_exists_absolute(directory) else PackedStringArray()):
		DirAccess.remove_absolute(directory.path_join(file))
	DirAccess.remove_absolute(directory)
	print("DIALOGUE_UI_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func talk_to_seven() -> void:
	session.player.position = session.room.get_node("Seven").position
	await frames(2)
	await key(KEY_E)
	await frames(4)

func slip_cases() -> void:
	await enter(FieldSession.FIELD_ID)
	await talk_to_seven()
	var config: DialogueConfig = (session.room as FieldRoom).dialogue
	check(dialogue().active and said().get("paper") == Color(DuskStyle.PAPER_DUSK, 0.95), "E next to 7 opens the paper slip (variant D)")
	check(said().get("speaker", {}).get("text") == config.speaker and said().get("speaker", {}).get("color") == DuskStyle.PAPER_DAY, "the speaker sits on the ink tag in paper colour")
	var early: int = shown_text().length()
	await frames(10)
	check(shown_text().length() > early and shown_text().length() < dialogue().text.text.length(), "the line types out over time")
	check(said().get("text", {}).get("color") == DuskStyle.INK and said().get("hint") == "E / RB 继续 · 长按加速", "ink text with the key line under the slip")
	await key(KEY_ESCAPE)
	var frozen: String = shown_text()
	await frames(20)
	check(paused and shown_text() == frozen, "pausing keeps the line where it was")
	await key(KEY_ESCAPE)
	await frames(2)
	check(not paused and dialogue().active, "and the dialogue goes on after resuming")
	await key(KEY_E)
	check(shown_text() == dialogue().text.text and said().get("marker") == "continue", "one E finishes the line and shows the go-on mark")
	for i: int in range(12):
		if not dialogue().active:
			break
		await key(KEY_E)
	check(not dialogue().active and said().is_empty(), "after the last line the slip closes by itself")
	# Tap versus hold: a line too long to finish; how far the text grows over
	# the same 12 frames with interact released and with RB held down.
	var long_line: String = ""
	for i: int in range(12):
		long_line += "远处的风把灰吹过田埂"
	dialogue().start(config, PackedStringArray([long_line, long_line]))
	await frames(12)
	var before: int = shown_text().length()
	await frames(12)
	var tapped: int = shown_text().length() - before
	await key(KEY_E)
	await frames(12)
	var down: InputEventJoypadButton = InputEventJoypadButton.new()
	down.button_index = JOY_BUTTON_RIGHT_SHOULDER
	down.pressed = true
	Input.parse_input_event(down)
	await frames(4)
	before = shown_text().length()
	var line: int = dialogue().line_index
	await frames(12)
	var held: int = shown_text().length() - before
	var rushing: Variant = said().get("marker")
	var up: InputEventJoypadButton = down.duplicate() as InputEventJoypadButton
	up.pressed = false
	Input.parse_input_event(up)
	await frames(2)
	check(line == 1 and tapped > 0 and shown_text().length() < long_line.length() and held >= tapped * 3, "holding RB types faster than leaving it (%d vs %d chars in 12 frames)" % [held, tapped])
	check(rushing == "»»" and said().get("marker") == null, "while held the slip shows the speed-up mark, and not after release")
	dialogue().dismiss()
	session._end_dialogue()
	await frames(2)

func departure_cases() -> void:
	stayed = 0
	left = 0
	dialogue().show_departure()
	await frames(2)
	var buttons: Array = dialogue().choices.get_children()
	check(said().get("choices") == ["留下", "确认离开并放弃救助"] and focus_text() == "留下", "leaving asks with 留下 focused")
	var areas: Array = said().get("choice_rects", [])
	var box: Rect2 = said()["box"]
	var tag: Rect2 = said().get("speaker_rect", Rect2())
	check(areas.size() == 2 and not (areas[0] as Rect2).intersects(areas[1]) and box.encloses(areas[0]) and box.encloses(areas[1]) and not (areas[0] as Rect2).intersects(tag) and not (areas[1] as Rect2).intersects(tag), "the two buttons sit apart inside the slip, clear of the name")
	for move: Variant in [KEY_UP, KEY_DOWN, KEY_TAB, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN]:
		if move is int and move >= KEY_SPECIAL:
			await key(move)
		else:
			await pad(move)
	check(focus_text() == "留下" or focus_text() == "确认离开并放弃救助", "the focus stays on the two buttons")
	(buttons[0] as Button).grab_focus()
	paused = true
	await frames(2)
	await click(buttons[1])
	await key(KEY_ENTER)
	await pad(JOY_BUTTON_A)
	check(stayed == 0 and left == 0 and dialogue().confirming, "while paused neither button can be chosen")
	paused = false
	await frames(2)
	check(focus_text() == "留下", "resuming gives the focus back to 留下")
	await key(KEY_ENTER)
	check(stayed == 1 and left == 0, "Enter on 留下 keeps the rescue")
	dialogue().dismiss()
	session._end_dialogue()
	await frames(2)

func missed_cases() -> void:
	await enter(RavineRescueSession.RESCUE_ID)
	var survivor: Node2D = session.room.get_node("Survivor") as Node2D
	session.player.position = survivor.position + Vector2(2000, 0)
	await frames(10)
	check(dialogue().missed_age < 0.0 and dialogue().missed_drawn.is_empty(), "away from the expired survivor there is no tag")
	session.player.position = survivor.position + Vector2(40, 0)
	var seen: Dictionary = {}
	for i: int in range(300):
		await frames(1)
		if dialogue().missed_drawn.has("text"):
			seen = dialogue().missed_drawn.duplicate()
			break
	check(seen.get("text") == FieldDialogue.MISSED_TEXT, "near the expired survivor the tag appears")
	check(not dialogue().active and session.player.life.can_control(), "it never stops the player or opens a dialogue")
	var rect: Rect2 = seen.get("rect", Rect2())
	check(rect.end.y <= (seen["anchor"] as Vector2).y - FieldDialogue.MISSED_LIFT + 0.5 or rect.position.y >= (seen["anchor"] as Vector2).y, "it sits above the survivor (or below when above is taken)")
	await frames(int(FieldDialogue.MISSED_SECONDS * 60) + 10)
	check(dialogue().missed_drawn.is_empty() and dialogue().missed_age < 0.0, "it fades out after about four seconds")
	await frames(60)
	check(dialogue().missed_drawn.is_empty(), "staying nearby does not show it again")
	await enter(FieldSession.FIELD_ID)
	session.player.position = session.room.get_node("Seven").position
	await frames(30)
	check(dialogue().missed_drawn.is_empty() and dialogue().missed_age < 0.0, "next to 7 (the town rescue is not here) there is no tag")
	await enter(RavineRescueSession.RESCUE_ID)
	session.player.position = (session.room.get_node("Survivor") as Node2D).position + Vector2(40, 0)
	var again: bool = false
	for i: int in range(300):
		await frames(1)
		if dialogue().missed_drawn.has("text"):
			again = true
			break
	check(again, "coming back to the Room shows it once more")
	session.player.position = (session.room.get_node("Survivor") as Node2D).position
	check(session.interact_ravine_survivor() and dialogue().text.text.contains("太晚"), "talking still gives the expired line")
	await frames(2)
	check(dialogue().missed_drawn.is_empty(), "the tag steps aside while the dialogue is open")
	session._end_dialogue()
	await frames(2)

## Both window sizes: the slip with its key line, the G-08 tag, the HUD as
## drawn, the area name and the interaction prompt stay apart and on screen.
func layout_cases() -> void:
	var hud: FormalHud = session.ui.get("_hud") as FormalHud
	for window: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = window
		await enter(FieldSession.FIELD_ID)
		await frames(200)
		await talk_to_seven()
		await frames(4)
		var slip: Rect2 = (said()["box"] as Rect2).merge(said().get("hint_rect", said()["box"]))
		var ok: bool = Rect2(Vector2.ZERO, Vector2(1920, 1080)).encloses(slip)
		for name: String in ["emblem", "hint", "horizon", "warning", "final", "banner"]:
			if hud.drawn.has(name) and hud.drawn[name].has("rect"):
				ok = ok and not slip.intersects(hud.drawn[name]["rect"])
		check(ok, "%dx%d: the slip stays on screen and off the HUD" % [window.x, window.y])
		while dialogue().active:
			await key(KEY_E)
		await enter(RavineRescueSession.RESCUE_ID)
		session.player.position = (session.room.get_node("Survivor") as Node2D).position + Vector2(40, 0)
		var tag: Rect2 = Rect2()
		for i: int in range(300):
			await frames(1)
			if dialogue().missed_drawn.has("rect"):
				tag = dialogue().missed_drawn["rect"]
				break
		var clear: bool = tag.size != Vector2.ZERO and Rect2(Vector2.ZERO, Vector2(1920, 1080)).encloses(tag)
		for other: Rect2 in dialogue().missed_avoided():
			clear = clear and not tag.intersects(other)
		var label: Label = session.ui.get("_error_label") as Label
		if label.is_visible_in_tree():
			clear = clear and not tag.intersects(label.get_global_rect())
		check(clear, "%dx%d: the G-08 tag is on screen, clear of the HUD, area name and prompt" % [window.x, window.y])
		await frames(260)
	root.size = Vector2i(1920, 1080)

func not_expired_cases() -> void:
	await enter(RavineRescueSession.RESCUE_ID)
	session.player.position = (session.room.get_node("Survivor") as Node2D).position + Vector2(40, 0)
	await frames(240)
	check(dialogue().missed_drawn.is_empty() and dialogue().missed_age < 0.0, "a rescue that can still happen gets no G-08 tag")
