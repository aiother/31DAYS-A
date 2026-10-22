extends SceneTree
## EXP-004 smoke test (not part of the verification pipeline). Every dialogue
## variant, both G-08 presentations and both card looks, driven by real E / RB,
## Esc and A input; assertions read what was drawn. Run:
## Godot --headless --path game --fixed-fps 60 --script res://prototypes/EXP-004/tests/smoke_test.gd
var checks: int = 0
var failures: int = 0
var preview: Control

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func frames(count: int = 2) -> void:
	for i: int in range(count):
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

func dialogue() -> Control:
	return preview.get("dialogue") as Control

func card() -> Control:
	return preview.get("card") as Control

func said() -> Dictionary:
	return dialogue().get("drawn")

func focus_text() -> String:
	var owner: Control = root.gui_get_focus_owner()
	return (owner as Button).text if owner is Button else ""

func run() -> void:
	root.size = Vector2i(1920, 1080)
	preview = (load("res://prototypes/EXP-004/preview.tscn") as PackedScene).instantiate() as Control
	root.add_child(preview)
	await frames(3)
	for variant: int in range(3):
		await dialogue_cases(variant)
	for mode: int in range(2):
		await missed_cases(mode)
	for variant: int in range(2):
		await card_cases(variant)
	await layout_cases()
	print("EXP004_SMOKE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func dialogue_cases(variant: int) -> void:
	var name: String = ["A", "B", "C"][variant]
	await key(KEY_1 + variant)
	await key(KEY_T)
	await frames(10)
	var first: String = str(said().get("text", {}).get("text", ""))
	check(bool(dialogue().get("active")) and first.length() > 0 and first.length() < 37, name + ": the first line types out")
	check(said().get("speaker", {}).get("text") == "7" and said().get("variant") == ["A · 墨夜黑框", "B · 黄昏纸笺", "C · 黑纱纸边"][variant], name + ": the speaker name is drawn")
	var slow: int = first.length()
	await key(KEY_E, 10)
	check(str(said().get("text", {}).get("text", "")) == "你也是从荒地那边过来的吗？镇子里的人都病倒了，我一个人照顾不过来。", name + ": one press finishes the line")
	check(said().get("marker") == "continue", name + ": the go-on marker shows once the line is out")
	await key(KEY_E)
	await frames(6)
	var normal: int = str(said().get("text", {}).get("text", "")).length()
	await pad(JOY_BUTTON_RIGHT_SHOULDER, 8)
	var held: int = str(said().get("text", {}).get("text", "")).length()
	check(said().get("speaker", {}).get("text") == "主角" and held > normal, name + ": the next line, and holding RB speeds it up")
	await key(KEY_ESCAPE)
	var frozen: String = str(said().get("text", {}).get("text", ""))
	await frames(20)
	check(bool(preview.get("paused")) and preview.get("drawn").get("pause") != null and str(said().get("text", {}).get("text", "")) == frozen, name + ": pausing keeps the dialogue where it was")
	await key(KEY_ESCAPE)
	check(not bool(preview.get("paused")) and bool(dialogue().get("active")) and int(dialogue().get("index")) == 1, name + ": unpausing returns to the same line")
	for i: int in range(6):
		await key(KEY_E)
	check(not bool(dialogue().get("active")) and said().is_empty(), name + ": the dialogue closes by itself after the last line")
	await key(KEY_K)
	check(not bool(preview.get("drawn").get("hud")), name + ": a forced story scene hides the HUD")
	for i: int in range(6):
		await key(KEY_E)
	check(bool(preview.get("drawn").get("hud")), name + ": the HUD comes back afterwards")
	await key(KEY_L)
	for i: int in range(2):
		await key(KEY_E)
	check(said().get("choices") == ["留下", "确认离开并放弃救助"] and focus_text() == "留下", name + ": leaving asks, starting on 留下")
	await pad(JOY_BUTTON_A)
	check(preview.get("last_choice") == "stay" and not bool(dialogue().get("active")), name + ": A on 留下 keeps the rescue")
	await key(KEY_L)
	for i: int in range(2):
		await key(KEY_E)
	await key(KEY_RIGHT)
	await key(KEY_ENTER)
	check(preview.get("last_choice") == "leave", name + ": choosing to leave is explicit")
	check(slow < 37, name + ": typing started from nothing")

func missed_cases(mode: int) -> void:
	await key(KEY_4 + mode)
	await key(KEY_M)
	await frames(4)
	if mode == 0:
		check(bool(dialogue().get("active")) and bool(said().get("aside")) and said().get("speaker") == null, "G-08 as a line: an aside without a speaker")
		for i: int in range(3):
			await key(KEY_E)
		check(not bool(dialogue().get("active")), "G-08 line closes like any dialogue")
	else:
		var tag: Dictionary = preview.get("drawn").get("missed_tag", {})
		check(not bool(dialogue().get("active")) and tag.get("text") == "此处曾有人需要帮助\n更早到来，或许还来得及", "G-08 as a tag: shown without opening a dialogue")
		await frames(300)
		check(not preview.get("drawn").has("missed_tag"), "G-08 tag fades out by itself")

func card_cases(variant: int) -> void:
	await key(KEY_6 + variant)
	await key(KEY_C)
	check(card().get("drawn").get("phase") == "entering", "card %d slides in" % variant)
	await frames(40)
	var drawn: Dictionary = card().get("drawn")
	check(drawn.get("phase") == "staying" and drawn.get("title", {}).get("text") == "无色实体" and str(drawn.get("tips", {}).get("text", "")).begins_with("这里不安全"), "card %d shows the ordinary enemy" % variant)
	check((drawn["rect"] as Rect2).end.x <= 1920.0 and (drawn["rect"] as Rect2).position.y >= 0.0, "card %d sits at the top right on screen" % variant)
	await key(KEY_ESCAPE)
	var age: float = float(card().get("age"))
	await frames(30)
	check(is_equal_approx(float(card().get("age")), age), "card %d waits while paused" % variant)
	await key(KEY_ESCAPE)
	await frames(300)
	check(card().get("drawn").get("phase") == "hidden", "card %d leaves" % variant)
	await key(KEY_B)
	await frames(40)
	drawn = card().get("drawn")
	check(bool(drawn.get("boss")) and drawn.get("title", {}).get("text") == "渴望俯视" and (drawn["rect"] as Rect2).size.x > 440.0, "card %d Boss version is the larger card" % variant)
	await frames(300)

## Both window sizes: the box, the card, the G-08 tag, the wave line and the
## HUD stand-in apart and on screen.
func layout_cases() -> void:
	await key(KEY_5)
	for window: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = window
		for variant: int in range(3):
			await key(KEY_1 + variant)
			await key(KEY_T)
			await key(KEY_B)
			await key(KEY_M)
			await key(KEY_W)
			await frames(30)
			var box: Rect2 = said()["box"]
			var rects: Array[Rect2] = [box.grow_individual(0, 0, 0, 44), card().get("drawn")["settled"], preview.get("drawn")["missed_tag"]["rect"], preview.get("drawn")["wave"]["rect"], Rect2(40, 40, 280, 290)]
			var ok: bool = true
			for a: int in range(rects.size()):
				ok = ok and Rect2(0, 0, 1920, 1080).encloses(rects[a])
				for b: int in range(a + 1, rects.size()):
					ok = ok and not rects[a].intersects(rects[b])
			check(ok, "%dx%d variant %d: dialogue, card, G-08 tag, wave line and HUD apart" % [window.x, window.y, variant])
			for i: int in range(4):
				await key(KEY_E)
			await frames(300)
	root.size = Vector2i(1920, 1080)
