# verify-suite: {"name":"formal UI style dusk progression key colours final glow and handwriting theme","path":"res://tests/test_ui_style.gd","marker":"UI_STYLE_TESTS checks=","fixed_fps":null,"timeout":60}
extends SceneTree
## UI-001: the formal style keeps EXP-002 sample two's rules (user G4).
const KEY_PALETTE: Dictionary = {"LIFE": "b8382c", "POSSIBILITY": "2f8f88", "GROWTH": "d9a03a", "OVERDRAFT": "6e1f3a", "DENY": "ff4636", "INK": "2b2420"}
const FONT_SHA256: String = "2d73eea94ad808999d90c0000c239a84a33b09d4bc6ab6c5b8bbf1eda8a7fc8b"
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error(message)

func time(day: int, progress: float, final_active: bool = false) -> Dictionary:
	return {"day": day, "day_progress": progress, "final_active": final_active}

func run() -> void:
	# Key colours are the documented hex values (EXP-002 README) and are constants.
	var constants: Dictionary = (load("res://ui/style/dusk_style.gd") as Script).get_script_constant_map()
	var hex: Dictionary = {}
	for key: String in KEY_PALETTE:
		hex[key] = (constants[key] as Color).to_html(false)
	check(hex == KEY_PALETTE, "key palette matches the chosen sample two %s" % [hex])
	# Dusk deepens strictly from day 1 to the final battle; final is full dusk.
	var stages: Array[Dictionary] = [time(1, 0.0), time(1, 1.0), time(2, 0.0), time(2, 1.0), time(3, 0.0), time(3, 1.0), time(3, 0.5, true)]
	var amounts: Array[float] = []
	for stage: Dictionary in stages:
		amounts.append(DuskStyle.dusk(stage))
	var increasing: bool = true
	for i: int in range(1, amounts.size()):
		increasing = increasing and amounts[i] > amounts[i - 1]
	check(increasing, "dusk deepens day by day %s" % [amounts])
	check(is_zero_approx(amounts[0]) and is_equal_approx(amounts[-1], 1.0), "day 1 dawn is plain paper, final battle is full dusk")
	check(DuskStyle.paper_color(time(1, 0.0)) == DuskStyle.PAPER_DAY and DuskStyle.paper_color(time(3, 0.5, true)) == DuskStyle.PAPER_DUSK, "paper tint follows the dusk")
	check(DuskStyle.glass(time(3, 0.5, true)) > DuskStyle.glass(time(1, 0.0)), "glass deepens with dusk")
	check(DuskStyle.edge_wash(time(1, 0.0)) == 0.0 and DuskStyle.edge_wash(time(3, 0.5, true)) > 0.4, "edge wash only once dusk sets in")
	# User G4: final-battle glow is 30% softer than the same dusk outside it.
	var final_glow: float = DuskStyle.glow_strength(time(3, 0.5, true))
	var same_dusk: float = 0.35 + 0.65 * DuskStyle.dusk(time(3, 0.5, true))
	check(is_equal_approx(final_glow, same_dusk * 0.7), "final battle glow is 70%% of the same dusk (%.3f)" % final_glow)
	check(is_equal_approx(DuskStyle.glow_strength(time(3, 1.0)), 0.35 + 0.65 * DuskStyle.dusk(time(3, 1.0))), "outside the final battle the glow is not reduced")
	check(is_equal_approx(DuskStyle.breath(time(1, 0.0), 1.0), 1.0) and DuskStyle.breath(time(3, 0.5, true), PI / 2.6) > 1.2, "breathing pulse only at dusk")
	check(DuskStyle.dusk({}) == 0.0 and DuskStyle.dusk(time(9, 2.0)) == DuskStyle.DAY_RANGE[3].y, "missing or out-of-range time input is clamped")
	# Ink jitter is deterministic per stroke seed.
	check(InkDraw.noise(3, 7) == InkDraw.noise(3, 7) and InkDraw.noise(3, 7) != InkDraw.noise(4, 7), "ink jitter is deterministic")
	# Theme: handwriting font, size scale, every button state.
	var theme: Theme = UiTheme.get_theme()
	check(theme.default_font != null and theme.default_font.resource_path == UiTheme.FONT_PATH, "theme uses the handwriting font")
	check(theme == UiTheme.get_theme(), "theme is built once and shared")
	var states_ok: bool = true
	for state: String in UiTheme.BUTTON_STATES:
		states_ok = states_ok and theme.has_stylebox(state, "Button")
	check(states_ok, "every button state has a style")
	check((theme.get_stylebox("hover", "Button") as StyleBoxFlat).bg_color.a > 0.0 and theme.get_stylebox("focus", "Button") is StyleBoxEmpty, "hover washes, focus leaves room for the ink underline")
	check(theme.get_color("font_disabled_color", "Button").a < 0.5, "disabled text is faded")
	check(UiTheme.SIZE_TITLE > UiTheme.SIZE_HEADING and UiTheme.SIZE_HEADING > UiTheme.SIZE_BODY and UiTheme.SIZE_BODY > UiTheme.SIZE_SMALL, "size scale descends")
	# The font file is the user-approved download, licence alongside.
	var font_hash: String = FileAccess.get_sha256(ProjectSettings.globalize_path(UiTheme.FONT_PATH))
	check(font_hash == FONT_SHA256, "font file matches the approved download")
	check(FileAccess.file_exists("res://assets/fonts/OFL.txt") and FileAccess.get_file_as_string("res://assets/fonts/OFL.txt").contains("SIL Open Font License"), "OFL licence ships with the font")
	print("UI_STYLE_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)
