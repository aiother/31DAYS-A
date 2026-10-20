extends SceneTree
## EXP-002 minimal proof: both samples load, dusk deepens day by day, every
## screen and state can be shown. Run:
## Godot --headless --path game --script res://prototypes/EXP-002/tests/smoke_test.gd
const HudState = preload("res://prototypes/EXP-001/hud_state.gd")
const Style = preload("res://prototypes/EXP-002/style.gd")
const Ink = preload("res://prototypes/EXP-002/ink.gd")
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
	preview = (load("res://prototypes/EXP-002/preview.tscn") as PackedScene).instantiate() as Control
	root.add_child(preview)
	await frames(2)
	var state: HudState = preview.get("state")
	var style: Style = preview.get("style")
	check(Ink.noise(3, 7) == Ink.noise(3, 7) and Ink.noise(3, 7) != Ink.noise(4, 7), "ink jitter is deterministic per stroke")
	for sample: int in range(2):
		preview.call("press", KEY_1 + sample)
		await dusk_rules(state, style, sample)
		await hud_states(state, sample)
	await pause_menu(state)
	await dialog_sample()
	print("EXP002_SMOKE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)

func dusk_rules(state: HudState, style: Style, sample: int) -> void:
	var tag: String = "sample %d: " % (sample + 1)
	check(style.sample == sample and not String(preview.get("title_label").text).is_empty(), tag + "selected and titled")
	style.progressive = true
	var amounts: Array[float] = []
	for stage: int in [KEY_5, KEY_6, KEY_7, KEY_8]:
		preview.call("press", stage)
		await frames(2)
		amounts.append(style.dusk(state))
	check(amounts[0] < amounts[1] and amounts[1] < amounts[2] and amounts[2] < amounts[3], tag + "dusk deepens from day 1 to the final battle %s" % [amounts])
	var top: float = 0.55 if sample == 0 else 1.0
	check(is_equal_approx(amounts[3], top), tag + "final battle reaches this sample's full dusk")
	check(style.paper_color(state) != Style.PAPER_DAY, tag + "paper takes on dusk colour at the end")
	check(style.glow_strength(state) > 0.0 and (style.glass(state) > 0.0) == (sample == 1), tag + "glow everywhere, glass only in the dusk-led sample")
	preview.call("press", KEY_0)
	var fixed: Array[float] = []
	for stage: int in [KEY_5, KEY_8]:
		preview.call("press", stage)
		await frames(1)
		fixed.append(style.dusk(state))
	check(not style.progressive and is_equal_approx(fixed[0], fixed[1]), tag + "progression can be switched off for a fixed blend")
	preview.call("press", KEY_0)
	preview.call("press", KEY_5)

func hud_states(state: HudState, sample: int) -> void:
	var tag: String = "sample %d: " % (sample + 1)
	var hud: Control = preview.get("hud")
	preview.call("press", KEY_R)
	for i: int in range(6):
		preview.call("press", KEY_Q)
	check(state.health == 1, tag + "last life")
	preview.call("press", KEY_E)
	preview.call("press", KEY_E)
	check(hud.call("deny_flash") >= 0.0 and state.deny_left > 0.0, tag + "short heal flashes the ring")
	for i: int in range(5):
		preview.call("press", KEY_A)
	for i: int in range(60):
		await process_frame
	check(state.balance < 0 and preview.get("distortion").visible, tag + "overdraft distorts the scene under the HUD")
	preview.call("press", KEY_R)
	preview.call("press", KEY_G)
	preview.call("press", KEY_D)
	await frames(2)
	check(not hud.get("flyers").is_empty(), tag + "gain flies into the ring")
	preview.call("press", KEY_X)
	preview.call("press", KEY_C)
	preview.call("press", KEY_Y)
	await frames(1)
	check(state.warning_active(), tag + "three-minute warning")
	preview.call("press", KEY_U)
	await frames(2)
	check(state.day == 2 and hud.get("banner_left") > 0.0, tag + "day change banner")
	preview.call("press", KEY_8)
	await frames(2)
	check(state.final_active and state.accelerate_left > 0.0, tag + "final countdown spin-down shows")
	preview.call("press", KEY_R)
	await frames(1)

func pause_menu(state: HudState) -> void:
	var pause: Control = preview.get("pause")
	preview.call("press", KEY_ESCAPE)
	await frames(2)
	check(pause.visible and pause.call("clock_visible") and state.paused, "Esc opens the pause menu with the clock")
	check(pause.get("buttons")[0].call("ink_state") == "focus", "first option shows the selected ink state")
	var held: Array = [state.balance, state.health]
	preview.call("press", KEY_Q)
	preview.call("press", KEY_S)
	check([state.balance, state.health] == held, "debug keys are ignored while paused")
	pause.get("buttons")[1].emit_signal("pressed")
	await frames(2)
	check(pause.get("mode") == "settings" and not pause.call("clock_visible") and pause.get("page_buttons").size() == 1, "settings covers the clock")
	preview.call("press", KEY_ESCAPE)
	await frames(2)
	check(pause.call("clock_visible") and pause.get("page_buttons").is_empty(), "Esc returns to the clock")
	pause.get("buttons")[2].emit_signal("pressed")
	await frames(2)
	check(pause.get("mode") == "confirm" and pause.get("page_buttons").size() == 2, "save-and-quit confirm covers the clock")
	preview.call("press", KEY_ESCAPE)
	preview.call("press", KEY_ESCAPE)
	await frames(2)
	check(not pause.visible and not state.paused, "Esc closes and resumes time")

func dialog_sample() -> void:
	var dialog: Control = preview.get("dialog")
	preview.call("press", KEY_K)
	await frames(2)
	var buttons: Array = dialog.get("buttons")
	check(dialog.visible and buttons[1].call("ink_state") == "focus", "dialog opens with the safe option selected")
	check(buttons[2].call("ink_state") == "disabled" and buttons[0].call("ink_state") == "normal", "dialog shows normal and disabled button states")
	# Held-down state; toggle mode lets the test hold it without a real mouse.
	buttons[0].toggle_mode = true
	buttons[0].set_pressed_no_signal(true)
	check(buttons[0].call("ink_state") == "pressed", "pressed button state")
	buttons[0].set_pressed_no_signal(false)
	buttons[0].toggle_mode = false
	preview.call("press", KEY_ESCAPE)
	await frames(1)
	check(not dialog.visible, "Esc closes the dialog")
