extends "res://prototypes/EXP-003/title_base.gd"
## Variant C · 朦胧战场: a graybox battlefield drawn behind a blur and warm
## desaturation, crossed by light shafts and a vignette (T7 “朦胧滤镜与打光”).
## Title at the top; the menu runs along the bottom.
const BLUR: Shader = preload("res://prototypes/EXP-003/haze_blur.gdshader")
var world: Control
var overlay: Control

func variant_name() -> String:
	return "C · 朦胧战场"

func menu_container() -> Container:
	var menu: HBoxContainer = HBoxContainer.new()
	menu.position = Vector2(300, 880)
	menu.add_theme_constant_override("separation", 20)
	return menu

func button_tone() -> String:
	return "light"

func build() -> void:
	world = Control.new()
	world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.draw.connect(_draw_world)
	add_child(world)
	var haze: ColorRect = ColorRect.new()
	haze.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = BLUR
	haze.material = material
	add_child(haze)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(_draw_overlay)
	add_child(overlay)
	super.build()
	for button: Button in buttons:
		button.custom_minimum_size = Vector2(300, 58)

func _process(delta: float) -> void:
	super._process(delta)
	world.queue_redraw()
	overlay.queue_redraw()

## A stand-in for the real game scene: sky, platforms, figures, enemies.
func _draw_world() -> void:
	world.draw_rect(Rect2(Vector2.ZERO, size), Color(0.17, 0.11, 0.14))
	InkDraw.wash(world, Rect2(0, 0, size.x, size.y * 0.7), Color(DuskStyle.DUSK_TOP, 0.9), Color(DuskStyle.DUSK_BOTTOM, 0.8))
	world.draw_circle(Vector2(size.x * 0.72, size.y * 0.33), 150, Color(0.75, 0.35, 0.22))
	for i: int in range(5):
		world.draw_rect(Rect2(180 + i * 360, 300 + InkDraw.noise(i, 90) * 260, 26, 700), Color(0.32, 0.24, 0.26))
	world.draw_rect(Rect2(0, size.y * 0.78, size.x, size.y * 0.22), Color(0.36, 0.33, 0.30))
	for p: Rect2 in [Rect2(320, 640, 300, 24), Rect2(1180, 560, 360, 24), Rect2(760, 470, 220, 24)]:
		world.draw_rect(p, Color(0.45, 0.40, 0.36))
	world.draw_rect(Rect2(420, 770, 50, 70), Color(0.5, 0.85, 0.85))
	world.draw_rect(Rect2(560, 760, 44, 80), Color(0.85, 0.3, 0.2))
	for i: int in range(4):
		world.draw_rect(Rect2(900 + i * 190, 770, 54, 70), Color(0.95, 0.75, 0.35) if i % 2 == 0 else Color(0.65, 0.4, 0.75))

func _draw_overlay() -> void:
	# Light shafts from the upper left, slowly breathing.
	for i: int in range(5):
		var x: float = 200.0 + i * 260.0
		var a: float = 0.05 + 0.03 * sin(clock * 0.6 + i)
		overlay.draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 90, 0), Vector2(x + 620, size.y), Vector2(x + 380, size.y)]), Color(DuskStyle.SUN, a))
	# Vignette from soft edge washes (stroked rings band visibly).
	var dark: Color = Color(0.03, 0.01, 0.02, 0.55)
	var clear: Color = Color(0.03, 0.01, 0.02, 0.0)
	InkDraw.wash(overlay, Rect2(0, 0, size.x, 220), dark, clear)
	InkDraw.wash(overlay, Rect2(0, size.y - 260, size.x, 260), clear, dark)
	overlay.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(260, 0), Vector2(260, size.y), Vector2(0, size.y)]), PackedColorArray([dark, clear, clear, dark]))
	overlay.draw_polygon(PackedVector2Array([Vector2(size.x - 260, 0), Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(size.x - 260, size.y)]), PackedColorArray([clear, dark, dark, clear]))
	overlay.draw_rect(Rect2(0, size.y * 0.78, size.x, size.y * 0.22), Color(0.03, 0.01, 0.02, 0.45))
	var title: Rect2 = title_rect()
	var shown: String = drawn_text(overlay, Vector2(0, title.end.y - 92), TITLE, 132, DuskStyle.PAPER_DAY, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	InkDraw.rough_line(overlay, Vector2(size.x * 0.5 - 220, title.end.y - 64), Vector2(size.x * 0.5 + 220, title.end.y - 64), Color(DuskStyle.SUN, 0.8), 3.0, 42, 1.2)
	overlay.draw_string(font, Vector2(0, title.end.y - 22), "V0.1 灰盒", HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTheme.SIZE_SMALL, Color(DuskStyle.PAPER_DAY, 0.7))
	drawn["title"] = {"text": shown, "rect": title, "variant": variant_name()}
