extends Control
## EXP-002 HUD: EXP-001 variant four layout (emblem, horizon time, banners,
## final countdown) redrawn in the selected visual direction.
const Ink = preload("res://prototypes/EXP-002/ink.gd")
const Style = preload("res://prototypes/EXP-002/style.gd")
const HudState = preload("res://prototypes/EXP-001/hud_state.gd")
const CENTER: Vector2 = Vector2(150, 150)
const RING: float = 86.0
const OUTER: float = 108.0
const BANNER_SECONDS: float = 4.0
const FLY_SECONDS: float = 0.7

var state: RefCounted
var style: RefCounted
var font: Font
var banner_left: float = 0.0
var flyers: Array[Dictionary] = []
## What the last _draw actually put on screen; read by the smoke test.
var drawn: Dictionary = {}

func _ready() -> void:
	font = ThemeDB.fallback_font
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	state.day_changed.connect(func(_day: int) -> void: banner_left = BANNER_SECONDS)
	state.gained.connect(_on_gained)

func _on_gained(amount: int) -> void:
	for i: int in range(clampi(amount, 1, 6)):
		flyers.append({"from": Vector2(1290 + i * 14, 700 - (i % 2) * 24), "t": -0.09 * i})

func _process(delta: float) -> void:
	if not state.paused and not state.frozen:
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

func ink_text(position: Vector2, value: String, size: int, color: Color = Style.INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	draw_string(font, position, value, align, width, size, color)

func deny_flash() -> float:
	if state.deny_left <= 0.0:
		return 0.0
	return (0.5 + 0.5 * sin(state.clock * 28.0)) * clampf(state.denied() * 1.6, 0.0, 1.0)

func gain_target() -> Vector2:
	var index: int = clampi(state.balance - 1, 0, HudState.BASE_MAX - 1)
	return CENTER + Vector2.from_angle(-PI / 2.0 + TAU * (index + 0.5) / HudState.BASE_MAX) * RING

func _draw() -> void:
	font = style.font()
	drawn = {"font": font.resource_path}
	_draw_edge_wash()
	if state.health == 1:
		_draw_last_life()
	_draw_emblem()
	_draw_horizon()
	if banner_left > 0.0:
		_draw_banner()
	if state.warning_active():
		_draw_warning()
	if state.final_active:
		_draw_final()
	_draw_flyers()

## The dusk creeping in from the top and bottom edges as doom approaches.
func _draw_edge_wash() -> void:
	var amount: float = style.edge_wash(state)
	if amount <= 0.001:
		return
	Ink.wash(self, Rect2(0, 0, size.x, size.y * 0.32), Color(Style.DUSK_TOP, amount), Color(Style.DUSK_TOP, 0.0))
	Ink.wash(self, Rect2(0, size.y * 0.62, size.x, size.y * 0.38), Color(Style.DUSK_BOTTOM, 0.0), Color(Style.DUSK_BOTTOM, amount))

func _draw_last_life() -> void:
	var strength: float = 0.55 + 0.25 * sin(state.clock * 4.0)
	for i: int in range(10):
		var inset: float = i * 10.0
		draw_rect(Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0), Color(Style.LIFE, strength * (1.0 - i / 10.0) * 0.16), false, 11.0)

func _arc(radius: float, index: int, color: Color, width: float) -> void:
	var span: float = TAU / HudState.BASE_MAX
	var from: float = -PI / 2.0 + span * index + 0.07
	draw_arc(CENTER, radius, from, from + span - 0.14, 10, color, width, true)

func _draw_emblem() -> void:
	var flash: float = deny_flash()
	var glow: float = style.glow_strength(state) * style.breath(state)
	var seed: int = 7
	# Key colours: the same on every day and in both samples.
	var palette: Dictionary = {"life": Style.LIFE, "possibility": Style.POSSIBILITY, "overdraft": Style.OVERDRAFT, "growth": Style.GROWTH, "deny": Style.DENY}
	drawn["palette"] = palette
	Ink.paper_disc(self, CENTER + Vector2(3, 4), OUTER + 18, Color(0, 0, 0, 0.25), seed)
	Ink.paper_disc(self, CENTER, OUTER + 16, Color(style.paper_color(state), style.panel_alpha()), seed, style.wobble())
	var g: float = style.glass(state)
	if g > 0.0:
		Ink.paper_disc(self, CENTER, OUTER + 14, Color(Style.DUSK_TOP.lerp(Style.DUSK_BOTTOM, 0.5), 0.35 * g), seed + 1, 0.0)
	Ink.rough_circle(self, CENTER, OUTER + 16, Color(Style.INK, 0.85), style.ink_width(), seed, style.wobble())
	var pulse: float = clampf(state.gain_pulse / 0.35, 0.0, 1.0)
	for i: int in range(HudState.BASE_MAX):
		_arc(RING, i, Color(Style.INK, 0.14).lerp(Style.DENY, flash * 0.35), 15.0)
		if i < state.balance:
			_arc(RING, i, Color(Style.POSSIBILITY_GLOW, 0.3 * glow), 24.0)
			var fill: Color = Color(palette["possibility"]).lerp(Style.POSSIBILITY_GLOW, pulse * 0.6).lerp(palette["deny"], flash * 0.6)
			_arc(RING, i, fill, 12.0)
			# Record the colour the ring segment was really drawn with.
			drawn["possibility_fill"] = fill
		elif i >= HudState.BASE_MAX - state.overdraft():
			var debt: Color = Color(palette["overdraft"]).lerp(palette["deny"], flash * 0.6)
			_arc(RING, i, debt, 12.0)
			drawn["overdraft_fill"] = debt
	Ink.rough_circle(self, CENTER, RING + 10, Color(Style.INK, 0.5 + flash * 0.4), 1.4 + flash * 1.5, seed + 2, style.wobble() * 0.6)
	Ink.rough_circle(self, CENTER, RING - 10, Color(Style.INK, 0.5), 1.4, seed + 3, style.wobble() * 0.6)
	for i: int in range(state.growth * HudState.GROWTH_STEP):
		var filled: bool = state.balance > HudState.BASE_MAX + i
		_arc(OUTER, i, palette["growth"] if filled else Color(palette["growth"], 0.35), 7.0)
	# Life: inked vermilion shards, current count only.
	var count: int = state.health
	var left: float = CENTER.x - (count - 1) * 12.0
	for i: int in range(count):
		var c: Vector2 = Vector2(left + i * 24.0, CENTER.y)
		var shard: PackedVector2Array = PackedVector2Array([c + Vector2(0, -26), c + Vector2(9, 0), c + Vector2(0, 26), c + Vector2(-9, 0)])
		var life_fill: Color = palette["life"]
		draw_colored_polygon(shard, life_fill)
		drawn["life_fill"] = life_fill
		shard.append(shard[0])
		draw_polyline(shard, Color(Style.INK, 0.8), 1.6, true)
	# Pearls and reach on a small paper tag.
	for i: int in range(HudState.PEARL_MAX):
		var p: Vector2 = CENTER + Vector2.from_angle(PI * 0.5 + (i - 1.5) * 0.28) * (OUTER + 34)
		if i < state.pearls:
			draw_circle(p, 7, Style.PEARL)
		# Pearls sit over the game scene, not paper, so their outline is light.
		Ink.rough_circle(self, p, 7, Color(Style.PAPER_DAY, 0.75), 1.6, 40 + i, 0.6)
	var tag: Rect2 = Rect2(CENTER + Vector2(OUTER + 34, -22), Vector2(150, 40))
	style.panel(self, tag, state, 21)
	ink_text(tag.position + Vector2(14, 28), "范围 %d%%" % state.reach_percent(), 22)
	drawn["emblem"] = {"life": count, "reach": state.reach_percent()}
	if state.show_medkit:
		var med: Rect2 = Rect2(tag.position + Vector2(0, 50), Vector2(110, 38))
		style.panel(self, med, state, 23)
		draw_rect(Rect2(med.position + Vector2(16, 12), Vector2(6, 16)), Style.LIFE)
		draw_rect(Rect2(med.position + Vector2(11, 17), Vector2(16, 6)), Style.LIFE)
		ink_text(med.position + Vector2(36, 27), "× %d" % state.medkits, 22)

func _draw_horizon() -> void:
	var y: float = size.y - 40
	var x: float = size.x * state.day_progress()
	Ink.rough_line(self, Vector2(0, y), Vector2(size.x, y), Color(Style.PAPER_DAY, 0.45), 2.0, 61, style.wobble())
	Ink.rough_line(self, Vector2(0, y), Vector2(x, y), Color(Style.SUN, 0.8), 2.6, 62, style.wobble())
	Ink.glow(self, Vector2(x, y), 12, Style.SUN, style.glow_strength(state) * style.breath(state))
	draw_circle(Vector2(x, y), 8, Style.SUN)
	var tag: Rect2 = Rect2(Vector2(clampf(x - 46, 8, size.x - 100), y - 52), Vector2(92, 34))
	style.panel(self, tag, state, 63)
	ink_text(tag.position + Vector2(0, 25), state.clock_text(), 22, Style.INK, HORIZONTAL_ALIGNMENT_CENTER, tag.size.x)
	drawn["horizon"] = state.clock_text()
	var date: Rect2 = Rect2(Vector2(size.x - 230, y + 6), Vector2(210, 28))
	style.panel(self, date, state, 64)
	ink_text(date.position + Vector2(0, 21), "第%d日 · 末日前%d天" % [state.day, state.days_left()], 17, Style.INK, HORIZONTAL_ALIGNMENT_CENTER, date.size.x)

func _draw_banner() -> void:
	var t: float = BANNER_SECONDS - banner_left
	var alpha: float = clampf(minf(t / 0.6, banner_left / 0.9), 0.0, 1.0)
	var box: Rect2 = Rect2(Vector2((size.x - 520) * 0.5, 190 + (1.0 - alpha) * 12.0), Vector2(520, 124))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	Ink.glow(self, box.get_center(), 120, Style.SUN, style.glow_strength(state) * alpha)
	style.panel(self, box, state, 71)
	ink_text(box.position + Vector2(0, 66), "第 %d 日" % state.day, 52, Color(Style.INK, alpha), HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	drawn["banner"] = state.day
	ink_text(box.position + Vector2(0, 106), "末日前 %d 天" % state.days_left(), 26, Color(Style.LIFE, alpha), HORIZONTAL_ALIGNMENT_CENTER, box.size.x)

func _draw_warning() -> void:
	var left: int = int(ceil(state.day_remaining))
	var box: Rect2 = Rect2(Vector2(size.x - 420, size.y - 150), Vector2(380, 50))
	style.panel(self, box, state, 81)
	ink_text(box.position + Vector2(18, 34), "即将进入第 %d 日 · %d:%02d" % [state.day + 1, int(left / 60.0), left % 60], 23)
	drawn["warning"] = true
	var blink: float = 0.5 + 0.5 * sin(state.clock * 5.0)
	Ink.rough_line(self, box.position + Vector2(16, 42), box.position + Vector2(box.size.x - 16, 42), Color(Style.LIFE, 0.4 + 0.5 * blink), 2.2, 82, style.wobble())

func _draw_final() -> void:
	var box: Rect2 = Rect2(Vector2((size.x - 470) * 0.5, 54), Vector2(470, 112))
	var value: float = state.final_remaining
	var label: String = "最终战倒计时"
	var color: Color = Style.INK
	if state.accelerate_left > 0.0:
		var progress: float = 1.0 - state.accelerate_left / HudState.ACCELERATE_SECONDS
		value = lerpf(state.final_from, state.final_remaining, ease(progress, 2.2))
		label = "时间加速……"
	elif state.final_from <= HudState.FINAL_SECONDS:
		label = "最终战倒计时 · 余时不足"
		color = Style.LIFE
	Ink.glow(self, box.get_center(), 140, Style.DUSK_BOTTOM, style.glow_strength(state) * style.breath(state))
	style.panel(self, box, state, 91)
	var dial: Vector2 = box.position + Vector2(62, 56)
	Ink.rough_circle(self, dial, 32, Color(Style.INK, 0.85), 2.2, 92, style.wobble())
	var hand: float = -PI / 2.0 + TAU * fmod(value, 60.0) / 60.0
	draw_line(dial, dial + Vector2.from_angle(hand) * 24, color, 3.0, true)
	draw_circle(dial, 4, Style.SUN)
	var seconds: int = int(ceil(value))
	ink_text(box.position + Vector2(118, 36), label, 21, Color(color, 0.85))
	var digits: String = "%02d:%02d" % [int(seconds / 60.0), seconds % 60]
	ink_text(box.position + Vector2(118, 92), digits, 50, color)
	drawn["final"] = {"label": label, "digits": digits, "color": color}

func _draw_flyers() -> void:
	var to: Vector2 = gain_target()
	for flyer: Dictionary in flyers:
		var t: float = float(flyer["t"])
		if t < 0.0:
			continue
		var from: Vector2 = flyer["from"]
		var control: Vector2 = from.lerp(to, 0.5) + Vector2(0, -260)
		var eased: float = ease(t, 0.6)
		var position: Vector2 = from.lerp(control, eased).lerp(control.lerp(to, eased), eased)
		Ink.glow(self, position, 7, Style.POSSIBILITY_GLOW, 1.4)
		draw_circle(position, 4, Style.PEARL)
