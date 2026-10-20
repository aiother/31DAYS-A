extends Control
## EXP-002 preview: visual direction samples on the EXP-001 variant-four layout.
## Simulation state is reused read-only from EXP-001; raw keycodes only.
const HudState = preload("res://prototypes/EXP-001/hud_state.gd")
const DISTORTION: Shader = preload("res://prototypes/EXP-001/overdraft_distortion.gdshader")
const Style = preload("res://prototypes/EXP-002/style.gd")
const HudView = preload("res://prototypes/EXP-002/hud_view.gd")
const PauseView = preload("res://prototypes/EXP-002/pause_view.gd")
const DialogSample = preload("res://prototypes/EXP-002/dialog_sample.gd")
const HELP: String = """1 / 2  切换样张（手札为主 / 黄昏为主）      H  显示或隐藏说明
5 / 6 / 7  跳到第1日 / 第2日 / 第3日      0  开关“随天数变化”
8 / 9  最终战：开战时第3日余25分钟（加速定格到15:00）/ 只余9分12秒（余时不足警示）
Esc 暂停菜单（左选项、右时钟；设置等二级页盖住时钟，Esc 返回）    K 通用对话框与按钮样式    J 手写字体开/关
Q 受伤   E 尝试恢复   F 尝试闪避（连闪成本1/2/3）   A / S / D 消耗1 / 获得1 / 获得3
G 成长上限   Z / X 珍珠 -1 / +1   C / V 药包显示 / 数量   R 重置
T 时间 +1分钟   Y 换日前3分钟   U 立即换日   L 时间 ×1/×30   空格 暂停时间"""

var state: HudState = HudState.new()
var style: Style = Style.new()
var distortion: ColorRect
var distortion_strength: float = 0.0
var hud: Control
var pause: Control
var dialog: Control
var title_label: Label
var help_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	distortion = ColorRect.new()
	distortion.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	distortion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = DISTORTION
	distortion.material = material
	distortion.visible = false
	add_child(distortion)
	hud = HudView.new()
	hud.state = state
	hud.style = style
	add_child(hud)
	title_label = _label(20, Color(1, 0.96, 0.9, 0.9))
	title_label.position = Vector2(460, 10)
	title_label.size = Vector2(1000, 30)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_label)
	help_label = _label(18, Color(1, 0.96, 0.9))
	help_label.text = HELP
	help_label.position = Vector2(980, 330)
	add_child(help_label)
	pause = PauseView.new()
	pause.state = state
	pause.style = style
	add_child(pause)
	dialog = DialogSample.new()
	dialog.state = state
	dialog.style = style
	add_child(dialog)

func _label(font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.05, 0.8))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func stage() -> String:
	return ("最终战（余时不足）" if state.final_from <= HudState.FINAL_SECONDS else "最终战") if state.final_active else "第%d日" % state.day

func _process(delta: float) -> void:
	state.tick(delta)
	var target: float = 0.0
	if state.balance < 0:
		target = 0.35 + 0.65 * state.overdraft() / float(-HudState.FLOOR)
	distortion_strength = move_toward(distortion_strength, target, delta * 1.5)
	distortion.visible = distortion_strength > 0.001
	(distortion.material as ShaderMaterial).set_shader_parameter("strength", distortion_strength)
	title_label.text = "%s · %s · 黄昏 %d%% · 随天数变化：%s" % [style.title(), stage(), roundi(style.dusk(state) * 100), "开" if style.progressive else "关"]
	title_label.add_theme_font_override("font", style.font())
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or key.echo or not key.pressed:
		return
	press(key.keycode)

## Moves the simulation to a given day (1-3), the final battle with time to
## spare (4, A-016 spin-down) or with under fifteen minutes left (5).
func jump(stage_index: int) -> void:
	state.stop_final()
	if stage_index == 4:
		state.start_final(25.0 * 60.0)
		return
	if stage_index >= 5:
		state.start_final(9.0 * 60.0 + 12.0)
		return
	state.day = stage_index
	state.day_remaining = HudState.DAY_SECONDS * 0.5

## Single entry point for keyboard and the smoke test.
func press(code: Key) -> void:
	if code == KEY_ESCAPE:
		if dialog.visible:
			dialog.call("close")
		elif pause.visible:
			pause.call("back")
		else:
			pause.call("open")
		return
	if pause.visible or dialog.visible:
		return
	match code:
		KEY_1: style.sample = 0
		KEY_2: style.sample = 1
		KEY_5: jump(1)
		KEY_6: jump(2)
		KEY_7: jump(3)
		KEY_8: jump(4)
		KEY_9: jump(5)
		KEY_0: style.progressive = not style.progressive
		KEY_J: style.handwriting = not style.handwriting
		KEY_K: dialog.call("open")
		KEY_H: help_label.visible = not help_label.visible
		KEY_Q: state.hurt()
		KEY_E: state.try_heal()
		KEY_R: state.reset()
		KEY_A: state.spend(1)
		KEY_S: state.gain(1)
		KEY_D: state.gain(3)
		KEY_F: state.try_dodge()
		KEY_G: state.cycle_growth()
		KEY_Z: state.add_pearls(-1)
		KEY_X: state.add_pearls(1)
		KEY_C: state.show_medkit = not state.show_medkit
		KEY_V: state.cycle_medkits()
		KEY_T: state.day_remaining = maxf(0.01, state.day_remaining - 60.0)
		KEY_Y: state.jump_to_warning()
		KEY_U: state.next_day()
		KEY_L: state.time_scale = 30.0 if state.time_scale == 1.0 else 1.0
		KEY_SPACE: state.paused = not state.paused

func _draw() -> void:
	# Same stand-in game scene as EXP-001 so both rounds compare fairly.
	var bands: int = 12
	for i: int in range(bands):
		var t: float = float(i) / bands
		draw_rect(Rect2(0, size.y * t, size.x, size.y / bands + 1), Color(0.16, 0.15, 0.2).lerp(Color(0.32, 0.24, 0.22), t))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 640), Vector2(260, 560), Vector2(520, 610), Vector2(860, 520), Vector2(1240, 590), Vector2(1600, 530), Vector2(1920, 600), Vector2(1920, 1080), Vector2(0, 1080)]), Color(0.1, 0.1, 0.13))
	draw_rect(Rect2(0, 790, size.x, 290), Color(0.07, 0.07, 0.09))
	draw_rect(Rect2(420, 700, 360, 24), Color(0.2, 0.2, 0.24))
	draw_rect(Rect2(940, 700, 44, 90), Color(0.85, 0.85, 0.9))
	draw_rect(Rect2(1270, 690, 70, 100), Color(0.35, 0.33, 0.4))
	draw_rect(Rect2(1700, 600, 28, 190), Color(0.55, 0.5, 0.42))
