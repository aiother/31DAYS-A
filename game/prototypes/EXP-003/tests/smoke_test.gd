extends SceneTree
## EXP-003 smoke test (not part of the verification pipeline). Runs every main
## menu and slot variant through the flow and asserts what they drew. Run:
## Godot --headless --path game --script res://prototypes/EXP-003/tests/smoke_test.gd
var checks: int = 0
var failures: int = 0
var preview: Control
var quits: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func frames(count: int = 3) -> void:
	for i: int in range(count):
		await process_frame

func key(code: Key) -> void:
	for down: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await frames(1)

func screen() -> Control:
	return preview.get("screen") as Control

func focus_text() -> String:
	var owner: Control = root.gui_get_focus_owner()
	return (owner as Button).text if owner is Button else ""

func run() -> void:
	root.size = Vector2i(1920, 1080)
	preview = (load("res://prototypes/EXP-003/preview.tscn") as PackedScene).instantiate() as Control
	root.add_child(preview)
	preview.set("quit_handler", func() -> void: quits += 1)
	await frames()
	var data: RefCounted = preview.get("data")
	for i: int in range(3):
		preview.set("title_index", i)
		preview.call("open_title")
		await frames()
		var drawn: Dictionary = screen().get("drawn")
		check(drawn.has("title") and (drawn["title"]["rect"] as Rect2).end.y <= 1080.0 / 3.0 + 1.0 and drawn["title"]["text"] == "末日前31天", "variant %d draws the title in the upper third" % i)
		check(drawn.get("menu") == ["新游戏", "继续游戏", "设置", "退出游戏"] and focus_text() == "继续游戏", "variant %d menu order and default focus on continue" % i)
		check((drawn["title"]["rect"] as Rect2).size.y >= 1080.0 / 3.0 - 1.0, "variant %d title area is about a third of the screen" % i)
	data.call("clear_all")
	preview.call("open_title")
	await frames()
	check(screen().get("drawn")["menu"] == ["新游戏", "设置", "退出游戏"] and focus_text() == "新游戏", "continue is hidden without any save")
	data.call("reset")
	data.call("toggle_unreadable")
	preview.set("title_index", 2)
	preview.call("open_title")
	await frames()
	await key(KEY_RIGHT)
	check(focus_text() == "设置", "variant C's bottom menu moves with left / right")
	preview.set("title_index", 0)
	preview.call("open_title")
	await frames()
	# Real keys: down from continue to settings, back up, confirm continue.
	await key(KEY_DOWN)
	check(focus_text() == "设置", "arrow keys move through the main menu")
	await key(KEY_UP)
	await key(KEY_ENTER)
	await frames()
	check(preview.get("where") == "slots" and screen().get("mode") == "continue", "continue opens the slot screen")
	for v: int in range(2):
		preview.set("slot_index", v)
		preview.call("open_slots", "continue")
		await frames()
		var view: Control = screen()
		var cards: Dictionary = view.get("drawn")["cards"]
		check(cards[0]["state"] == "progress" and cards[1]["state"] == "completed" and cards[2]["state"] == "unreadable", "slot variant %d draws progress, completed and unreadable slots" % v)
		check(str(cards[0]["lines"][3]).contains("沟壑入口") and str(cards[0]["lines"][1]).contains("1:23:45"), "slot variant %d shows checkpoint and play time" % v)
		check(view.get("drawn")["focused"] == 0, "slot variant %d focuses the first loadable slot" % v)
		await key(KEY_RIGHT)
		check(view.get("drawn")["focused"] == 1, "slot variant %d right arrow moves to the next slot" % v)
		view.call("activate", 1)
		await frames()
		check(view.get("drawn").get("message") == "游戏已通关" and preview.get("where") == "slots", "slot variant %d completed slot answers 游戏已通关 and stays (A-013)" % v)
		preview.call("open_slots", "new")
		await frames()
		view = screen()
		check(view.get("drawn")["focused"] == 2 or view.get("drawn")["focused"] == 0, "slot variant %d new game focuses a sensible slot" % v)
		view.call("activate", 0)
		await frames()
		check(str(view.get("drawn").get("dialog", "")).contains("将覆盖此槽现有进度") and focus_text() == "返回", "slot variant %d overwrite asks first, default return" % v)
		await key(KEY_ESCAPE)
		await frames()
		check(not view.get("drawn").has("dialog") and preview.get("where") == "slots", "slot variant %d Esc cancels the overwrite" % v)
	data.call("toggle_unreadable")
	preview.call("open_slots", "new")
	await frames()
	screen().call("activate", 2)
	await frames()
	check(str(screen().get("drawn").get("dialog", "")) == "在槽三开始新游戏？", "empty slot asks a plain confirmation")
	await key(KEY_LEFT)
	await key(KEY_ENTER)
	await frames()
	check(preview.get("where") == "game" and int(screen().get("slot")) == 2 and data.call("state", 2) == "progress", "confirming starts a new game in that slot")
	# Every return-to-title path.
	for page: String in ["death", "end", "timeout"]:
		screen().call("open_page", page)
		await frames()
		check(screen().get("drawn").get("page") == page, "%s page opens" % page)
		var target: Button = null
		for button: Button in screen().get("buttons"):
			if button.text == "返回标题":
				target = button
		check(target != null, "%s page offers 返回标题" % page)
		target.pressed.emit()
		await frames()
		check(preview.get("where") == "title", "%s returns to the title" % page)
		preview.call("start_game", 0)
		await frames()
	check(data.call("state", 2) == "progress", "dying and timing out keep the slot in progress")
	await key(KEY_ESCAPE)
	await frames()
	check(screen().get("drawn").get("page") == "pause", "Esc in game opens pause")
	preview.call("open_title")
	await frames()
	var quit_button: Button = (screen().get("buttons") as Array)[-1]
	quit_button.pressed.emit()
	await frames()
	await key(KEY_LEFT)
	await key(KEY_ENTER)
	await frames()
	check(quits == 1, "quit asks first and then quits")
	print("EXP003_SMOKE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
