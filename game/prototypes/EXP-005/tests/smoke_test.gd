extends SceneTree
## EXP-005 smoke test (not part of the verification pipeline). Every look,
## every effect, driven by real key input; assertions read what was drawn.
## Run: Godot --headless --path game --fixed-fps 60 --script res://prototypes/EXP-005/tests/smoke_test.gd
var checks: int = 0
var failures: int = 0
var preview: Control

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error(message)

func frames(count: int = 1) -> void:
	for i: int in range(count):
		await process_frame

func press(code: Key, down: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func key(code: Key, hold: int = 0) -> void:
	press(code, true)
	await frames(1 + hold)
	press(code, false)
	await frames(1)

func fx() -> Node2D:
	return preview.get("effects")

func seen(kind: String) -> Array:
	return (fx().get("drawn") as Array).filter(func(record: Dictionary) -> bool: return record["kind"] == kind)

## Waits up to `limit` frames for a kind to be drawn; returns its record.
func wait_for(kind: String, limit: int = 30) -> Dictionary:
	for i: int in range(limit):
		var found: Array = seen(kind)
		if not found.is_empty():
			return found[0]
		await frames(1)
	return {}

func settle(limit: int = 120) -> bool:
	for i: int in range(limit):
		if (fx().get("entries") as Array).is_empty():
			return true
		await frames(1)
	return false

func place(x: float) -> void:
	var body: Node2D = preview.get("player")
	body.position = Vector2(x, preview.GROUND)
	preview.set("velocity", Vector2.ZERO)
	preview.set("on_floor", true)
	preview.set("facing", 1.0)

func revive_targets() -> void:
	for target: Dictionary in preview.get("targets"):
		target["hp"] = 3
		target["dead"] = 0.0

func run() -> void:
	root.size = Vector2i(1920, 1080)
	preview = (load("res://prototypes/EXP-005/preview.tscn") as PackedScene).instantiate() as Control
	root.add_child(preview)
	await frames(3)
	check(fx().z_index < (preview.get("warnings") as Node2D).z_index and (preview.get("hud_layer") as CanvasLayer).layer > 0, "warnings and the HUD layer sit above every effect")
	for style: int in range(3):
		await key([KEY_1, KEY_2, KEY_3][style])
		check(fx().get("style") == style, "key %d picks look %s" % [style + 1, fx().STYLES[style]])
		await style_cases(style)
	await toggle_cases()
	await layout_cases()
	await perf_cases()
	print("EXP005_SMOKE_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func style_cases(style: int) -> void:
	var name: String = fx().STYLES[style]
	preview.set("hitstop", false)
	preview.set("shake", false)
	revive_targets()
	fx().call("clear")
	place(690.0)
	await frames(2)
	# Attack next to a target: trail, hit and the target's flash.
	await key(KEY_J)
	var swing: Dictionary = await wait_for("swing")
	var hit: Dictionary = await wait_for("hit")
	check(swing.get("style") == style and hit.get("style") == style and not seen("enemy_hurt").is_empty(), name + ": J draws the trail, the hit and the target flash")
	check((swing.get("color", Color.TRANSPARENT) as Color).a > 0.0 and (hit.get("color", Color.TRANSPARENT) as Color).a > 0.0, name + ": they are visible")
	# Two more blows defeat it: burst and possibility gain.
	await frames(20)
	await key(KEY_J)
	await frames(20)
	await key(KEY_J)
	var death: Dictionary = await wait_for("enemy_death")
	check(not death.is_empty() and not (await wait_for("gain")).is_empty(), name + ": the third blow defeats the target with a burst and a gain")
	check(await settle(), name + ": every one-shot effect ends and leaves nothing behind")
	# Dodge with and without enough possibility.
	place(500.0)
	await key(KEY_K)
	var dodge: Dictionary = await wait_for("dodge")
	check(not dodge.is_empty() and not dodge.get("poor", true) and not seen("spend").is_empty(), name + ": K dodges with after-images and a possibility spend")
	check(not (await wait_for("invuln")).is_empty(), name + ": invulnerability shows while it lasts")
	check(await settle(), name + ": and ends with it")
	await key(KEY_P)
	await key(KEY_K)
	var poor: Dictionary = await wait_for("poor_dodge")
	check(not poor.is_empty() and poor.get("poor", false) and (poor.get("color", Color.WHITE) as Color).is_equal_approx(Color(DuskStyle.LIFE, (poor["color"] as Color).a)), name + ": with too little possibility the dodge breaks up in vermilion")
	await key(KEY_P)
	await settle()
	# Healing: a held loop that finishes, and one that is let go early.
	press(KEY_L, true)
	var loop: Dictionary = await wait_for("heal_loop", 40)
	check(not loop.is_empty() and is_inf(float(loop["life"])), name + ": holding L starts the healing loop")
	var done: Dictionary = await wait_for("heal_done", 140)
	press(KEY_L, false)
	await frames(2)
	check(not done.is_empty() and seen("heal_loop").is_empty(), name + ": a full hold finishes with the done effect and the loop stops")
	await settle()
	press(KEY_L, true)
	await wait_for("heal_loop", 40)
	await frames(10)
	press(KEY_L, false)
	await frames(3)
	check(seen("heal_loop").is_empty() and seen("heal_done").is_empty(), name + ": letting go early stops the loop without the done effect")
	await settle()
	# Hurt and revive.
	await key(KEY_T)
	check(not (await wait_for("hurt")).is_empty(), name + ": T shows the hurt effect")
	await settle()
	await key(KEY_Z)
	check(not (await wait_for("revive")).is_empty(), name + ": Z shows the revive effect")
	await settle()
	# Downward attack onto a target: bounce.
	revive_targets()
	place(760.0)
	await key(KEY_SPACE)
	var body: Node2D = preview.get("player")
	for i: int in range(90):
		await frames(1)
		if (preview.get("velocity") as Vector2).y > 0.0 and body.position.y > preview.GROUND - 110.0:
			break
	press(KEY_S, true)
	await key(KEY_J)
	press(KEY_S, false)
	check(not (await wait_for("bounce", 20)).is_empty(), name + ": a downward attack on a target bounces")
	await settle()
	# A projectile knocked back.
	revive_targets()
	place(560.0)
	await key(KEY_R)
	var reflected: bool = false
	for i: int in range(90):
		await frames(1)
		var shots: Array = preview.get("projectiles")
		if not shots.is_empty() and ((shots[0] as Dictionary)["at"] as Vector2).distance_to(body.position + Vector2(0, -48) + Vector2(70, 0)) < 60.0:
			await key(KEY_J)
			reflected = not (await wait_for("reflect", 20)).is_empty()
			break
	check(reflected, name + ": attacking a projectile reflects it")
	await settle()

func toggle_cases() -> void:
	revive_targets()
	fx().call("clear")
	place(690.0)
	preview.set("hitstop", false)
	preview.set("shake", false)
	await key(KEY_H)
	await key(KEY_V)
	check(preview.get("hitstop") and preview.get("shake"), "H and V switch hit-stop and shake on")
	var before: int = preview.get("hitstop_frames")
	await key(KEY_J)
	var shook: bool = false
	for i: int in range(20):
		await frames(1)
		shook = shook or (preview.get("world") as Node2D).position != Vector2.ZERO
	check(int(preview.get("hitstop_frames")) - before >= 3 and shook, "with both on, a hit holds the world a few frames and shakes it")
	await key(KEY_H)
	await key(KEY_V)
	await frames(20)
	before = preview.get("hitstop_frames")
	revive_targets()
	await key(KEY_J)
	shook = false
	for i: int in range(20):
		await frames(1)
		shook = shook or (preview.get("world") as Node2D).position != Vector2.ZERO
	check(int(preview.get("hitstop_frames")) == before and not shook, "with both off, a hit neither holds nor shakes")

## Both window sizes: effects stay on screen and clear of the mock HUD.
func layout_cases() -> void:
	for window: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = window
		revive_targets()
		fx().call("clear")
		place(690.0)
		await key(KEY_J)
		await frames(4)
		await key(KEY_T)
		await frames(4)
		var view: Rect2 = Rect2(Vector2.ZERO, Vector2(1920, 1080))
		var ok: bool = not (fx().get("drawn") as Array).is_empty()
		for record: Dictionary in fx().get("drawn"):
			var at: Vector2 = record["at"]
			ok = ok and view.has_point(at) and not preview.HUD_RECT.grow(60).has_point(at)
		check(ok, "%dx%d: effects are on screen and away from the HUD" % [window.x, window.y])
		await settle()
	root.size = Vector2i(1920, 1080)

func perf_cases() -> void:
	revive_targets()
	fx().call("clear")
	for style: int in range(3):
		await key([KEY_1, KEY_2, KEY_3][style])
		revive_targets()
		preview.set("perf", {})
		await key(KEY_G)
		check((fx().get("drawn") as Array).filter(func(record: Dictionary) -> bool: return record["kind"] == "hit").size() >= 8, "%s: G strikes all eight targets at once" % fx().STYLES[style])
		for i: int in range(40):
			await frames(1)
		var perf: Dictionary = preview.get("perf")
		check(perf.has("avg_ms"), "%s: frame times recorded" % fx().STYLES[style])
		print("PERF %s avg=%.2fms peak=%.2fms (headless)" % [fx().STYLES[style], float(perf.get("avg_ms", -1.0)), float(perf.get("peak_ms", -1.0))])
		await settle()
