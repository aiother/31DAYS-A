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
	for index: int in range(4):
		preview.call("press", KEY_1 + index)
		await frames(2)
		check(preview.get("variant_index") == index, "variant %d selected" % (index + 1))
		check(preview.get("variant").get_script() == preview.VARIANTS[index], "variant %d script is live" % (index + 1))
		check(not String(preview.get("variant").call("title")).is_empty(), "variant %d has a title" % (index + 1))
		await walk_states(state, index)
	await combo_checks(state)
	clock_rules()
	dodge_rules()
	fracture_feedback()
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
	check(state.final_active and state.accelerate_left > 0.0 and state.final_remaining < HudState.FINAL_SECONDS and state.final_remaining > HudState.FINAL_SECONDS - 1.0, tag + "over 15 minutes: budget is 15:00 and already counting during the spin-down")
	check(state.day_remaining < 25.0 * 60.0 and state.day_remaining > 25.0 * 60.0 - 1.0, tag + "third-day time is not cut to 15:00 and keeps running (A-016)")
	preview.call("press", KEY_P)
	await frames(2)
	check(state.accelerate_left == 0.0 and state.final_remaining <= 552.0 and state.final_remaining > 550.0, tag + "under 15 minutes shows the real budget")
	preview.call("press", KEY_I)
	preview.call("press", KEY_R)
	await frames(1)

func combo_checks(state: HudState) -> void:
	preview.call("press", KEY_4)
	preview.call("press", KEY_R)
	await frames(3)
	check(not preview.get("distortion").visible, "combo: no distortion while possibility is not negative")
	for i: int in range(6):
		preview.call("press", KEY_A)
	for i: int in range(60):
		await process_frame
	check(state.balance == -3 and preview.get("distortion").visible and preview.get("distortion_strength") > 0.3, "combo: overdraft distorts the scene")
	preview.call("press", KEY_F)
	check(state.deny_kind == "闪避" and state.deny_left > 0.0, "combo: short dodge still flashes the container alongside the filter")
	preview.call("press", KEY_1)
	for i: int in range(60):
		await process_frame
	check(not preview.get("distortion").visible, "distortion stays a combo-variant idea")
	preview.call("press", KEY_4)
	var pause: Control = preview.get("pause")
	var before: float = state.day_remaining
	preview.call("press", KEY_ESCAPE)
	await frames(3)
	check(pause.visible and state.paused and pause.get("clock").visible, "Esc opens the pause menu with the clock on the right")
	check(is_equal_approx(state.day_remaining, before), "pause menu holds the day clock")
	var held: Array = [state.balance, state.health]
	preview.call("press", KEY_Q)
	preview.call("press", KEY_S)
	check([state.balance, state.health] == held, "debug keys are ignored while paused")
	pause.call("show_settings")
	await frames(2)
	check(pause.get("mode") == "settings" and not pause.get("clock").visible and pause.get("page").visible, "settings page covers the clock")
	preview.call("press", KEY_ESCAPE)
	await frames(2)
	check(pause.visible and pause.get("clock").visible and not pause.get("page").visible, "Esc on a secondary page returns to the clock")
	pause.call("show_confirm")
	await frames(2)
	check(pause.get("mode") == "confirm" and not pause.get("clock").visible, "save-and-quit confirm covers the clock")
	preview.call("press", KEY_ESCAPE)
	preview.call("press", KEY_ESCAPE)
	await frames(2)
	check(not pause.visible and not state.paused, "Esc closes the menu and resumes time")
	preview.call("press", KEY_R)

## Deterministic A-016 timing: the spin-down never decides whether real time runs.
func clock_rules() -> void:
	var s: HudState = HudState.new()
	s.start_final(1500.0)
	check(s.final_remaining == HudState.FINAL_SECONDS and s.accelerate_left == HudState.ACCELERATE_SECONDS, "clock: over 15 minutes starts at 15:00 with the spin-down")
	s.tick(1.0)
	check(is_equal_approx(s.final_remaining, 899.0) and is_equal_approx(s.day_remaining, 1499.0) and is_equal_approx(s.accelerate_left, 1.5), "clock: during the spin-down both real clocks run")
	s.paused = true
	s.tick(1.0)
	check(is_equal_approx(s.final_remaining, 899.0) and is_equal_approx(s.day_remaining, 1499.0) and is_equal_approx(s.accelerate_left, 1.5), "clock: pause holds real clocks and the spin-down alike")
	s.paused = false
	s.tick(1.5)
	check(is_equal_approx(s.final_remaining, 897.5) and is_equal_approx(s.day_remaining, 1497.5) and s.accelerate_left == 0.0, "clock: spin-down ends without a jump in real time")
	s.tick(1.0)
	check(is_equal_approx(s.final_remaining, 896.5) and is_equal_approx(s.day_remaining, 1496.5), "clock: after the spin-down both keep running")
	var short: HudState = HudState.new()
	short.start_final(552.0)
	check(short.accelerate_left == 0.0 and short.final_remaining == 552.0, "clock: under 15 minutes shows the real budget at once")
	short.tick(2.0)
	check(is_equal_approx(short.final_remaining, 550.0) and is_equal_approx(short.day_remaining, 550.0), "clock: under 15 minutes budget and third day run together")

## Deterministic chained dodge costs 1/2/3 and the A-018 shortfall boundary.
func dodge_rules() -> void:
	var s: HudState = HudState.new()
	s.balance = 2
	check(s.try_dodge() and s.balance == 1 and s.deny_left == 0.0, "dodge: first costs 1, balance 2 is enough")
	check(s.dodge_cost() == 2, "dodge: next chained dodge costs 2")
	check(s.try_dodge() and s.balance == -1 and s.deny_kind == "闪避" and s.deny_left > 0.0, "dodge: cost 2 with balance 1 overdraws and flashes though balance was positive")
	s.deny_left = 0.0
	s.balance = 3
	check(s.try_dodge() and s.balance == 0 and s.deny_left == 0.0, "dodge: third costs 3, balance equal to cost does not flash")
	check(not s.try_dodge() and s.balance == 0, "dodge: a fourth dodge in the chain is refused")
	s.tick(HudState.COMBO_RESET)
	check(s.dodge_cost() == 1, "dodge: chain resets after the combo window")
	s.balance = 1
	check(s.try_dodge() and s.balance == 0 and s.deny_left == 0.0, "dodge: after reset the cost is 1 again")
	s.balance = HudState.FLOOR + 1
	s.tick(HudState.COMBO_RESET)
	check(s.try_dodge() and s.balance == HudState.FLOOR, "dodge: may overdraw down to the floor")
	check(not s.try_dodge() and s.balance == HudState.FLOOR and s.deny_left > 0.0, "dodge: below the floor is refused and flashes")

## Old variant three keeps A-018 and G-02 at the zero boundaries.
func fracture_feedback() -> void:
	preview.call("press", KEY_3)
	preview.call("press", KEY_R)
	var state: HudState = preview.get("state")
	var fracture: Control = preview.get("variant")
	state.balance = 0
	check(fracture.call("blob_color", 1.0, 0.0).r > 0.7, "variant 3: empty glow still flashes red at balance 0")
	check(fracture.call("blob_color", 0.0, 0.0).r < 0.5, "variant 3: empty glow is grey without a flash")
	check(fracture.call("reach_text") == "范围 100%", "variant 3: reach shows with zero pearls")
	preview.call("press", KEY_X)
	preview.call("press", KEY_Z)
	check(fracture.call("reach_text") == "范围 100%", "variant 3: reach stays after 0 -> 1 -> 0 pearls")