class_name SaveToast
extends Control
## Save feedback (BL-052): a small paper tag that appears when a checkpoint is
## recorded and saved, then fades. It sits in the top-right corner, inset from
## the screen edges (user, 2026-10-21), above the enemy intro card's slot and
## the graybox room text, so it covers neither them nor the HUD.
const TEXT: String = "检查点已保存"
const SECONDS: float = 2.4
const FADE: float = 0.5
## Inset from the top and right screen edges, in 1920x1080 canvas units.
const MARGIN: float = 40.0

var session: Node
var font: Font
var remaining: float = 0.0
## What the last _draw showed; read by tests.
var drawn: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = UiTheme.font()
	custom_minimum_size = Vector2(font.get_string_size(TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_SMALL).x + 36, 34)
	size = custom_minimum_size
	visible = false

func show_saved() -> void:
	remaining = SECONDS
	visible = true
	queue_redraw()

func _process(delta: float) -> void:
	position = Vector2(get_parent_area_size().x - size.x - MARGIN, MARGIN)
	if not visible:
		return
	if not get_tree().paused:
		remaining = maxf(0.0, remaining - delta)
	visible = remaining > 0.0
	queue_redraw()

func _draw() -> void:
	var time: Dictionary = session.call("ui_time_state") if session != null and session.has_method("ui_time_state") else {}
	var alpha: float = clampf(remaining / FADE, 0.0, 1.0)
	modulate.a = alpha
	DuskStyle.panel(self, Rect2(Vector2.ZERO, size), time, 27)
	draw_string(font, Vector2(18, 24), TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_SMALL, DuskStyle.INK)
	drawn = {"text": TEXT, "alpha": alpha}
