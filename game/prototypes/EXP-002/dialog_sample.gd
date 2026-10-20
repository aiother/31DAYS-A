extends Control
## Generic dialog and button-state reference for later screens (main menu,
## slot selection, death screen). Style only; no real layout for those screens.
const Ink = preload("res://prototypes/EXP-002/ink.gd")
const Style = preload("res://prototypes/EXP-002/style.gd")
const InkButton = preload("res://prototypes/EXP-002/ink_button.gd")
const BOX: Rect2 = Rect2(560, 300, 800, 460)

var state: RefCounted
var style: RefCounted
var font: Font
var buttons: Array[Button] = []

func _ready() -> void:
	font = ThemeDB.fallback_font
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var row: HBoxContainer = HBoxContainer.new()
	row.position = BOX.position + Vector2(60, 300)
	row.add_theme_constant_override("separation", 20)
	add_child(row)
	for entry: Array in [["放弃", 701, false], ["再想想", 702, false], ["不可用", 703, true]]:
		var button: Button = InkButton.new()
		button.call("setup", entry[0], 26, entry[1], style)
		button.custom_minimum_size = Vector2(200, 56)
		button.disabled = entry[2]
		button.pressed.connect(close)
		buttons.append(button)
		row.add_child(button)

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func open() -> void:
	visible = true
	buttons[1].grab_focus()

func close() -> void:
	visible = false

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.03, 0.04, 0.55))
	Ink.glow(self, BOX.get_center(), 260, Style.DUSK_BOTTOM, style.glow_strength(state) * 0.7)
	style.panel(self, BOX, state, 700)
	draw_string(font, BOX.position + Vector2(60, 90), "要放弃这次救助吗？", HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Style.INK)
	Ink.rough_line(self, BOX.position + Vector2(60, 108), BOX.position + Vector2(330, 108), Color(Style.LIFE, 0.8), 2.4, 704, style.wobble())
	draw_string(font, BOX.position + Vector2(60, 170), "放弃后，这位幸存者将不再等你。", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(Style.INK, 0.85))
	draw_string(font, BOX.position + Vector2(60, 214), "（通用对话框与按钮状态样式参考：常态、悬停、选中、按下、不可用）", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(Style.INK, 0.55))
