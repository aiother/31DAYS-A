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

## Review R2: waiting for effects to end is a condition, never a pause.
## The limit is fixed here, independent of the lives under test.
func ends(label: String) -> void:
	check(await settle(), label + ": every effect has ended, nothing left behind")

func pad(button: JoyButton, hold: int = 0) -> void:
	for down: bool in [true, false]:
		var event: InputEventJoypadButton = InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = down
		Input.parse_input_event(event)
		await frames(1 + (hold if down else 0))
	await frames(1)

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
	check(fx().get("style") == fx().FUSION and not preview.get("shake") and is_equal_approx(float(preview.get("hitstop_seconds")), preview.HITSTOP_DEFAULT), "the preview opens on the fusion look, longer hit-stop, no shake on ordinary hits")
	check(fx().z_index < (preview.get("warnings") as Node2D).z_index and (preview.get("hud_layer") as CanvasLayer).layer > 0, "warnings and the HUD layer sit above every effect")
	for style: int in range(4):
		await key([KEY_1, KEY_2, KEY_3, KEY_4][style])
		check(fx().get("style") == style, "key %d picks look %s" % [style + 1, fx().STYLES[style]])
		await style_cases(style)
	await lifetime_cases()
	await direction_cases()
	await pad_cases()
	await fusion_cases()
	await toggle_cases()
	await hitstop_cases()
	await bite_cases()
	await landing_bounce_cases()
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
	await ends("step 1")
	# Healing: a held loop that finishes, and one that is let go early.
	press(KEY_L, true)
	var loop: Dictionary = await wait_for("heal_loop", 40)
	check(not loop.is_empty() and is_inf(float(loop["life"])), name + ": holding L starts the healing loop")
	var done: Dictionary = await wait_for("heal_done", 140)
	press(KEY_L, false)
	await frames(2)
	check(not done.is_empty() and seen("heal_loop").is_empty(), name + ": a full hold finishes with the done effect and the loop stops")
	await ends("step 2")
	press(KEY_L, true)
	await wait_for("heal_loop", 40)
	await frames(10)
	press(KEY_L, false)
	await frames(3)
	check(seen("heal_loop").is_empty() and seen("heal_done").is_empty(), name + ": letting go early stops the loop without the done effect")
	await ends("step 3")
	# Hurt and revive.
	await key(KEY_T)
	check(not (await wait_for("hurt")).is_empty(), name + ": T shows the hurt effect")
	await ends("step 4")
	await key(KEY_Z)
	check(not (await wait_for("revive")).is_empty(), name + ": Z shows the revive effect")
	await ends("step 5")
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
	await ends("step 6")
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
	await ends("step 7")

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
		await ends("step 8")
	root.size = Vector2i(1920, 1080)

func perf_cases() -> void:
	revive_targets()
	fx().call("clear")
	for style: int in range(4):
		await key([KEY_1, KEY_2, KEY_3, KEY_4][style])
		revive_targets()
		preview.set("perf", {})
		await key(KEY_G)
		check((fx().get("drawn") as Array).filter(func(record: Dictionary) -> bool: return record["kind"] == "hit").size() >= 8, "%s: G strikes all eight targets at once" % fx().STYLES[style])
		for i: int in range(40):
			await frames(1)
		var perf: Dictionary = preview.get("perf")
		check(perf.has("avg_ms"), "%s: frame times recorded" % fx().STYLES[style])
		print("PERF %s avg=%.2fms peak=%.2fms (headless)" % [fx().STYLES[style], float(perf.get("avg_ms", -1.0)), float(perf.get("peak_ms", -1.0))])
		await ends("step 9")

## Look D: A's swing and hit with B's warm glow; every other effect is B.
func fusion_cases() -> void:
	await key(KEY_4)
	revive_targets()
	fx().call("clear")
	preview.set("hitstop", false)
	place(690.0)
	await frames(2)
	await key(KEY_J)
	var swing: Dictionary = await wait_for("swing")
	var hit: Dictionary = await wait_for("hit")
	check(swing.get("look") == 0 and hit.get("look") == 0 and (swing.get("glow", Color.TRANSPARENT) as Color).a > 0.0 and (hit.get("glow", Color.TRANSPARENT) as Color).a > 0.0, "D: the swing and the hit are A's, with B's warm glow under them")
	await ends("step 10")
	place(500.0)
	await key(KEY_K)
	var dodge: Dictionary = await wait_for("dodge")
	var spend: Dictionary = await wait_for("spend")
	check(dodge.get("look") == 1 and spend.get("look") == 1, "D: the dodge and the spend are B's")
	await ends("step 11")
	await key(KEY_T)
	check((await wait_for("hurt")).get("look") == 1, "D: being hurt is B's")
	await ends("step 12")
	preview.set("hitstop", true)

## Hit-stop is adjustable, and struck targets shiver while it lasts; hurt
## always shakes lightly, ordinary hits only when V turns it on.
func hitstop_cases() -> void:
	preview.set("hitstop", true)
	preview.set("shake", false)
	preview.set("hitstop_seconds", preview.HITSTOP_DEFAULT)
	await key(KEY_BRACKETRIGHT)
	var longer: float = preview.get("hitstop_seconds")
	for i: int in range(12):
		await key(KEY_BRACKETLEFT)
	var shortest: float = preview.get("hitstop_seconds")
	check(is_equal_approx(longer, preview.HITSTOP_DEFAULT + 0.02) and is_equal_approx(shortest, preview.HITSTOP_RANGE.x), "] lengthens and [ shortens the hit-stop, within its range")
	preview.set("hitstop_seconds", 0.12)
	revive_targets()
	fx().call("clear")
	place(690.0)
	var before: int = preview.get("hitstop_frames")
	await key(KEY_J)
	var shivered: bool = false
	var shook: bool = false
	for i: int in range(4):
		await frames(1)
		shivered = shivered or (not (preview.get("struck") as Array).is_empty() and float(preview.get("stop_left")) > 0.0)
		shook = shook or (preview.get("world") as Node2D).position != Vector2.ZERO
	for i: int in range(20):
		await frames(1)
		shook = shook or (preview.get("world") as Node2D).position != Vector2.ZERO
	var held: int = int(preview.get("hitstop_frames")) - before
	check(held >= 6 and held <= 9 and shivered and (preview.get("struck") as Array).is_empty(), "a 0.12 s hit-stop holds about 7 frames, the struck target shivers, then it is released (%d frames)" % held)
	check(not shook, "with V off an ordinary hit does not shake")
	await ends("step 13")
	await key(KEY_T)
	var hurt_shake: float = 0.0
	for i: int in range(6):
		await frames(1)
		hurt_shake = maxf(hurt_shake, (preview.get("world") as Node2D).position.length())
	check(hurt_shake > 0.0 and hurt_shake <= preview.HURT_SHAKE * 1.5, "being hurt still shakes, at half the old strength (%.1f px)" % hurt_shake)
	await ends("step 14")

## User feedback round two: the hit-stop is the blade caught in the target.
## The swing that landed stops where it met the target, together with the
## player and the target, then sweeps on.
func bite_cases() -> void:
	await key(KEY_4)
	preview.set("hitstop", true)
	preview.set("hitstop_seconds", 0.12)
	revive_targets()
	fx().call("clear")
	place(690.0)
	await frames(2)
	await key(KEY_J)
	var caught: Dictionary = {}
	for i: int in range(20):
		await frames(1)
		var swings: Array = seen("swing")
		if not swings.is_empty() and swings[0].get("held", false):
			caught = swings[0]
			break
	check(not caught.is_empty(), "the swing that lands is held at the moment of the hit")
	var body: Node2D = preview.get("player")
	var where: Vector2 = body.position
	var age: float = caught.get("age", -1.0)
	await frames(3)
	var still: Array = seen("swing")
	check(not still.is_empty() and float(still[0]["age"]) == age and still[0].get("held", false) and body.position == where and float(preview.get("stop_left")) > 0.0, "during the hit-stop the trail, the player and the target all stay put")
	var moved: bool = false
	for i: int in range(12):
		await frames(1)
		var after: Array = seen("swing")
		if not after.is_empty() and not after[0].get("held", false) and float(after[0]["age"]) > age:
			moved = true
			break
	check(moved, "after the hit-stop the trail sweeps on from where it was caught")
	await ends("step 15")
	# A miss is not held: the trail sweeps straight through.
	place(300.0)
	await frames(2)
	await key(KEY_J)
	var ever_held: bool = false
	for i: int in range(20):
		await frames(1)
		for record: Dictionary in seen("swing"):
			ever_held = ever_held or record.get("held", false)
	check(not ever_held, "a swing that hits nothing is never held")
	await ends("step 16")

## Bug from the user's trial: a downward attack started just before landing
## hit after the player touched down; the bounce then left the player marked
## on the floor, gravity never applied, and the player flew off the top.
func landing_bounce_cases() -> void:
	preview.set("hitstop", false)
	revive_targets()
	fx().call("clear")
	place(760.0)
	await key(KEY_SPACE)
	var body: Node2D = preview.get("player")
	for i: int in range(120):
		await frames(1)
		if (preview.get("velocity") as Vector2).y > 0.0 and body.position.y > preview.GROUND - 30.0:
			break
	press(KEY_S, true)
	await key(KEY_J)
	press(KEY_S, false)
	var bounced: bool = not (await wait_for("bounce", 20)).is_empty()
	var highest: float = body.position.y
	for i: int in range(150):
		await frames(1)
		highest = minf(highest, body.position.y)
	check(bounced, "a downward attack started just before landing still hits and bounces")
	check(highest > preview.GROUND - 300.0 and is_equal_approx(body.position.y, preview.GROUND) and preview.get("on_floor"), "the bounce rises a little and comes back down (highest %.0f px above the ground)" % (preview.GROUND - highest))
	await ends("step 17")
	preview.set("hitstop", true)

## Review R1 + R2: in every look, every effect really draws something visible
## (counted from the drawing helpers, not from metadata), and every finite
## effect ends within a fixed limit; loops end when stopped.
func lifetime_cases() -> void:
	var finite: Array = fx().LIFE.keys()
	# The preview ends the invulnerability loop when the mock has none left.
	preview.set("invuln_left", 1000.0)
	for style: int in range(4):
		preview.call("set_style", style)
		for kind: String in finite + fx().LOOPS:
			fx().call("clear")
			fx().call("spawn", kind, Vector2(960, 700), Vector2.RIGHT)
			await frames(3)
			var found: Array = seen(kind)
			var record: Dictionary = found[0] if not found.is_empty() else {}
			check(int(record.get("prims", 0)) > 0 and float(record.get("alpha", 0.0)) > 0.05, "%s · %s: draws visible primitives (%d)" % [fx().STYLES[style], kind, int(record.get("prims", 0))])
			if kind in fx().LOOPS:
				# The mock would start invulnerability again while it has time left.
				preview.set("invuln_left", 0.0)
				fx().call("stop", kind)
				await frames(1)
				check(seen(kind).is_empty() and not fx().call("active", kind), "%s · %s: the loop ends when stopped" % [fx().STYLES[style], kind])
				preview.set("invuln_left", 1000.0)
			else:
				var gone: bool = false
				for i: int in range(90):
					await frames(1)
					# Only this kind: the mock's own invulnerability loop stays on here.
					if not (fx().get("entries") as Array).any(func(entry: Dictionary) -> bool: return entry["kind"] == kind):
						gone = true
						break
				check(gone and seen(kind).is_empty(), "%s · %s: ends within 1.5 s and leaves nothing" % [fx().STYLES[style], kind])
	fx().call("clear")
	preview.set("invuln_left", 0.0)
	await frames(2)

## Review R1: the swing goes where the attack goes, judged from the points it
## actually drew -- forward, up, and (in the air) down, all by real input.
func swing_toward(direction: String) -> Vector2:
	for i: int in range(30):
		await frames(1)
		var found: Array = seen("swing")
		if not found.is_empty() and float(found[0]["age"]) > 0.05:
			return (found[0]["centroid"] as Vector2) - (found[0]["at"] as Vector2)
	return Vector2.INF

## The attack itself (0.26 s) outlasts the shorter trails; wait it out.
func attack_over() -> void:
	for i: int in range(40):
		if float(preview.get("attack_left")) <= 0.0:
			return
		await frames(1)

func direction_cases() -> void:
	preview.set("hitstop", false)
	for style: int in range(4):
		preview.call("set_style", style)
		var label: String = fx().STYLES[style]
		place(300.0)
		await frames(2)
		await key(KEY_J)
		var forward: Vector2 = await swing_toward("forward")
		check(forward.x > 20.0 and absf(forward.y) < forward.x, "%s: a plain attack sweeps forward (%s)" % [label, forward])
		await ends(label + " forward")
		await attack_over()
		place(300.0)
		await frames(2)
		press(KEY_W, true)
		await key(KEY_J)
		press(KEY_W, false)
		var upward: Vector2 = await swing_toward("up")
		check(upward.y < -20.0 and absf(upward.x) < -upward.y, "%s: W + J sweeps upward (%s)" % [label, upward])
		await ends(label + " up")
		await attack_over()
		place(300.0)
		await key(KEY_SPACE)
		await frames(8)
		press(KEY_S, true)
		await key(KEY_J)
		press(KEY_S, false)
		var downward: Vector2 = await swing_toward("down")
		check(downward.y > 20.0 and absf(downward.x) < downward.y, "%s: S + J in the air sweeps downward (%s)" % [label, downward])
		await ends(label + " down")
		await attack_over()
		for i: int in range(80):
			if preview.get("on_floor"):
				break
			await frames(1)
	preview.set("hitstop", true)

## Review R3: a controller alone reaches every effect.
func pad_cases() -> void:
	preview.set("hitstop", false)
	preview.set("poor", false)
	revive_targets()
	fx().call("clear")
	place(500.0)
	await pad(JOY_BUTTON_BACK)
	check(preview.get("poor"), "pad Back switches to too little possibility")
	await pad(JOY_BUTTON_B)
	check(not (await wait_for("poor_dodge")).is_empty(), "pad B then dodges into overdraft")
	await pad(JOY_BUTTON_BACK)
	check(not preview.get("poor"), "pad Back switches back")
	await ends("pad poor dodge")
	await pad(JOY_BUTTON_B)
	check(not (await wait_for("dodge")).is_empty(), "pad B dodges normally")
	await ends("pad dodge")
	await pad(JOY_BUTTON_Y, 120)
	check(not (await wait_for("heal_done", 40)).is_empty() or not seen("heal_loop").is_empty(), "pad Y held heals")
	await ends("pad heal")
	place(560.0)
	await pad(JOY_BUTTON_DPAD_UP)
	check(not (preview.get("projectiles") as Array).is_empty(), "pad up throws a projectile")
	var body: Node2D = preview.get("player")
	var reflected: bool = false
	for i: int in range(90):
		await frames(1)
		var shots: Array = preview.get("projectiles")
		if not shots.is_empty() and ((shots[0] as Dictionary)["at"] as Vector2).distance_to(body.position + Vector2(0, -48) + Vector2(70, 0)) < 60.0:
			await pad(JOY_BUTTON_X)
			reflected = not (await wait_for("reflect", 20)).is_empty()
			break
	check(reflected, "pad X reflects it")
	await ends("pad reflect")
	await pad(JOY_BUTTON_DPAD_LEFT)
	check(not (await wait_for("hurt")).is_empty(), "pad left shows being hurt")
	await ends("pad hurt")
	await pad(JOY_BUTTON_DPAD_RIGHT)
	check(not (await wait_for("revive")).is_empty(), "pad right shows the revive")
	await ends("pad revive")
	revive_targets()
	await pad(JOY_BUTTON_DPAD_DOWN)
	check(seen("hit").size() >= 8, "pad down strikes all eight targets")
	await ends("pad stress")
	var was: bool = preview.get("hitstop")
	await pad(JOY_BUTTON_START)
	check(preview.get("hitstop") != was, "pad Start switches the hit-stop")
	preview.set("hitstop_seconds", 0.10)
	await pad(JOY_BUTTON_RIGHT_STICK)
	var longer: float = preview.get("hitstop_seconds")
	await pad(JOY_BUTTON_LEFT_STICK)
	await pad(JOY_BUTTON_LEFT_STICK)
	check(is_equal_approx(longer, 0.12) and is_equal_approx(float(preview.get("hitstop_seconds")), 0.08), "pad stick presses lengthen and shorten the hit-stop")
	preview.set("hitstop", true)
	preview.set("hitstop_seconds", preview.HITSTOP_DEFAULT)

