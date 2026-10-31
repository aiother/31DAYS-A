class_name FormalHud
extends Control
## Formal HUD (UI-002): EXP-001 variant four layout drawn in the EXP-002 sample
## two style (UI-001 DuskStyle / InkDraw / UiTheme). Reads the real player and
## the session's SYS-005 interface; it never changes game state.
##
## Layout in 1920x1080 canvas units: emblem top-left (life shards, possibility
## ring, growth arc, pearls, reach and medkit tags), horizon along the bottom
## (hidden, UI-011), date-change animation in the upper middle and final countdown
## top-centre.
const CENTER: Vector2 = Vector2(150, 150)
const RING: float = 86.0
const OUTER: float = 108.0
const PEARL_MAX: int = 4
const DENY_SECONDS: float = 0.9
const FLY_SECONDS: float = 0.7
const MAX_FLYERS: int = 6
## A-016: the start-of-battle spin-down only plays on screen; the real budget
## keeps running underneath it.
const ACCELERATE_SECONDS: float = 2.5
const FINAL_BUDGET: float = 900.0
## UI-011 (user 2026-10-31): the horizon, its time tag and the date tag are hidden
## ("不太好看……先隐藏吧"); the drawing stays so it can be turned back on.
const SHOW_HORIZON: bool = false
## UI-011: the date change is a short animation in the upper middle of the screen
## (reference `codexandclaude/references/日期切换.mp4`): a half sun rises from a
## short horizon line, thin rings with ticks sweep open around it, a vertical line
## rises through its centre, and the day name fades in beneath. It fits between
## the final countdown (ends at 166) and the save error line (starts at 360).
const DAY_CENTER: Vector2 = Vector2(960, 274)
const DAY_RADIUS: float = 54.0
const DAY_NUMERALS: Array[String] = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
## Distortion under the HUD only, so the HUD itself stays crisp.
const FILTER_LAYER: int = 10
const DISTORTION: Shader = preload("res://ui/hud/overdraft_distortion.gdshader")

var player: PlayerController
var session: Node
## The control hint Label owned by LifeUI; the HUD draws its paper tag.
var hint: Label
var font: Font
var clock: float = 0.0
var deny_left: float = 0.0
var gain_pulse: float = 0.0
var flyers: Array[Dictionary] = []
var banner_left: float = 0.0
var banner_day: int = 0
var accelerate_left: float = 0.0
var accelerate_from: float = 0.0
var distortion_strength: float = 0.0
var filter: CanvasLayer
var filter_rect: ColorRect
var _seen_day: int = 0
var _seen_final: bool = false
## What the last _draw actually put on screen; read by tests.
var drawn: Dictionary = {}

func setup(target: PlayerController, owner_session: Node, hint_label: Label) -> void:
	player = target
	session = owner_session
	hint = hint_label
	player.possibility.shortfall.connect(_on_shortfall)
	player.possibility.gained.connect(_on_gained)
	if session.has_signal("day_changed"):
		session.connect("day_changed", _on_day_changed)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	font = UiTheme.font()
	filter = CanvasLayer.new()
	filter.layer = FILTER_LAYER
	add_child(filter)
	filter_rect = ColorRect.new()
	filter_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = DISTORTION
	filter_rect.material = material
	filter_rect.visible = false
	filter.add_child(filter_rect)
	filter_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func time_state() -> Dictionary:
	if session != null and session.has_method("ui_time_state"):
		return session.call("ui_time_state")
	return {}

func _on_shortfall(_kind: int) -> void:
	deny_left = DENY_SECONDS

func _on_gained(amount: int, source_world_position: Vector2) -> void:
	var from: Vector2 = get_viewport().get_canvas_transform() * source_world_position
	for i: int in range(clampi(amount, 1, MAX_FLYERS)):
		flyers.append({"from": from + Vector2(i * 14, -(i % 2) * 24), "t": -0.09 * i})

## SYS-005 N1: the first date after a new session is initialisation, and
## reloading an earlier checkpoint is not a new day, so neither gets a banner.
func _on_day_changed(day: int) -> void:
	if _seen_day > 0 and day > _seen_day:
		banner_day = day
		banner_left = DayClock.CONFIG.announcement_seconds
	_seen_day = day

func _process(delta: float) -> void:
	var time: Dictionary = time_state()
	var active: bool = bool(time.get("has_session", false))
	if not active:
		_seen_day = 0
	elif _seen_day == 0:
		_seen_day = int(time["day"])
	var final_active: bool = bool(time.get("final_active", false))
	if final_active and not _seen_final:
		# Only a start seen live (start known) can replay the spin-down.
		accelerate_left = ACCELERATE_SECONDS if bool(time.get("final_acceleration", false)) else 0.0
		accelerate_from = float(time.get("final_start_day3_remaining", FINAL_BUDGET))
	_seen_final = final_active
	if not get_tree().paused:
		clock += delta
		deny_left = maxf(0.0, deny_left - delta)
		gain_pulse = maxf(0.0, gain_pulse - delta)
		banner_left = maxf(0.0, banner_left - delta)
		accelerate_left = maxf(0.0, accelerate_left - delta)
		var landed: Array[Dictionary] = []
		for flyer: Dictionary in flyers:
			flyer["t"] = float(flyer["t"]) + delta / FLY_SECONDS
			if float(flyer["t"]) >= 1.0:
				landed.append(flyer)
		for flyer: Dictionary in landed:
			flyers.erase(flyer)
			gain_pulse = 0.35
		distortion_strength = move_toward(distortion_strength, distortion_target(), delta * 1.5)
	filter_rect.visible = is_visible_in_tree() and distortion_strength > 0.001
	(filter_rect.material as ShaderMaterial).set_shader_parameter("strength", distortion_strength)
	queue_redraw()

## EXP-001 variant four: none at or above 0, then deeper with each point of debt.
func distortion_target() -> float:
	var actions: PlayerPossibility = player.possibility
	if actions.balance >= 0:
		return 0.0
	return 0.35 + 0.65 * float(-actions.balance) / float(maxi(1, -actions.config.floor_balance))

func deny_flash() -> float:
	if deny_left <= 0.0:
		return 0.0
	return (0.5 + 0.5 * sin(clock * 28.0)) * clampf(deny_left / DENY_SECONDS * 1.6, 0.0, 1.0)

func base_maximum() -> int:
	return player.possibility.config.maximum

func gain_target() -> Vector2:
	var index: int = clampi(player.possibility.balance - 1, 0, base_maximum() - 1)
	return CENTER + Vector2.from_angle(-PI / 2.0 + TAU * (index + 0.5) / base_maximum()) * RING

func reach_percent() -> int:
	return roundi(player.combat.range_multiplier() * 100.0)

func days_left(day: int) -> int:
	return 4 - day

## Maps the real day onto a 06:00-24:00 in-game clock (EXP-001 choice).
func clock_text(time: Dictionary) -> String:
	var minutes: int = mini(6 * 60 + int(float(time.get("day_progress", 0.0)) * 18.0 * 60.0), 24 * 60 - 1)
	return "%02d:%02d" % [int(minutes / 60.0), minutes % 60]

func ink_text(at: Vector2, value: String, size_px: int, color: Color = DuskStyle.INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	draw_string(font, at, value, align, width, size_px, color)

func _draw() -> void:
	var time: Dictionary = time_state()
	drawn = {"font": font.resource_path, "dusk": DuskStyle.dusk(time)}
	if player == null:
		return
	_draw_edge_wash(time)
	if player.life.health == 1 and player.life.is_alive():
		_draw_last_life()
	_draw_emblem(time)
	_draw_hint(time)
	if bool(time.get("has_session", false)):
		if SHOW_HORIZON:
			_draw_horizon(time)
		if banner_left > 0.0:
			_draw_banner(time)
		if bool(time.get("day_warning", false)) and not bool(time.get("final_active", false)):
			_draw_warning(time)
		if bool(time.get("final_active", false)):
			_draw_final(time)
	_draw_flyers()

## The dusk creeping in from the top and bottom edges as doom approaches.
func _draw_edge_wash(time: Dictionary) -> void:
	var amount: float = DuskStyle.edge_wash(time)
	if amount <= 0.001:
		return
	InkDraw.wash(self, Rect2(0, 0, size.x, size.y * 0.32), Color(DuskStyle.DUSK_TOP, amount), Color(DuskStyle.DUSK_TOP, 0.0))
	InkDraw.wash(self, Rect2(0, size.y * 0.62, size.x, size.y * 0.38), Color(DuskStyle.DUSK_BOTTOM, 0.0), Color(DuskStyle.DUSK_BOTTOM, amount))

func _draw_last_life() -> void:
	var strength: float = 0.55 + 0.25 * sin(clock * 4.0)
	for i: int in range(10):
		var inset: float = i * 10.0
		# Stronger than the EXP-002 sample (0.16) so it reads over dark rooms too.
		draw_rect(Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0), Color(DuskStyle.LIFE, strength * (1.0 - i / 10.0) * 0.45), false, 11.0)
	drawn["last_life"] = {"color": DuskStyle.LIFE, "strength": strength}

func _arc(radius: float, index: int, color: Color, width: float) -> void:
	var span: float = TAU / base_maximum()
	var from: float = -PI / 2.0 + span * index + 0.07
	draw_arc(CENTER, radius, from, from + span - 0.14, 10, color, width, true)

func _draw_emblem(time: Dictionary) -> void:
	var actions: PlayerPossibility = player.possibility
	var base: int = base_maximum()
	var flash: float = deny_flash()
	var glow: float = DuskStyle.glow_strength(time) * DuskStyle.breath(time, clock)
	var seed: int = 7
	drawn["deny_flash"] = flash
	InkDraw.paper_disc(self, CENTER + Vector2(3, 4), OUTER + 18, Color(0, 0, 0, 0.25), seed)
	InkDraw.paper_disc(self, CENTER, OUTER + 16, Color(DuskStyle.paper_color(time), DuskStyle.PANEL_ALPHA), seed, DuskStyle.WOBBLE)
	InkDraw.paper_disc(self, CENTER, OUTER + 14, Color(DuskStyle.DUSK_TOP.lerp(DuskStyle.DUSK_BOTTOM, 0.5), 0.35 * DuskStyle.glass(time)), seed + 1, 0.0)
	InkDraw.rough_circle(self, CENTER, OUTER + 16, Color(DuskStyle.INK, 0.85), DuskStyle.INK_WIDTH, seed, DuskStyle.WOBBLE)
	var pulse: float = clampf(gain_pulse / 0.35, 0.0, 1.0)
	var filled: int = 0
	var debt: int = 0
	for i: int in range(base):
		_arc(RING, i, Color(DuskStyle.INK, 0.14).lerp(DuskStyle.DENY, flash * 0.35), 15.0)
		if i < actions.balance:
			_arc(RING, i, Color(DuskStyle.POSSIBILITY_GLOW, 0.3 * glow), 24.0)
			var fill: Color = DuskStyle.POSSIBILITY.lerp(DuskStyle.POSSIBILITY_GLOW, pulse * 0.6).lerp(DuskStyle.DENY, flash * 0.6)
			_arc(RING, i, fill, 12.0)
			drawn["possibility_fill"] = fill
			filled += 1
		elif i >= base + mini(0, actions.balance):
			# Overdraft darkens from the top, counter-clockwise.
			var owed: Color = DuskStyle.OVERDRAFT.lerp(DuskStyle.DENY, flash * 0.6)
			_arc(RING, i, owed, 12.0)
			drawn["overdraft_fill"] = owed
			debt += 1
	var outline: Color = Color(DuskStyle.INK, 0.5 + flash * 0.4).lerp(DuskStyle.DENY, flash * 0.5)
	InkDraw.rough_circle(self, CENTER, RING + 10, outline, 1.4 + flash * 1.5, seed + 2, DuskStyle.WOBBLE * 0.6)
	InkDraw.rough_circle(self, CENTER, RING - 10, Color(DuskStyle.INK, 0.5), 1.4, seed + 3, DuskStyle.WOBBLE * 0.6)
	drawn["ring_outline"] = outline
	# Growth: extra capacity as an outer arc; lit once the balance reaches it.
	var growth: int = maxi(0, actions.maximum - base)
	var growth_lit: int = 0
	for i: int in range(growth):
		var lit: bool = actions.balance > base + i
		var arc: Color = DuskStyle.GROWTH if lit else Color(DuskStyle.GROWTH, 0.35)
		_arc(OUTER, i % base, arc, 7.0)
		# Record the colour the growth segment was really drawn with.
		drawn["growth_fill" if lit else "growth_dim"] = arc
		growth_lit += 1 if lit else 0
	# Life: inked vermilion shards, current count only.
	var count: int = maxi(0, player.life.health)
	var left: float = CENTER.x - (count - 1) * 12.0
	for i: int in range(count):
		var c: Vector2 = Vector2(left + i * 24.0, CENTER.y)
		var shard: PackedVector2Array = PackedVector2Array([c + Vector2(0, -26), c + Vector2(9, 0), c + Vector2(0, 26), c + Vector2(-9, 0)])
		draw_colored_polygon(shard, DuskStyle.LIFE)
		drawn["life_fill"] = DuskStyle.LIFE
		shard.append(shard[0])
		draw_polyline(shard, Color(DuskStyle.INK, 0.8), 1.6, true)
	var healing: float = 0.0
	if actions.state == PlayerPossibility.State.HEALING:
		healing = clampf(1.0 - actions.remaining / actions.config.heal_duration, 0.0, 1.0)
		draw_arc(CENTER, RING - 18, -PI / 2.0, -PI / 2.0 + TAU * healing, 40, Color(DuskStyle.LIFE, 0.85), 3.0, true)
	# Pearls under the emblem and the reach tag beside it (T7 G-02).
	var pearls: int = clampi(player.combat.pearl_count, 0, PEARL_MAX)
	for i: int in range(PEARL_MAX):
		var p: Vector2 = CENTER + Vector2.from_angle(PI * 0.5 + (i - 1.5) * 0.28) * (OUTER + 34)
		if i < pearls:
			draw_circle(p, 7, DuskStyle.PEARL)
		# Pearls sit over the game scene, not paper, so their outline is light.
		InkDraw.rough_circle(self, p, 7, Color(DuskStyle.PAPER_DAY, 0.75), 1.6, 40 + i, 0.6)
	var tag: Rect2 = Rect2(CENTER + Vector2(OUTER + 34, -22), Vector2(150, 40))
	DuskStyle.panel(self, tag, time, 21)
	var reach: String = "范围 %d%%" % reach_percent()
	ink_text(tag.position + Vector2(14, 28), reach, UiTheme.SIZE_BODY - 2)
	var record: Dictionary = {"life": count, "balance": actions.balance, "filled": filled, "overdraft": debt, "growth": growth, "growth_lit": growth_lit, "pearls": pearls, "reach": reach, "healing": healing, "rect": Rect2(CENTER - Vector2.ONE * (OUTER + 42), Vector2.ONE * (OUTER + 42) * 2.0).merge(tag)}
	if session != null and session.has_method("medkit_count"):
		var med: Rect2 = Rect2(tag.position + Vector2(0, 50), Vector2(110, 38))
		DuskStyle.panel(self, med, time, 23)
		draw_rect(Rect2(med.position + Vector2(16, 12), Vector2(6, 16)), DuskStyle.LIFE)
		draw_rect(Rect2(med.position + Vector2(11, 17), Vector2(16, 6)), DuskStyle.LIFE)
		var medkits: String = "× %d" % int(session.call("medkit_count"))
		ink_text(med.position + Vector2(36, 27), medkits, UiTheme.SIZE_BODY - 2)
		record["medkits"] = medkits
		record["rect"] = (record["rect"] as Rect2).merge(med)
	drawn["emblem"] = record

## Paper tag behind LifeUI's control hint (user kept the hints, 2026-10-21).
func _draw_hint(time: Dictionary) -> void:
	if hint == null or not hint.is_visible_in_tree() or hint.text.is_empty():
		return
	var box: Rect2 = Rect2(hint.global_position - global_position, hint.size).grow_individual(12, 4, 12, 4)
	DuskStyle.panel(self, box, time, 25)
	drawn["hint"] = {"text": hint.text, "rect": box}

func _draw_horizon(time: Dictionary) -> void:
	var y: float = size.y - 40
	var x: float = size.x * float(time.get("day_progress", 0.0))
	var glow: float = DuskStyle.glow_strength(time) * DuskStyle.breath(time, clock)
	InkDraw.rough_line(self, Vector2(0, y), Vector2(size.x, y), Color(DuskStyle.PAPER_DAY, 0.45), 2.0, 61, DuskStyle.WOBBLE)
	InkDraw.rough_line(self, Vector2(0, y), Vector2(x, y), Color(DuskStyle.SUN, 0.8), 2.6, 62, DuskStyle.WOBBLE)
	InkDraw.glow(self, Vector2(x, y), 12, DuskStyle.SUN, glow)
	draw_circle(Vector2(x, y), 8, DuskStyle.SUN)
	var tag: Rect2 = Rect2(Vector2(clampf(x - 46, 8, size.x - 100), y - 52), Vector2(92, 34))
	DuskStyle.panel(self, tag, time, 63)
	var at: String = clock_text(time)
	ink_text(tag.position + Vector2(0, 25), at, UiTheme.SIZE_BODY - 2, DuskStyle.INK, HORIZONTAL_ALIGNMENT_CENTER, tag.size.x)
	var day: int = int(time["day"])
	var date: Rect2 = Rect2(Vector2(size.x - 230, y + 6), Vector2(210, 28))
	DuskStyle.panel(self, date, time, 64)
	var date_text: String = "第%d日 · 末日前%d天" % [day, days_left(day)]
	ink_text(date.position + Vector2(0, 21), date_text, UiTheme.SIZE_SMALL - 1, DuskStyle.INK, HORIZONTAL_ALIGNMENT_CENTER, date.size.x)
	drawn["horizon"] = {"clock": at, "sun_x": x, "date": date_text, "sun": DuskStyle.SUN, "glow": glow, "rect": Rect2(0, tag.position.y, size.x, size.y - tag.position.y)}

## "第 二 日": the day in Chinese numerals, spaced like the reference title.
static func day_name(day: int) -> String:
	var numeral: String = DAY_NUMERALS[day] if day >= 0 and day < DAY_NUMERALS.size() else str(day)
	return "第 %s 日" % numeral

func _draw_banner(time: Dictionary) -> void:
	var total: float = DayClock.CONFIG.announcement_seconds
	var t: float = total - banner_left
	var fade: float = clampf(banner_left / 0.9, 0.0, 1.0)
	var c: Vector2 = DAY_CENTER
	var r: float = DAY_RADIUS
	# 1. The half sun rises from behind a short horizon line.
	var rise: float = ease(clampf(t / 0.7, 0.0, 1.0), 0.4)
	var lift: float = (1.0 - rise) * r * 0.6
	InkDraw.glow(self, c, r * 1.5, DuskStyle.SUN, 0.4 * rise * fade)
	# Three translucent layers, densest at the core, so the sun reads as light
	# rather than a flat disc and the scene still shows through its rim.
	for layer: Array in [[1.0, DuskStyle.SUN, 0.22], [0.82, DuskStyle.SUN, 0.26], [0.6, DuskStyle.DUSK_BOTTOM, 0.34]]:
		var half_disc: PackedVector2Array = []
		for i: int in range(33):
			var a: float = PI + PI * i / 32.0
			var reach: float = r * float(layer[0])
			half_disc.append(Vector2(c.x + cos(a) * reach, minf(c.y + sin(a) * reach + lift, c.y)))
		draw_colored_polygon(half_disc, Color(layer[1] as Color, float(layer[2]) * rise * fade))
	InkDraw.rough_line(self, c - Vector2(r + 70, 0), c + Vector2(r + 70, 0), Color(DuskStyle.PAPER_DAY, 0.6 * rise * fade), 1.6, 71, DuskStyle.WOBBLE)
	# 2. Thin rings sweep open from the top, the outer one ticked like a dial.
	for k: int in range(3):
		var open: float = ease(clampf((t - 0.25 - 0.15 * k) / 0.8, 0.0, 1.0), 0.5)
		if open <= 0.0:
			continue
		var radius: float = r + 12.0 + 12.0 * k
		var half: float = PI * 0.5 * open
		var ring: Color = Color(DuskStyle.PAPER_DAY, (0.55 - 0.12 * k) * fade)
		draw_arc(c, radius, -PI * 0.5 - half, -PI * 0.5 + half, 48, ring, 1.4, true)
		if k == 2:
			for step: int in range(-7, 8):
				var a: float = -PI * 0.5 + step * PI / 15.0
				if absf(a + PI * 0.5) > half:
					continue
				var length: float = 10.0 if step % 3 == 0 else 5.0
				var dir: Vector2 = Vector2(cos(a), sin(a))
				draw_line(c + dir * radius, c + dir * (radius + length), ring, 1.2, true)
	# 3. A vertical line rises through the centre to a small diamond.
	var grow: float = ease(clampf((t - 0.4) / 0.6, 0.0, 1.0), 0.4)
	if grow > 0.0:
		var top: float = c.y - (r + 44.0) * grow
		draw_line(c, Vector2(c.x, top), Color(DuskStyle.PAPER_DAY, 0.75 * fade), 1.4, true)
		if grow > 0.95:
			draw_arc(Vector2(c.x, c.y - r - 36.0), 3.5, 0.0, TAU, 12, Color(DuskStyle.PEARL, 0.8 * fade), 1.2, true)
			var tip: Vector2 = Vector2(c.x, top)
			draw_colored_polygon(PackedVector2Array([tip + Vector2(0, -6), tip + Vector2(4, 0), tip + Vector2(0, 6), tip + Vector2(-4, 0)]), Color(DuskStyle.PEARL, 0.85 * fade))
	# 4. The day name fades in beneath, settling upward.
	var shown: float = clampf((t - 0.5) / 0.6, 0.0, 1.0)
	var alpha: float = shown * fade
	var settle: float = (1.0 - shown) * 10.0
	var title: String = day_name(banner_day)
	var line_box: Rect2 = Rect2(Vector2(c.x - 300.0, 0), Vector2(600, 0))
	ink_text(Vector2(line_box.position.x + 2.0, c.y + 52.0 + settle), title, 46, Color(DuskStyle.INK, 0.45 * alpha), HORIZONTAL_ALIGNMENT_CENTER, line_box.size.x)
	ink_text(Vector2(line_box.position.x, c.y + 50.0 + settle), title, 46, Color(DuskStyle.PEARL, alpha), HORIZONTAL_ALIGNMENT_CENTER, line_box.size.x)
	ink_text(Vector2(line_box.position.x, c.y + 76.0 + settle), "末日前 %d 天" % days_left(banner_day), 22, Color(DuskStyle.LIFE, alpha), HORIZONTAL_ALIGNMENT_CENTER, line_box.size.x)
	# From the diamond tip (r + 50 above the centre) down to the subtitle's descent.
	var box: Rect2 = Rect2(Vector2(c.x - r - 70.0, c.y - r - 52.0), Vector2((r + 70.0) * 2.0, r + 52.0 + 84.0))
	drawn["banner"] = {"day": banner_day, "text": title, "rect": box, "elapsed": t, "sun": rise, "rings": ease(clampf((t - 0.55) / 0.8, 0.0, 1.0), 0.5), "title_alpha": alpha}

func _draw_warning(time: Dictionary) -> void:
	var left: int = ceili(float(time.get("day_warning_remaining", 0.0)))
	var box: Rect2 = Rect2(Vector2(size.x - 420, size.y - 150), Vector2(380, 50))
	DuskStyle.panel(self, box, time, 81)
	var text: String = "即将进入第 %d 日 · %d:%02d" % [int(time["day"]) + 1, int(left / 60.0), left % 60]
	ink_text(box.position + Vector2(18, 34), text, UiTheme.SIZE_BODY - 1)
	var blink: float = 0.5 + 0.5 * sin(clock * 5.0)
	InkDraw.rough_line(self, box.position + Vector2(16, 42), box.position + Vector2(box.size.x - 16, 42), Color(DuskStyle.LIFE, 0.4 + 0.5 * blink), 2.2, 82, DuskStyle.WOBBLE)
	drawn["warning"] = {"text": text, "rect": box}

func _draw_final(time: Dictionary) -> void:
	var box: Rect2 = Rect2(Vector2((size.x - 470) * 0.5, 54), Vector2(470, 112))
	var real: float = float(time.get("final_remaining", 0.0))
	var value: float = real
	var label: String = "最终战倒计时"
	var color: Color = DuskStyle.INK
	if accelerate_left > 0.0:
		var progress: float = 1.0 - accelerate_left / ACCELERATE_SECONDS
		value = lerpf(accelerate_from, real, ease(progress, 2.2))
		label = "时间加速……"
	elif bool(time.get("final_start_known", false)) and float(time.get("final_start_day3_remaining", FINAL_BUDGET)) < FINAL_BUDGET:
		# A-016: less than 15 minutes left at the start shows the real remainder in vermilion.
		label = "最终战倒计时 · 余时不足"
		color = DuskStyle.LIFE
	InkDraw.glow(self, box.get_center(), 140, DuskStyle.DUSK_BOTTOM, DuskStyle.glow_strength(time) * DuskStyle.breath(time, clock))
	DuskStyle.panel(self, box, time, 91)
	var dial: Vector2 = box.position + Vector2(62, 56)
	InkDraw.rough_circle(self, dial, 32, Color(DuskStyle.INK, 0.85), 2.2, 92, DuskStyle.WOBBLE)
	var hand: float = -PI / 2.0 + TAU * fmod(value, 60.0) / 60.0
	draw_line(dial, dial + Vector2.from_angle(hand) * 24, color, 3.0, true)
	draw_circle(dial, 4, DuskStyle.SUN)
	var seconds: int = ceili(value)
	ink_text(box.position + Vector2(118, 36), label, 21, Color(color, 0.85))
	var digits: String = "%02d:%02d" % [int(seconds / 60.0), seconds % 60]
	ink_text(box.position + Vector2(118, 92), digits, 50, color)
	drawn["final"] = {"label": label, "digits": digits, "shown": value, "real": real, "color": color, "rect": box}

func _draw_flyers() -> void:
	var to: Vector2 = gain_target()
	var live: int = 0
	for flyer: Dictionary in flyers:
		var t: float = float(flyer["t"])
		if t < 0.0:
			continue
		var from: Vector2 = flyer["from"]
		var control: Vector2 = from.lerp(to, 0.5) + Vector2(0, -260)
		var eased: float = ease(t, 0.6)
		var at: Vector2 = from.lerp(control, eased).lerp(control.lerp(to, eased), eased)
		InkDraw.glow(self, at, 7, DuskStyle.POSSIBILITY_GLOW, 1.4)
		draw_circle(at, 4, DuskStyle.PEARL)
		live += 1
	drawn["flyers"] = {"count": flyers.size(), "live": live, "target": to}
