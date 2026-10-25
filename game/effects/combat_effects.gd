class_name CombatEffects
extends Node2D
## FX-001 combat feedback, drawn in code in the look the user chose in EXP-005
## (2026-10-23, "D · 融合"): the swing and the hit use the ink-splatter brush
## over a warm glow with pearl specks; every other effect is the light-trace
## look. World coordinates; one entry per running effect. Loops (healing,
## invulnerability) last until stopped.
## `drawn` lists what the last frame put on screen. Every primitive goes
## through a helper below that records it (EXP-005 review R1), so an effect
## that draws nothing cannot pass as drawn.
const LIFE: Dictionary = {
	"swing": 0.22, "hit": 0.40, "bounce": 0.28, "reflect": 0.32, "dodge": 0.28, "poor_dodge": 0.36,
	"spend": 0.42, "gain": 0.50, "heal_done": 0.52, "hurt": 0.30, "enemy_hurt": 0.20,
	"enemy_death": 0.66, "revive": 0.86,
	# FX-002
	"boss_death": 1.20, "arrival_enemy": 0.70, "arrival_ally": 0.70,
}
## Loops last until stopped; the wind-up cues (FX-002, G-07) follow an enemy
## for exactly as long as its wind-up lasts.
const LOOPS: Array[String] = ["heal_loop", "invuln", "windup", "windup_heavy"]
## Height of a body's centre above its feet.
const CHEST: Vector2 = Vector2(0, -48)

var entries: Array[Dictionary] = []
## Summaries of what the last frame drew, built only when read (tests), so a
## crowded fight does not pay for them every frame.
var drawn: Array[Dictionary]:
	get = _summaries
var clock: float = 0.0
var _serial: int = 0
var _prims: Array[Dictionary] = []
var _frame: Array[Dictionary] = []
## One soft radial texture for every glow: a single quad instead of the
## sixteen stacked circles UI-001 uses for its few large glows.
static var _glow_texture: GradientTexture2D

func _ready() -> void:
	z_as_relative = false
	z_index = 20

## Starts an effect at `at` (world space). `follow` makes it track a body.
## `size` scales the drawing (a Boss's cue is drawn larger than an ordinary one).
func spawn(kind: String, at: Vector2, direction: Vector2 = Vector2.RIGHT, follow: Node2D = null, size: float = 1.0) -> Dictionary:
	_serial += 1
	var entry: Dictionary = {"kind": kind, "at": at, "dir": direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT,
		"age": 0.0, "life": INF if kind in LOOPS else float(LIFE[kind]), "seed": _serial * 37, "follow": follow, "serial": _serial,
		"size": size}
	if follow != null:
		entry["offset"] = at - follow.global_position
	entries.append(entry)
	queue_redraw()
	return entry

## Freezes the newest effect of this kind for `seconds` (the swing that just
## landed stays caught in the target during the hit-stop). Returns whether one
## was found.
func hold(kind: String, seconds: float) -> bool:
	for i: int in range(entries.size() - 1, -1, -1):
		if entries[i]["kind"] == kind:
			entries[i]["hold"] = maxf(float(entries[i].get("hold", 0.0)), seconds)
			return true
	return false

## Ends one particular effect (one enemy's wind-up cue among several).
func stop_entry(entry: Dictionary) -> void:
	entries.erase(entry)
	queue_redraw()

func stop(kind: String) -> void:
	entries = entries.filter(func(entry: Dictionary) -> bool: return entry["kind"] != kind)
	queue_redraw()

func active(kind: String) -> bool:
	return entries.any(func(entry: Dictionary) -> bool: return entry["kind"] == kind)

func clear() -> void:
	entries.clear()
	_frame.clear()
	queue_redraw()

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	clock += delta
	for entry: Dictionary in entries:
		var held: float = float(entry.get("hold", 0.0))
		if held > 0.0:
			entry["hold"] = maxf(0.0, held - delta)
		else:
			entry["age"] = float(entry["age"]) + delta
		var follow: Variant = entry["follow"]
		# A freed body still reads as an Object but compares equal to null.
		if typeof(follow) == TYPE_OBJECT and not is_instance_valid(follow):
			# The body it followed is gone: a loop (an enemy's wind-up cue) ends
			# with it; a finite effect stays where it last was and runs out.
			entry["follow"] = null
			if is_inf(float(entry["life"])):
				entry["age"] = INF
		elif is_instance_valid(follow) and follow is Node2D and held <= 0.0:
			entry["at"] = (follow as Node2D).global_position + (entry["offset"] as Vector2)
	entries = entries.filter(func(entry: Dictionary) -> bool: return float(entry["age"]) < float(entry["life"]))
	queue_redraw()

func _draw() -> void:
	_frame = []
	for entry: Dictionary in entries:
		var t: float = 0.0 if is_inf(float(entry["life"])) else clampf(float(entry["age"]) / float(entry["life"]), 0.0, 1.0)
		_prims = []
		var record: Dictionary = call("_" + str(entry["kind"]), entry, t)
		record["prims"] = _prims
		record["kind"] = entry["kind"]
		record["held"] = float(entry.get("hold", 0.0)) > 0.0
		record["age"] = entry["age"]
		record["life"] = entry["life"]
		record["at"] = entry["at"]
		record["dir"] = entry["dir"]
		record["serial"] = entry["serial"]
		record["size"] = entry["size"]
		_frame.append(record)

func _summaries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for raw: Dictionary in _frame:
		var record: Dictionary = raw.duplicate()
		var prims: Array[Dictionary] = raw["prims"]
		record["prims"] = prims.size()
		record["color"] = prims.back()["color"] if not prims.is_empty() else Color.TRANSPARENT
		var strongest: float = 0.0
		var sum: Vector2 = Vector2.ZERO
		var count: int = 0
		var box: Rect2 = Rect2()
		for prim: Dictionary in prims:
			strongest = maxf(strongest, (prim["color"] as Color).a)
			var reach: Vector2 = Vector2.ONE * float(prim["reach"])
			for point: Vector2 in prim["points"]:
				var spot: Rect2 = Rect2(point - reach, reach * 2.0)
				box = spot if count == 0 else box.merge(spot)
				sum += point
				count += 1
		# How far the drawing actually reaches (review R3): sizes are checked from this.
		record["span"] = maxf(box.size.x, box.size.y)
		record["box"] = box
		# Every point drawn, so where a cue points can be checked (G4 2026-10-25).
		var points: PackedVector2Array = PackedVector2Array()
		for prim: Dictionary in prims:
			points.append_array(prim["points"])
		record["points"] = points
		record["alpha"] = strongest
		record["centroid"] = sum / count if count > 0 else Vector2.INF
		# Every colour actually drawn (review R2): looks are checked from these.
		record["colors"] = prims.map(func(prim: Dictionary) -> Color: return prim["color"])
		out.append(record)
	return out

# --- drawing helpers that return what they drew ---------------------------

func _note(color: Color, points: PackedVector2Array, reach: float = 0.0) -> Color:
	_prims.append({"color": color, "points": points, "reach": reach})
	return color

func _line(a: Vector2, b: Vector2, color: Color, width: float) -> Color:
	draw_line(a, b, color, width, true)
	return _note(color, PackedVector2Array([a, b]))

func _poly(points: PackedVector2Array, color: Color, width: float) -> Color:
	if points.size() < 2:
		return color
	draw_polyline(points, color, width, true)
	return _note(color, points)

func _dot(at: Vector2, radius: float, color: Color) -> Color:
	draw_circle(at, maxf(radius, 0.5), color)
	return _note(color, PackedVector2Array([at]), maxf(radius, 0.5))

func _rect(rect: Rect2, color: Color) -> Color:
	draw_rect(rect, color, true)
	return _note(color, PackedVector2Array([rect.position, rect.end]))

## A soft glow (the reach of UI-001's layered circles, about three radii, in
## one textured quad); recorded at its effective strength.
func _glow(center: Vector2, radius: float, color: Color, strength: float) -> Color:
	if _glow_texture == null:
		var gradient: Gradient = Gradient.new()
		# Close to the summed alpha of the sixteen layers: dense core, long tail.
		gradient.set_color(0, Color(1, 1, 1, 0.62))
		gradient.set_color(1, Color(1, 1, 1, 0.0))
		gradient.add_point(0.34, Color(1, 1, 1, 0.38))
		gradient.add_point(0.6, Color(1, 1, 1, 0.1))
		_glow_texture = GradientTexture2D.new()
		_glow_texture.gradient = gradient
		_glow_texture.fill = GradientTexture2D.FILL_RADIAL
		_glow_texture.fill_from = Vector2(0.5, 0.5)
		_glow_texture.fill_to = Vector2(1.0, 0.5)
		_glow_texture.width = 64
		_glow_texture.height = 64
	var tint: Color = Color(color, color.a * clampf(strength, 0.0, 1.0))
	var reach: float = radius * 2.95
	draw_texture_rect(_glow_texture, Rect2(center - Vector2(reach, reach), Vector2(reach, reach) * 2.0), false, tint)
	return _note(tint, PackedVector2Array([center]), reach)

func _ring(center: Vector2, radius: float, color: Color, width: float, seed: int, wobble: float) -> Color:
	return _poly(InkDraw.circle_points(center, radius, seed, wobble), color, width)

func _arc_points(center: Vector2, radius: float, from: float, to: float, count: int = 18) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(count + 1):
		points.append(center + Vector2.from_angle(lerpf(from, to, float(i) / count)) * radius)
	return points

func _n(i: int, seed: int) -> float:
	return InkDraw.noise(i, seed)

## Fades in fast and out over the rest of the life.
func _fade(t: float) -> float:
	return clampf(minf(t / 0.12, (1.0 - t) / 0.6), 0.0, 1.0)

# --- effects ---------------------------------------------------------------

## The attack's trail: a dry paper brush sweeping through the attack
## direction over a warm glow, with a vermilion fleck at its head.
func _swing(e: Dictionary, t: float) -> Dictionary:
	var c: Vector2 = e["at"]
	var base: float = (e["dir"] as Vector2).angle()
	var sweep: float = deg_to_rad(120.0)
	var head: float = base - sweep * 0.5 + sweep * minf(1.0, t * 1.6)
	var tail: float = maxf(base - sweep * 0.5, head - sweep * 0.7)
	var a: float = 1.0 - t
	var glow: Color = _poly(_arc_points(c, 72.0, tail, head, 18), Color(DuskStyle.SUN, 0.28 * a), 28.0)
	var color: Color = glow
	for k: int in range(4):
		var r: float = 64.0 + k * 7.0
		color = _poly(_arc_points(c, r, tail + k * 0.03, head, 16), Color(DuskStyle.PAPER_DAY, a * (0.9 - k * 0.18)), 12.0 - k * 2.6)
	_dot(c + Vector2.from_angle(head) * 70.0, 4.0 * a, Color(DuskStyle.LIFE, a))
	return {"glow": glow}

## A blow landing: a short warm flash, vermilion and pearl specks thrown along
## the blow, and a ring opening at the point of impact.
func _hit(e: Dictionary, t: float) -> Dictionary:
	var c: Vector2 = e["at"]
	var dir: Vector2 = e["dir"]
	var a: float = _fade(t)
	var glow: Color = _glow(c, 22.0 + t * 18.0, DuskStyle.SUN, a)
	for i: int in range(12):
		var spread: float = (_n(i, e["seed"]) - 0.5) * 1.6
		var reach: float = (18.0 + _n(i, e["seed"] + 1) * 52.0) * minf(1.0, t * 3.0)
		_dot(c + dir.rotated(spread) * reach, (3.0 + _n(i, e["seed"] + 2) * 5.0) * (1.0 - t * 0.6), Color(DuskStyle.LIFE if i % 3 else DuskStyle.PEARL, a))
	_ring(c, 10.0 + t * 26.0, Color(DuskStyle.PEARL, 0.7 * a), 3.0, e["seed"], 2.0)
	return {"glow": glow}

## The downward attack's rebound: a ring at the feet and lift lines.
func _bounce(e: Dictionary, t: float) -> Dictionary:
	var c: Vector2 = e["at"] - CHEST
	var a: float = 1.0 - t
	_poly(_arc_points(c, 20.0 + t * 60.0, PI * 0.05, PI * 0.95, 14), Color(DuskStyle.POSSIBILITY_GLOW, a), 4.0)
	for i: int in range(3):
		var x: float = (i - 1) * 16.0
		_line(c + Vector2(x, -10 - t * 30.0), c + Vector2(x, -34 - t * 60.0), Color(DuskStyle.POSSIBILITY_GLOW, 0.8 * a), 2.4)
	return {}

## A projectile knocked back: a flash and a stroke along its new path.
func _reflect(e: Dictionary, t: float) -> Dictionary:
	var c: Vector2 = e["at"]
	var dir: Vector2 = e["dir"]
	var a: float = _fade(t)
	_glow(c, 26.0, DuskStyle.SUN, a)
	_poly(_arc_points(c, 22.0 + t * 18.0, dir.angle() - 1.2, dir.angle() + 1.2, 12), Color(DuskStyle.SUN, a), 3.0)
	_line(c, c + dir * (30.0 + t * 50.0), Color(DuskStyle.SUN, a), 2.4)
	return {}

## Dodging with enough possibility: glowing after-images along the dash.
func _dodge(e: Dictionary, t: float) -> Dictionary:
	return _ghosts(e, t, false)

## Dodging into overdraft: the same in vermilion, with a crack mark.
func _poor_dodge(e: Dictionary, t: float) -> Dictionary:
	return _ghosts(e, t, true)

func _ghosts(e: Dictionary, t: float, poor: bool) -> Dictionary:
	var c: Vector2 = e["at"]
	var back: Vector2 = -(e["dir"] as Vector2)
	var a: float = 1.0 - t
	var tint: Color = DuskStyle.LIFE if poor else DuskStyle.POSSIBILITY_GLOW
	for k: int in range(3):
		var at: Vector2 = c + back * (24.0 + k * 26.0) * (0.5 + t)
		var alpha: float = a * (0.9 - k * 0.25)
		_glow(at, 22.0, tint, alpha)
		_dot(at, 10.0 - k * 2.0, Color(tint, alpha))
	if poor:
		_line(c + Vector2(-10, -10), c + Vector2(10, 10), Color(DuskStyle.LIFE, a), 3.0)
	return {"poor": poor}

## Invulnerability around the player (a loop): a soft pulsing glow.
func _invuln(e: Dictionary, _t: float) -> Dictionary:
	var pulse: float = 0.5 + 0.5 * sin(clock * 14.0)
	_glow(e["at"], 40.0, DuskStyle.POSSIBILITY_GLOW, 0.4 + 0.4 * pulse)
	return {}

## Possibility spent (dodge, heal): teal drops leaving the player.
func _spend(e: Dictionary, t: float) -> Dictionary:
	var c: Vector2 = e["at"]
	var a: float = 1.0 - t
	for i: int in range(6):
		var angle: float = -PI * 0.5 + (_n(i, e["seed"]) - 0.5) * 2.2
		var p: Vector2 = c + Vector2.from_angle(angle) * (14.0 + t * 46.0) + Vector2(0, t * t * 40.0)
		_glow(p, 6.0, DuskStyle.POSSIBILITY_GLOW, a)
		_dot(p, 2.5, Color(DuskStyle.POSSIBILITY_GLOW, a))
	return {}

## Possibility gained at its source (a defeated target, a rescue).
func _gain(e: Dictionary, t: float) -> Dictionary:
	var c: Vector2 = e["at"]
	var a: float = _fade(t)
	for i: int in range(5):
		var p: Vector2 = c + Vector2((_n(i, e["seed"]) - 0.5) * 50.0, -t * (40.0 + _n(i, e["seed"] + 3) * 40.0))
		_glow(p, 8.0, DuskStyle.POSSIBILITY_GLOW, a)
		_dot(p, 3.0, Color(DuskStyle.POSSIBILITY_GLOW, a))
	return {}

## Healing in progress (a loop): motes circling inward.
func _heal_loop(e: Dictionary, _t: float) -> Dictionary:
	var c: Vector2 = e["at"]
	for i: int in range(6):
		var phase: float = fmod(clock * 0.9 + i / 6.0, 1.0)
		var p: Vector2 = c + Vector2.from_angle(TAU * i / 6.0 + clock * 2.0) * (60.0 * (1.0 - phase))
		_glow(p, 8.0, DuskStyle.POSSIBILITY_GLOW, maxf(phase, 0.15))
		_dot(p, 2.5, Color(DuskStyle.POSSIBILITY_GLOW, maxf(phase, 0.15)))
	return {}

## Healing completed: a closing ring and a vermilion life mark.
func _heal_done(e: Dictionary, t: float) -> Dictionary:
	var c: Vector2 = e["at"]
	var a: float = 1.0 - t
	_glow(c, 30.0 + t * 30.0, DuskStyle.LIFE, a)
	_poly(InkDraw.circle_points(c, 70.0 - t * 40.0, e["seed"], 0.5, 36), Color(DuskStyle.PAPER_DAY, a), 2.0)
	_dot(c, 6.0 * a, Color(DuskStyle.LIFE, a))
	return {}

## The player is hit.
func _hurt(e: Dictionary, t: float) -> Dictionary:
	var c: Vector2 = e["at"]
	var a: float = 1.0 - t
	_glow(c, 40.0, DuskStyle.DENY, a)
	_poly(InkDraw.circle_points(c, 30.0 + t * 30.0, 0, 0.0, 32), Color(DuskStyle.DENY, a), 3.0)
	return {}

## A target is hit (its own flash over the body).
func _enemy_hurt(e: Dictionary, t: float) -> Dictionary:
	_rect(Rect2((e["at"] as Vector2) - Vector2(30, 40), Vector2(60, 80)), Color(DuskStyle.PAPER_DAY, (1.0 - t) * 0.7))
	return {}

## A target is defeated: a warm burst and pearl shards flying out.
func _enemy_death(e: Dictionary, t: float) -> Dictionary:
	var c: Vector2 = e["at"]
	var a: float = 1.0 - t
	_glow(c, 50.0 * (1.0 - t * 0.5), DuskStyle.SUN, a)
	for i: int in range(10):
		var dir: Vector2 = Vector2.from_angle(TAU * i / 10.0 + _n(i, e["seed"]))
		var p: Vector2 = c + dir * (10.0 + t * 110.0)
		_poly(PackedVector2Array([p, p + dir.rotated(0.5) * 10.0, p + dir * 18.0]), Color(DuskStyle.PEARL, a), 2.0)
	return {}

## Revival at a checkpoint: a column of light rising from the feet.
func _revive(e: Dictionary, t: float) -> Dictionary:
	var c: Vector2 = e["at"] - CHEST
	var a: float = _fade(t)
	_glow(c + Vector2(0, -60), 60.0, DuskStyle.SUN, a)
	_line(c, c + Vector2(0, -180.0 * t), Color(DuskStyle.PEARL, a), 6.0)
	return {}

# --- FX-002 ------------------------------------------------------------------
# Enemy cues are the enemy's own: a glint at its eye that flares twice over
# the wind-up (T2 §14 "闪烁") and a mark of the coming blow drawn out as the
# wind-up runs, shaped by what that enemy does (G4 2026-10-25: not the
# player's hit look). Ordinary blows never use vermilion; heavy and strong
# blows and every Boss blow are vermilion and carry no pearl. Entry fields set
# by the director: "style", "attack", "expect" (wind-up seconds), "facing",
# "count", and for aimed blows "aim_from" / "aim_to" (world space, live).

func _windup(e: Dictionary, _t: float) -> Dictionary:
	return _cue(e, false)

func _windup_heavy(e: Dictionary, _t: float) -> Dictionary:
	return _cue(e, true)

func _cue(e: Dictionary, heavy: bool) -> Dictionary:
	var p: float = clampf(float(e["age"]) / maxf(0.05, float(e.get("expect", 0.5))), 0.0, 1.0)
	match String(e.get("style", "colorless")):
		"mono": _cue_mono(e, p, heavy)
		"tian": _cue_tian(e, p, heavy)
		"overlook": _cue_overlook(e, p)
		"parasite": _cue_parasite(e, p)
		_: _cue_colorless(e, p, heavy)
	return {"heavy": heavy, "progress": p}

## A four-point glint at the eye, flaring twice over the wind-up.
func _glint(at: Vector2, size: float, color: Color, p: float) -> void:
	var flare: float = absf(sin(p * TAU))
	var r: float = size * (0.45 + 0.55 * flare)
	var tint: Color = Color(color, 0.55 + 0.45 * flare)
	_inked(PackedVector2Array([at - Vector2(r, 0), at + Vector2(r, 0)]), tint, 2.0)
	_inked(PackedVector2Array([at - Vector2(0, r * 1.7), at + Vector2(0, r * 1.7)]), tint, 2.0)
	_dot(at, 3.5 + 2.0 * flare, Color(DuskStyle.INK, 0.5))
	_dot(at, 2.0 + 2.0 * flare, Color(color, 0.95))

## A stroke with a dark ink edge under it, so it reads on light and dark ground.
func _inked(points: PackedVector2Array, color: Color, width: float) -> void:
	_poly(points, Color(DuskStyle.INK, color.a * 0.55), width + 3.0)
	_poly(points, color, width)

func _eye(e: Dictionary, k: float = 1.0) -> Vector2:
	return (e["at"] as Vector2) + Vector2(float(e.get("facing", 1.0)) * 12.0, -12.0) * k

## Colourless (grey, formless): three ash claw marks reaching out ahead, or a
## dotted aim toward its target for a throw.
func _cue_colorless(e: Dictionary, p: float, heavy: bool) -> void:
	var c: Vector2 = e["at"]
	var tint: Color = DuskStyle.LIFE if heavy else DuskStyle.PEARL
	_glint(_eye(e), 9.0, tint, p)
	if e.get("attack") == "ranged":
		var to: Vector2 = e.get("aim_to", c + (e["dir"] as Vector2) * 220.0)
		var shown: int = maxi(1, ceili(9.0 * p))
		for i: int in range(1, shown + 1):
			_dot(c.lerp(to, float(i) / 10.0), 2.6, Color(tint, 0.8))
		return
	var dir: Vector2 = e["dir"]
	var side: Vector2 = dir.orthogonal()
	for i: int in range(3):
		var a: Vector2 = c + dir * 30.0 + side * (i - 1) * 15.0
		var reach: float = 14.0 + 38.0 * p
		_inked(PackedVector2Array([a - side * 10.0, a + dir * reach * 0.55 - side * 2.0, a + dir * reach + side * 10.0]), Color(tint, 0.45 + 0.5 * p), 3.0)

## Single-colour (violet, fast, dashing): chevrons running ahead along the lane
## it will cut through; a strong blow is vermilion, three chevrons and edged.
func _cue_mono(e: Dictionary, p: float, heavy: bool) -> void:
	var c: Vector2 = e["at"]
	var dir: Vector2 = e["dir"]
	var side: Vector2 = dir.orthogonal()
	var tint: Color = DuskStyle.LIFE if heavy else DuskStyle.DUSK_TOP
	_glint(_eye(e), 12.0 if heavy else 9.0, DuskStyle.LIFE if heavy else DuskStyle.PEARL, p)
	var run: float = fmod(clock * 3.0, 1.0)
	for i: int in range(3 if heavy else 2):
		var tip: Vector2 = c + dir * (44.0 + (i + run) * 30.0 * (0.5 + p))
		_inked(PackedVector2Array([tip - dir * 12.0 + side * 13.0, tip, tip - dir * 12.0 - side * 13.0]), Color(tint, 0.4 + 0.55 * p), 4.0 if heavy else 3.0)
	if heavy:
		var length: float = 40.0 + 120.0 * p
		for s: float in [-1.0, 1.0]:
			_line(c + dir * 36.0 + side * 20.0 * s, c + dir * (36.0 + length) + side * 20.0 * s, Color(DuskStyle.LIFE, 0.6 * p), 2.0)

## Tian warrior (gold, armed): one gold slash tick per blow of the combo; a
## heavy blow is a vermilion overhead arc ending in a crack on the ground; a
## throw is a gold aim line toward its target.
func _cue_tian(e: Dictionary, p: float, heavy: bool) -> void:
	var c: Vector2 = e["at"]
	var dir: Vector2 = e["dir"]
	var f: float = signf(dir.x) if not is_zero_approx(dir.x) else float(e.get("facing", 1.0))
	_glint(_eye(e), 12.0 if heavy else 9.0, DuskStyle.LIFE if heavy else DuskStyle.PEARL, p)
	if heavy:
		var start: float = -PI * 0.5 - f * PI * 0.35
		var finish: float = -PI * 0.5 + f * PI * 0.55
		_inked(_arc_points(c + Vector2(f * 20.0, 0), 78.0, start, lerpf(start, finish, 0.25 + 0.75 * p), 16), Color(DuskStyle.LIFE, 0.5 + 0.45 * p), 5.0)
		var ground: Vector2 = c - CHEST + Vector2(f * 90.0, 0)
		var crack: PackedVector2Array = PackedVector2Array()
		for i: int in range(6):
			crack.append(ground + Vector2(f * (i - 2.5) * 14.0 * p, -4.0 * _n(i, e["seed"]) * p))
		_line(ground - Vector2(0, 6), ground - Vector2(0, 6 + 10.0 * p), Color(DuskStyle.LIFE, p), 2.0)
		_inked(crack, Color(DuskStyle.LIFE, 0.4 + 0.5 * p), 2.5)
		return
	if e.get("attack") == "ranged":
		var to: Vector2 = e.get("aim_to", c + dir * 240.0)
		var head: Vector2 = c.lerp(to, 0.25 + 0.6 * p)
		var back: Vector2 = (c - to).normalized()
		_inked(PackedVector2Array([c + (to - c).normalized() * 30.0, head]), Color(DuskStyle.GROWTH, 0.5 + 0.45 * p), 2.5)
		_inked(PackedVector2Array([head + back.rotated(0.5) * 12.0, head, head + back.rotated(-0.5) * 12.0]), Color(DuskStyle.GROWTH, 0.9), 2.5)
		return
	var count: int = maxi(1, int(e.get("count", 2)))
	for i: int in range(count):
		if p < float(i) / count:
			break
		var at: Vector2 = c + Vector2(f * (40.0 + i * 22.0), -14.0 + i * 10.0)
		_inked(PackedVector2Array([at + Vector2(-f * 8.0, -14.0), at + Vector2(f * 8.0, 14.0)]), Color(DuskStyle.GROWTH, 0.9), 3.5)

## Overlook (it looks down, then dives): an eye around it that narrows as the
## dive nears and looks at the marked spot, a dashed dive line down to that
## spot and two brackets closing in on it.
func _cue_overlook(e: Dictionary, p: float) -> void:
	var c: Vector2 = e["at"]
	var k: float = float(e["size"])
	var to: Vector2 = e.get("aim_to", c + Vector2(0, 300))
	var dir: Vector2 = (to - c).normalized() if not (to - c).is_zero_approx() else Vector2.DOWN
	var open: float = 1.0 - 0.6 * p
	var w: float = 34.0 * k
	_inked(_arc_points(c, w, PI * (1.0 + 0.18 * open), PI * (2.0 - 0.18 * open), 14), Color(DuskStyle.LIFE, 0.85), 4.0)
	var lower: PackedVector2Array = _arc_points(c, w, PI * 0.18 * open, PI * (1.0 - 0.18 * open), 14)
	for i: int in range(lower.size()):
		lower[i] = c + (lower[i] - c) * Vector2(1.0, open)
	_inked(lower, Color(DuskStyle.LIFE, 0.85), 4.0)
	_dot(c + dir * 9.0 * k, 5.0 * k * (0.6 + 0.4 * open), Color(DuskStyle.LIFE, 0.95))
	var dashes: int = 8
	for i: int in range(dashes):
		var a: float = float(i) / dashes
		if a > p + 0.15:
			break
		_line(c.lerp(to, a + 0.02), c.lerp(to, a + 0.08), Color(DuskStyle.LIFE, 0.35 + 0.55 * p), 3.0)
	var gap: float = lerpf(150.0, 48.0, p)
	for s: float in [-1.0, 1.0]:
		var x: Vector2 = to + Vector2(gap * s, 0)
		_inked(PackedVector2Array([x + Vector2(-10.0 * s, -26.0), x + Vector2(0, -26.0), x, x + Vector2(-10.0 * s, 0)]), Color(DuskStyle.LIFE, 0.5 + 0.45 * p), 3.5)

## Parasite companion (it fires leeching shots): a swelling sac at its mouth
## and one writhing tendril per shot of the burst, reaching for the target.
func _cue_parasite(e: Dictionary, p: float) -> void:
	var from: Vector2 = e.get("aim_from", e["at"])
	var to: Vector2 = e.get("aim_to", from + Vector2(300, 0))
	var k: float = float(e["size"])
	var dir: Vector2 = (to - from).normalized() if not (to - from).is_zero_approx() else Vector2.RIGHT
	var swell: float = 0.5 + 0.5 * sin(clock * 9.0)
	_dot(from, (6.0 + 6.0 * p + 2.0 * swell) * k, Color(DuskStyle.OVERDRAFT, 0.9))
	_ring(from, (10.0 + 8.0 * p) * k, Color(DuskStyle.LIFE, 0.8), 3.0, e["seed"], 2.0)
	_glint(from + Vector2(0, -22.0 * k), 12.0, DuskStyle.LIFE, p)
	var count: int = maxi(1, int(e.get("count", 3)))
	var length: float = minf(from.distance_to(to), 60.0 + 260.0 * p)
	for i: int in range(count):
		var spread: float = (i - (count - 1) * 0.5) * 0.12
		var line: Vector2 = dir.rotated(spread)
		var points: PackedVector2Array = PackedVector2Array()
		for j: int in range(10):
			var a: float = float(j) / 9.0
			var wave: float = sin(a * 9.0 + clock * 10.0 + i) * 7.0 * a
			points.append(from + line * length * a + line.orthogonal() * wave)
		_inked(points, Color(DuskStyle.LIFE, 0.4 + 0.5 * p), 2.5)

## A Boss is defeated: a burst of its own, longer and much larger than an
## ordinary defeat. Overlook's eye cracks and shatters into ink shards that
## rain down; the parasite bursts into whipping tendrils and blood drops, and
## the possibility it leeched escapes upward.
func _boss_death(e: Dictionary, t: float) -> Dictionary:
	var c: Vector2 = e["at"]
	var k: float = float(e["size"])
	var a: float = 1.0 - t
	var flash: float = clampf(1.0 - t * 4.0, 0.0, 1.0)
	_glow(c, 70.0 * k, DuskStyle.LIFE if e.get("style") == "parasite" else DuskStyle.PEARL, flash)
	if e.get("style") == "parasite":
		for i: int in range(10):
			var dir: Vector2 = Vector2.from_angle(TAU * i / 10.0 + _n(i, e["seed"]) * 0.6)
			var points: PackedVector2Array = PackedVector2Array()
			var reach: float = (30.0 + 110.0 * minf(1.0, t * 2.5)) * k
			for j: int in range(8):
				var s: float = float(j) / 7.0
				points.append(c + dir * reach * s + dir.orthogonal() * sin(s * 7.0 + t * 18.0 + i) * 10.0 * s * k)
			_inked(points, Color(DuskStyle.OVERDRAFT, a), 3.5)
		for i: int in range(24):
			var v: Vector2 = Vector2.from_angle(TAU * _n(i, e["seed"] + 4)) * (120.0 + 180.0 * _n(i, e["seed"] + 5)) * k
			var q: Vector2 = c + v * t + Vector2(0, 260.0 * k * t * t)
			_dot(q, (3.0 + 3.0 * _n(i, e["seed"] + 6)) * k * 0.6, Color(DuskStyle.LIFE, a))
		for i: int in range(8):
			var q: Vector2 = c + Vector2((_n(i, e["seed"] + 7) - 0.5) * 120.0 * k, -t * (80.0 + 80.0 * _n(i, e["seed"] + 8)) * k)
			_glow(q, 8.0 * k * 0.6, DuskStyle.POSSIBILITY_GLOW, a)
		return {"style": "parasite"}
	for i: int in range(6):
		var dir: Vector2 = Vector2.from_angle(TAU * i / 6.0 + _n(i, e["seed"]))
		var crack: PackedVector2Array = PackedVector2Array([c])
		for j: int in range(1, 4):
			crack.append(c + dir.rotated((_n(i * 4 + j, e["seed"]) - 0.5) * 0.6) * j * 16.0 * k * minf(1.0, t * 6.0))
		_poly(crack, Color(DuskStyle.LIFE, clampf(1.0 - t * 2.5, 0.0, 1.0)), 3.0)
	for i: int in range(22):
		var dir: Vector2 = Vector2.from_angle(TAU * i / 22.0 + _n(i, e["seed"] + 1) * 0.4)
		var v: Vector2 = dir * (110.0 + 170.0 * _n(i, e["seed"] + 2)) * k
		var q: Vector2 = c + v * t + Vector2(0, 300.0 * k * t * t)
		var spin: float = t * 8.0 + i
		var size: float = (6.0 + 6.0 * _n(i, e["seed"] + 3)) * k * 0.6
		var shard: PackedVector2Array = PackedVector2Array([q + Vector2.from_angle(spin) * size, q + Vector2.from_angle(spin + 2.2) * size * 0.6, q + Vector2.from_angle(spin + 4.0) * size, q + Vector2.from_angle(spin) * size])
		_poly(shard, Color(DuskStyle.INK, a), 3.0)
		if i % 3 == 0:
			_poly(shard, Color(DuskStyle.LIFE, a), 1.5)
	for i: int in range(5):
		var q: Vector2 = c + Vector2.from_angle(TAU * i / 5.0) * 40.0 * k * t
		_dot(q, (10.0 + 30.0 * t) * k * 0.6, Color(DuskStyle.INK, 0.25 * a))
	return {"style": "overlook"}

## Arrivals look nothing like a cue. An enemy steps out of an ink rift that
## tears open from the ground up and seals behind it; an ally comes down in
## a teal shaft of light that settles on the ground.
func _arrival_enemy(e: Dictionary, t: float) -> Dictionary:
	var feet: Vector2 = (e["at"] as Vector2) - CHEST
	var a: float = _fade(t)
	var open: float = sin(t * PI)
	var height: float = 130.0 * minf(1.0, t * 2.5)
	for s: float in [-1.0, 1.0]:
		var edge: PackedVector2Array = PackedVector2Array()
		for j: int in range(8):
			var y: float = float(j) / 7.0
			edge.append(feet + Vector2(s * (2.0 + 14.0 * open * sin(y * PI) + (_n(j, e["seed"]) - 0.5) * 4.0), -height * y))
		_poly(edge, Color(DuskStyle.INK, a), 4.0)
	_line(feet, feet - Vector2(0, height * 0.9), Color(DuskStyle.LIFE, a * open), 2.0)
	for i: int in range(5):
		var drip: Vector2 = feet + Vector2((_n(i, e["seed"] + 2) - 0.5) * 30.0 * open, -height * _n(i, e["seed"] + 3) + 60.0 * t * t)
		_dot(drip, 2.5, Color(DuskStyle.INK, a))
	_line(feet - Vector2(24.0 * open, 0), feet + Vector2(24.0 * open, 0), Color(DuskStyle.INK, a), 3.0)
	return {}

func _arrival_ally(e: Dictionary, t: float) -> Dictionary:
	var feet: Vector2 = (e["at"] as Vector2) - CHEST
	var a: float = _fade(t)
	var fall: float = minf(1.0, t * 2.2)
	var top: Vector2 = feet - Vector2(0, 200)
	_line(top, top.lerp(feet, fall), Color(DuskStyle.POSSIBILITY_GLOW, a * 0.6), 12.0)
	_line(top, top.lerp(feet, fall), Color(DuskStyle.POSSIBILITY, a), 3.0)
	_line(top + Vector2(-6, 0), (top + Vector2(-6, 0)).lerp(feet + Vector2(-6, 0), fall), Color(DuskStyle.POSSIBILITY, a * 0.6), 2.0)
	_line(top + Vector2(6, 0), (top + Vector2(6, 0)).lerp(feet + Vector2(6, 0), fall), Color(DuskStyle.POSSIBILITY, a * 0.6), 2.0)
	if fall >= 1.0:
		var spread: float = (t - 1.0 / 2.2) * 2.0
		var ripple: PackedVector2Array = _arc_points(feet, 20.0 + 26.0 * spread, PI, TAU, 16)
		for i: int in range(ripple.size()):
			ripple[i] = feet + (ripple[i] - feet) * Vector2(1.0, 0.25)
		_poly(ripple, Color(DuskStyle.POSSIBILITY, a), 3.0)
	for i: int in range(4):
		_dot(top.lerp(feet, fmod(fall + i * 0.25, 1.0)) + Vector2((_n(i, e["seed"]) - 0.5) * 16.0, 0), 3.0, Color(DuskStyle.POSSIBILITY, a))
	return {}
