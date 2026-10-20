extends Control
## Elements shared by every variant: last-life vignette, day banner (top centre),
## three-minute warning (bottom right), final countdown (top centre, A-016) and
## the possibility gain fly-in.
const HudState = preload("res://prototypes/EXP-001/hud_state.gd")
const BANNER_SECONDS: float = 4.0
const FLY_SECONDS: float = 0.7

var state: RefCounted
var target: Callable
var font: Font
var banner_left: float = 0.0
var flyers: Array[Dictionary] = []

func _ready() -> void:
	font = ThemeDB.fallback_font
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	state.day_changed.connect(_on_day_changed)
	state.gained.connect(_on_gained)

func _on_day_changed(_day: int) -> void:
	banner_left = BANNER_SECONDS

func _on_gained(amount: int) -> void:
	for i: int in range(clampi(amount, 1, 6)):
		flyers.append({"from": Vector2(1290 + i * 14, 700 - (i % 2) * 24), "t": -0.09 * i})

func _process(delta: float) -> void:
	banner_left = maxf(0.0, banner_left - delta)
	var landed: Array[Dictionary] = []
	for flyer: Dictionary in flyers:
		flyer["t"] = float(flyer["t"]) + delta / FLY_SECONDS
		if float(flyer["t"]) >= 1.0:
			landed.append(flyer)
	for flyer: Dictionary in landed:
		flyers.erase(flyer)
		state.gain_pulse = 0.35
	queue_redraw()

func text(position: Vector2, value: String, size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	draw_string_outline(font, position, value, align, width, size, 7, Color(0, 0, 0, 0.6))
	draw_string(font, position, value, align, width, size, color)

func _draw() -> void:
	if state.health == 1:
		_draw_vignette()
	_draw_flyers()
	if banner_left > 0.0:
		_draw_banner()
	if state.warning_active():
		_draw_warning()
	if state.final_active:
		_draw_final()

func _draw_vignette() -> void:
	var strength: float = 0.55 + 0.25 * sin(state.clock * 4.0)
	for i: int in range(12):
		var inset: float = i * 9.0
		var alpha: float = strength * (1.0 - i / 12.0) * 0.18
		draw_rect(Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0), Color(0.85, 0.05, 0.08, alpha), false, 10.0)

func _draw_flyers() -> void:
	var to: Vector2 = target.call() if target.is_valid() else Vector2(160, 120)
	for flyer: Dictionary in flyers:
		var t: float = float(flyer["t"])
		if t < 0.0:
			continue
		var from: Vector2 = flyer["from"]
		var control: Vector2 = from.lerp(to, 0.5) + Vector2(0, -260)
		var eased: float = ease(t, 0.6)
		var a: Vector2 = from.lerp(control, eased)
		var b: Vector2 = control.lerp(to, eased)
		var position: Vector2 = a.lerp(b, eased)
		draw_circle(position, 9, Color(0.6, 0.9, 1.0, 0.35))
		draw_circle(position, 5, Color(0.9, 0.98, 1.0))

func _draw_banner() -> void:
	var t: float = BANNER_SECONDS - banner_left
	var alpha: float = clampf(minf(t / 0.5, banner_left / 0.8), 0.0, 1.0)
	var width: float = 620.0
	var box: Rect2 = Rect2(Vector2((size.x - width) * 0.5, 190), Vector2(width, 120))
	draw_rect(box, Color(0, 0, 0, 0.45 * alpha))
	text(Vector2(box.position.x, box.position.y + 62), "第 %d 日" % state.day, 52, Color(1, 1, 1, alpha), HORIZONTAL_ALIGNMENT_CENTER, width)
	text(Vector2(box.position.x, box.position.y + 102), "末日前 %d 天" % state.days_left(), 26, Color(1.0, 0.75, 0.55, alpha), HORIZONTAL_ALIGNMENT_CENTER, width)

func _draw_warning() -> void:
	var left: int = int(ceil(state.day_remaining))
	var blink: float = 0.6 + 0.4 * sin(state.clock * 5.0)
	var box: Rect2 = Rect2(Vector2(size.x - 420, size.y - 200), Vector2(370, 54))
	draw_rect(box, Color(0.25, 0.05, 0.02, 0.6 * blink))
	text(box.position + Vector2(18, 36), "即将进入第 %d 日 · %d:%02d" % [state.day + 1, int(left / 60.0), left % 60], 24, Color(1.0, 0.8, 0.6))

func _draw_final() -> void:
	var width: float = 520.0
	var origin: Vector2 = Vector2((size.x - width) * 0.5, 64)
	var value: float = state.final_remaining
	var label: String = "最终战倒计时"
	var color: Color = Color(1.0, 0.92, 0.85)
	if state.accelerate_left > 0.0:
		# A-016 (一)①: purely visual spin-down onto the live budget (15:00 and
		# already counting); real time keeps running underneath.
		var progress: float = 1.0 - state.accelerate_left / HudState.ACCELERATE_SECONDS
		value = lerpf(state.final_from, state.final_remaining, ease(progress, 2.2))
		label = "时间加速……"
		color = Color(0.8, 0.9, 1.0).lerp(Color.WHITE, progress)
		origin.x += sin(state.clock * 60.0) * 3.0 * (1.0 - progress)
	elif state.final_from <= HudState.FINAL_SECONDS:
		# A-016 (二)③: under fifteen minutes the clock shows the real budget.
		label = "最终战倒计时 · 余时不足"
		color = Color(1.0, 0.55, 0.45)
	var seconds: int = int(ceil(value))
	draw_circle(Vector2(origin.x + 40, origin.y + 46), 30, Color(0, 0, 0, 0.5))
	draw_arc(Vector2(origin.x + 40, origin.y + 46), 26, 0, TAU, 32, color, 3.0, true)
	var hand: float = -PI / 2.0 + TAU * fmod(value, 60.0) / 60.0
	draw_line(Vector2(origin.x + 40, origin.y + 46), Vector2(origin.x + 40, origin.y + 46) + Vector2.from_angle(hand) * 20, color, 3.0)
	text(origin + Vector2(90, 26), label, 22, Color(color, 0.85))
	text(origin + Vector2(90, 80), "%02d:%02d" % [int(seconds / 60.0), seconds % 60], 52, color)
