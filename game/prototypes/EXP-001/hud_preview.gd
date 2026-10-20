extends Control
## EXP-001 preview: switch HUD variants and drive simulated states by key.
## Raw keycodes only; the frozen project input map is not touched.
const HudState = preload("res://prototypes/EXP-001/hud_state.gd")
const Overlay = preload("res://prototypes/EXP-001/shared_overlay.gd")
const PauseMenu = preload("res://prototypes/EXP-001/pause_menu.gd")
const DISTORTION: Shader = preload("res://prototypes/EXP-001/overdraft_distortion.gdshader")
const COMBO: int = 3
const VARIANTS: Array[Script] = [
	preload("res://prototypes/EXP-001/variant_corner.gd"),
	preload("res://prototypes/EXP-001/variant_emblem.gd"),
	preload("res://prototypes/EXP-001/variant_fracture.gd"),
	preload("res://prototypes/EXP-001/variant_combo.gd"),
]
const HELP: String = """1 / 2 / 3 / 4  切换方案（4 为组合方案）    H  显示/隐藏本说明
Q 受伤（最低1点）   E 尝试恢复（消耗3）   R 全部重置
A 消耗1可能性（可透支到-9）   S 获得1   D 获得3（光效飞入）
F 尝试闪避（不足时透支并发红）   G 切换成长上限 0/1/2 段
Z / X 珍珠 -1 / +1      C 显示药包（G-01，可选）   V 药包数量
T 时间 +1分钟   Y 跳到换日前3分钟   U 立即进入下一日
O 最终战：第3日余25分钟（加速定格）   P 最终战：余9分12秒   I 结束最终战
L 时间流速 ×1 / ×30     空格 暂停时间     Tab（方案二）按住展开时间
Esc 暂停菜单：左侧选项，右侧时钟与天数；进入设置等二级界面会盖住时钟，Esc 返回
方案四：可能性低于0时画面出现失真滤镜，透支越多越强"""

var state: HudState = HudState.new()
var variant_index: int = 0
var variant: Control
var overlay: Control
var title_label: Label
var help_label: Label
var distortion: ColorRect
var distortion_strength: float = 0.0
var pause: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Distortion sits under the HUD so only the game scene is distorted.
	distortion = ColorRect.new()
	distortion.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	distortion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = DISTORTION
	distortion.material = material
	distortion.visible = false
	add_child(distortion)
	overlay = Overlay.new()
	overlay.state = state
	overlay.target = func() -> Vector2: return variant.call("gain_target") if variant != null else Vector2.ZERO
	add_child(overlay)
	title_label = _label(22, Color(1, 1, 1, 0.85))
	title_label.position = Vector2(560, 12)
	title_label.size = Vector2(800, 30)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label = _label(19, Color(0.85, 0.88, 0.95))
	help_label.text = HELP
	help_label.position = Vector2(1100, 340)
	add_child(title_label)
	add_child(help_label)
	pause = PauseMenu.new()
	pause.state = state
	add_child(pause)
	select_variant(0)

func _label(font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func select_variant(index: int) -> void:
	variant_index = clampi(index, 0, VARIANTS.size() - 1)
	if variant != null:
		variant.queue_free()
	variant = VARIANTS[variant_index].new() as Control
	variant.set("state", state)
	add_child(variant)
	move_child(variant, distortion.get_index() + 1)
	title_label.text = variant.call("title")

func _process(delta: float) -> void:
	state.tick(delta)
	var target: float = 0.0
	if variant_index == COMBO and state.balance < 0:
		target = 0.35 + 0.65 * state.overdraft() / float(-HudState.FLOOR)
	distortion_strength = move_toward(distortion_strength, target, delta * 1.5)
	distortion.visible = distortion_strength > 0.001
	(distortion.material as ShaderMaterial).set_shader_parameter("strength", distortion_strength)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or key.echo:
		return
	if key.keycode == KEY_TAB:
		variant.set("expanded", key.pressed)
		return
	if key.pressed:
		press(key.keycode)

## Single entry point for keyboard and the smoke test.
func press(code: Key) -> void:
	if code == KEY_ESCAPE:
		if pause.visible:
			pause.call("back")
		else:
			pause.call("open")
		return
	if pause.visible:
		return
	match code:
		KEY_1: select_variant(0)
		KEY_2: select_variant(1)
		KEY_3: select_variant(2)
		KEY_4: select_variant(3)
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
		KEY_O: state.start_final(25.0 * 60.0)
		KEY_P: state.start_final(9.0 * 60.0 + 12.0)
		KEY_I: state.stop_final()
		KEY_L: state.time_scale = 30.0 if state.time_scale == 1.0 else 1.0
		KEY_SPACE: state.paused = not state.paused

func _draw() -> void:
	# Stand-in game scene so the HUD can be judged against something busy.
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
