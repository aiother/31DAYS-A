extends SceneTree
## EXP-002 minimal proof: every check runs for BOTH samples, and asserts what
## the views actually drew (drawn records), not only node visibility. Run:
## Godot --headless --path game --script res://prototypes/EXP-002/tests/smoke_test.gd
const HudState = preload("res://prototypes/EXP-001/hud_state.gd")
const Style = preload("res://prototypes/EXP-002/style.gd")
const Ink = preload("res://prototypes/EXP-002/ink.gd")
## Documented key palette (README); must not change with day or sample.
const KEY_PALETTE: Dictionary = {"life": "b8382c", "possibility": "2f8f88", "overdraft": "6e1f3a", "growth": "d9a03a", "deny": "ff4636"}
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
		var tag: String = "sample %d: " % (sample + 1)
		await dusk_rules(state, style, sample, tag)
		await key_palette(tag)
		await hud_states(state, tag)
		await final_countdowns(state, tag)
		await pause_menu(state, sample, tag)
		await dialog_sample(sample, tag)
	print("EXP002_SMOKE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)

func dusk_rules(state: HudState, style: Style, sample: int, tag: String) -> void:
	check(style.sample == sample and not String(preview.get("title_label").text).is_empty(), tag + "selected and titled")
	style.progressive = true
	var amounts: Array[float] = []
	for stage: int in [KEY_5, KEY_6, KEY_7, KEY_8]:
		preview.call("press", stage)
		await frames(2)
		amounts.append(style.dusk(state))
	check(amounts[0] < amounts[1] and amounts[1] < amounts[2] and amounts[2] < amounts[3], tag + "dusk deepens from day 1 to the final battle %s" % [amounts])
	check(is_equal_approx(amounts[3], 0.55 if sample == 0 else 1.0), tag + "final battle reaches this sample's full dusk")
	check(style.paper_color(state) != Style.PAPER_DAY, tag + "paper takes on dusk colour at the end")
	check(style.glow_strength(state) > 0.0 and (style.glass(state) > 0.0) == (sample == 1), tag + "glow everywhere, glass only in the dusk-led sample")
	# User G4: final-battle glow is 30% softer than the same dusk outside it.
	var final_glow: float = style.glow_strength(state)
	var unscaled: float = (0.35 + 0.65 * style.dusk(state)) * (0.7 if sample == 0 else 1.0)
	check(state.final_active and is_equal_approx(final_glow, unscaled * 0.7), tag + "final battle glow is 30%% softer than at the same dusk (%.3f vs %.3f)" % [final_glow, unscaled])
	preview.call("press", KEY_0)
	var fixed: Array[float] = []
	for stage: int in [KEY_5, KEY_8]:
		preview.call("press", stage)
		await frames(1)
		fixed.append(style.dusk(state))
	check(not style.progressive and is_equal_approx(fixed[0], fixed[1]), tag + "progression can be switched off for a fixed blend")
	preview.call("press", KEY_0)
	preview.call("press", KEY_5)

## The colours the HUD actually draws with are the documented ones, on day 1
## and in the final battle alike.
func key_palette(tag: String) -> void:
	var hud: Control = preview.get("hud")
	for stage: int in [KEY_5, KEY_8]:
		preview.call("press", KEY_R)
		preview.call("press", stage)
		await frames(2)
		var palette: Dictionary = hud.get("drawn").get("palette", {})
		var hex: Dictionary = {}
		for key: String in palette:
			hex[key] = (palette[key] as Color).to_html(false)
		check(hex == KEY_PALETTE, tag + "key palette unchanged at stage %d: %s" % [stage - KEY_0, hex])

func hud_states(state: HudState, tag: String) -> void:
	var hud: Control = preview.get("hud")
	preview.call("press", KEY_R)
	preview.call("press", KEY_5)
	await frames(2)
	var drawn: Dictionary = hud.get("drawn")
	check(drawn.get("font", "") == Style.HAND_FONT_PATH, tag + "HUD draws with the handwriting font (user G4)")
	preview.call("press", KEY_J)
	await frames(2)
	check(hud.get("drawn").get("font", "x") != Style.HAND_FONT_PATH, tag + "J switches back to the built-in font for comparison")
	preview.call("press", KEY_J)
	await frames(2)
	drawn = hud.get("drawn")
	check(drawn.has("emblem") and drawn["emblem"]["life"] == HudState.MAX_HEALTH and drawn["emblem"]["reach"] == 100, tag + "emblem draws life and zero-pearl reach")
	check(drawn.get("horizon", "") == state.clock_text(), tag + "horizon draws the clock time")
	for i: int in range(6):
		preview.call("press", KEY_Q)
	preview.call("press", KEY_E)
	preview.call("press", KEY_E)
	await frames(1)
	check(state.health == 3 and state.deny_left > 0.0 and hud.call("deny_flash") >= 0.0, tag + "short heal flashes the ring")
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
	preview.call("press", KEY_Y)
	await frames(2)
	check(hud.get("drawn").get("warning", false), tag + "three-minute warning is drawn")
	preview.call("press", KEY_U)
	await frames(2)
	check(hud.get("drawn").get("banner", 0) == 2, tag + "day change banner is drawn")

func final_countdowns(state: HudState, tag: String) -> void:
	var hud: Control = preview.get("hud")
	preview.call("press", KEY_R)
	preview.call("press", KEY_8)
	await frames(2)
	var spin: Dictionary = hud.get("drawn").get("final", {})
	check(spin.get("label", "") == "时间加速……", tag + "over 15 minutes first shows the spin-down")
	state.tick(HudState.ACCELERATE_SECONDS + 0.5)
	await frames(2)
	var settled: Dictionary = hud.get("drawn").get("final", {})
	check(settled.get("label", "") == "最终战倒计时" and String(settled.get("digits", "")).begins_with("14:"), tag + "after the spin-down the real 15-minute budget counts %s" % [settled])
	preview.call("press", KEY_9)
	await frames(2)
	var short: Dictionary = hud.get("drawn").get("final", {})
	check(state.final_active and state.final_from < HudState.FINAL_SECONDS and state.accelerate_left == 0.0, tag + "key 9 starts a short-budget final battle")
	check(String(short.get("label", "")).contains("余时不足") and short.get("digits", "") == "09:12" and short.get("color", Color.BLACK) == Style.LIFE, tag + "under 15 minutes draws the real budget in the warning colour %s" % [short])
	preview.call("press", KEY_R)

func pause_menu(state: HudState, sample: int, tag: String) -> void:
	var pause: Control = preview.get("pause")
	preview.call("press", KEY_6)
	preview.call("press", KEY_ESCAPE)
	await frames(2)
	var drawn: Dictionary = pause.get("drawn")
	check(pause.visible and state.paused and drawn.get("sample", -1) == sample, tag + "Esc opens the pause menu in this sample")
	check(drawn.get("font", "") == Style.HAND_FONT_PATH and (pause.get("buttons")[0] as Control).get_theme_font("font").resource_path == Style.HAND_FONT_PATH, tag + "pause menu text and buttons use the handwriting font")
	check(drawn.has("clock") and drawn["clock"]["time"] == state.clock_text() and drawn["clock"]["day"] == 2, tag + "the clock is drawn with the current time and day")
	check(pause.get("buttons")[0].call("ink_state") == "focus", tag + "first option shows the selected ink state")
	var held: Array = [state.balance, state.health]
	preview.call("press", KEY_Q)
	preview.call("press", KEY_S)
	check([state.balance, state.health] == held, tag + "debug keys are ignored while paused")
	pause.get("buttons")[1].emit_signal("pressed")
	await frames(2)
	drawn = pause.get("drawn")
	check(drawn.get("settings", false) and not drawn.has("clock") and pause.get("page_buttons").size() == 1, tag + "settings page is drawn over the clock")
	preview.call("press", KEY_ESCAPE)
	await frames(2)
	check(pause.get("drawn").has("clock") and pause.get("page_buttons").is_empty(), tag + "Esc returns to the clock")
	pause.get("buttons")[2].emit_signal("pressed")
	await frames(2)
	drawn = pause.get("drawn")
	check(drawn.get("confirm", false) and not drawn.has("clock") and pause.get("page_buttons").size() == 2, tag + "save-and-quit confirm is drawn over the clock")
	preview.call("press", KEY_ESCAPE)
	preview.call("press", KEY_ESCAPE)
	await frames(2)
	check(not pause.visible and not state.paused, tag + "Esc closes and resumes time")

func dialog_sample(sample: int, tag: String) -> void:
	var dialog: Control = preview.get("dialog")
	preview.call("press", KEY_K)
	await frames(2)
	var buttons: Array = dialog.get("buttons")
	check(dialog.visible and dialog.get("drawn").get("sample", -1) == sample and dialog.get("drawn").get("title", "") != "", tag + "dialog is drawn in this sample")
	check(buttons[1].call("ink_state") == "focus", tag + "dialog opens with the safe option selected")
	check(buttons[2].call("ink_state") == "disabled" and buttons[0].call("ink_state") == "normal", tag + "normal and disabled button states")
	# Headless has no real pointer, so deliver the enter/exit notifications directly.
	var hover_box: StyleBox = (buttons[0] as Control).get_theme_stylebox("hover")
	check(hover_box is StyleBoxFlat and (hover_box as StyleBoxFlat).bg_color.a > 0.0, tag + "hover draws a warm wash")
	buttons[0].notification(Control.NOTIFICATION_MOUSE_ENTER)
	await frames(1)
	check(buttons[0].call("ink_state") == "hover", tag + "hover state under the mouse")
	buttons[0].notification(Control.NOTIFICATION_MOUSE_EXIT)
	await frames(1)
	buttons[0].toggle_mode = true
	buttons[0].set_pressed_no_signal(true)
	check(buttons[0].call("ink_state") == "pressed", tag + "pressed button state")
	buttons[0].set_pressed_no_signal(false)
	buttons[0].toggle_mode = false
	preview.call("press", KEY_ESCAPE)
	await frames(1)
	check(not dialog.visible, tag + "Esc closes the dialog")
