class_name RescueOverlay
extends CanvasLayer
var shade: ColorRect
var slash: Line2D
var caption: Label
func _ready() -> void:
	layer = 14
	shade = ColorRect.new()
	shade.size = Vector2(1920,1080)
	shade.color = Color(0.05,0.01,0.01,0.35)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	slash = Line2D.new()
	slash.points = PackedVector2Array([Vector2(-80,1020),Vector2(2000,60)])
	slash.width = 64
	slash.default_color = Color(1,0.22,0.15,0.9)
	add_child(slash)
	for x: int in [340,800,1260]:
		var fracture: Line2D = Line2D.new()
		fracture.points = PackedVector2Array([Vector2(x,-80),Vector2(x+110,420),Vector2(x-90,650),Vector2(x+210,1160)])
		fracture.width = 7
		fracture.default_color = Color(1,0.65,0.5,0.8)
		slash.add_child(fracture)
	caption = Label.new()
	caption.position = Vector2(600,70)
	caption.add_theme_font_size_override("font_size",34)
	add_child(caption)
	hide()

func show_drop() -> void:
	show()
	slash.hide()
	caption.text = "10 · 临时救场演出"

func show_slash() -> void:
	slash.show()
	caption.text = ""

func show_save_retry() -> void:
	slash.hide()
	caption.text = "进度保存失败 · E / RB 重试"
