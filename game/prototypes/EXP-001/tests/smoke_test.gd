extends SceneTree
## EXP-001 minimal proof: the preview loads, every variant draws every state.
## Run: Godot --headless --path game --script res://prototypes/EXP-001/tests/smoke_test.gd
const HudState = preload("res://prototypes/EXP-001/hud_state.gd")
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

func frames(count: int) -> void:
	for i: int in range(count):
		await process_frame

func run() -> void:
	preview = (load("res://prototypes/EXP-001/hud_preview.tscn") as PackedScene).instantiate() as Control
	root.add_child(preview)
	await frames(2)
	var state: HudState = preview.get("state")
	check(state != null, "preview owns a simulated state")
	for index: int in range(3):
		preview.call("press", KEY_1 + index)
		await frames(2)
		check(preview.get("variant_index") == index, "variant %d selected" % (index + 1))
		check(preview.get("variant").get_script() == preview.VARIANTS[index], "variant %d script is live" % (index + 1))
		check(not String(preview.get("variant").call("title")).is_empty(), "variant %d has a title" % (index + 1))
		await walk_states(state, index)
	print("EXP001_SMOKE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)

func walk_states(state: HudState, index: int) -> void:
	var tag: String = "variant %d: " % (index + 1)
	preview.call("press", KEY_R)
	for i: int in range(6):
		preview.call("press", KEY_Q)
	await frames(2)
	check(state.health == 1, tag + "life stops at the last point and shows the vignette")
	preview.call("press", KEY_E)
	check(state.health == 3 and state.balance == 0, tag + "heal spends 3 and restores 2")
	preview.call("press", KEY_E)
	check(state.deny_left > 0.0 and state.deny_kind == "恢复", tag + "heal without enough possibility flashes (A-018)")
	await frames(2)
	preview.call("press", KEY_F)
	check(state.balance == -1 and state.deny_kind == "闪避", tag + "short dodge overdraws and flashes")
	for i: int in range(12):
		preview.call("press", KEY_A)
	check(state.balance == HudState.FLOOR, tag + "overdraft stops at the floor")
	await frames(2)
	preview.call("press", KEY_R)
	preview.call("press", KEY_G)
	preview.call("press", KEY_G)
	check(state.maximum() == HudState.BASE_MAX + 2 * HudState.GROWTH_STEP, tag + "growth adds extra capacity")
	preview.call("press", KEY_D)
	for i: int in range(4):
		preview.call("press", KEY_D)
	await frames(3)
	check(state.balance == state.maximum(), tag + "gain fills into growth capacity")
	check(not preview.get("overlay").get("flyers").is_empty(), tag + "gain spawns fly-in light")
	for i: int in range(5):
		preview.call("press", KEY_X)
	check(state.pearls == HudState.PEARL_MAX and state.reach_percent() == 120, tag + "pearls cap at four, reach 120%")
	preview.call("press", KEY_C)
	preview.call("press", KEY_V)
	check(state.show_medkit and state.medkits == 3, tag + "optional medkit count toggles")
	await frames(2)
	preview.call("press", KEY_Y)
	await frames(1)
	check(state.warning_active(), tag + "three-minute warning shows before day change")
	preview.call("press", KEY_U)
	await frames(2)
	check(state.day == 2 and preview.get("overlay").get("banner_left") > 0.0, tag + "day change shows the banner")
	preview.call("press", KEY_T)
	if index == 1:
		var tab: InputEventKey = InputEventKey.new()
		tab.keycode = KEY_TAB
		tab.pressed = true
		preview.call("_unhandled_input", tab)
		await frames(2)
		check(preview.get("variant").get("expanded"), tag + "Tab expands the compact time (A-015 ③)")
		tab.pressed = false
		preview.call("_unhandled_input", tab)
	preview.call("press", KEY_O)
	await frames(2)
	check(state.final_active and state.accelerate_left > 0.0 and state.final_remaining == HudState.FINAL_SECONDS, tag + "over 15 minutes spins down visually to 15:00")
	check(is_equal_approx(state.day_remaining, 25.0 * 60.0), tag + "accelerate does not consume third-day time (A-016)")
	preview.call("press", KEY_P)
	await frames(2)
	check(state.accelerate_left == 0.0 and state.final_remaining <= 552.0 and state.final_remaining > 550.0, tag + "under 15 minutes shows the real budget")
	preview.call("press", KEY_I)
	preview.call("press", KEY_R)
	await frames(1)
