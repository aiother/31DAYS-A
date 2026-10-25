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
		for prim: Dictionary in prims:
			strongest = maxf(strongest, (prim["color"] as Color).a)
			for point: Vector2 in prim["points"]:
				sum += point
				count += 1
		record["alpha"] = strongest
		record["centroid"] = sum / count if count > 0 else Vector2.INF
		# Every colour actually drawn (review R2): looks are checked from these.
		record["colors"] = prims.map(func(prim: Dictionary) -> Color: return prim["color"])
		out.append(record)
	return out

# --- drawing helpers that return what they drew ---------------------------

func _note(color: Color, points: PackedVector2Array) -> Color:
	_prims.append({"color": color, "points": points})
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
	return _note(color, PackedVector2Array([at]))

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
	return _note(tint, PackedVector2Array([center]))

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

## An enemy is about to strike (G-07, ordinary attack): a pearl ring that
## pulses quickly around the body and a short warm stroke along the coming blow.
func _windup(e: Dictionary, _t: float) -> Dictionary:
	var c: Vector2 = e["at"]
	var k: float = float(e["size"])
	var pulse: float = 0.5 + 0.5 * sin(clock * 22.0)
	_glow(c, 26.0 * k, DuskStyle.SUN, 0.35 + 0.25 * pulse)
	_ring(c, (30.0 + 6.0 * pulse) * k, Color(DuskStyle.PEARL, 0.55 + 0.35 * pulse), 2.5, e["seed"], 1.5)
	var dir: Vector2 = e["dir"]
	_line(c + dir * 34.0 * k, c + dir * 62.0 * k, Color(DuskStyle.SUN, 0.8), 3.0)
	return {"heavy": false}

## A heavy or strong blow is coming (single-colour strong attack, Tian heavy,
## both Bosses): vermilion, larger and doubled, with ink specks and a long
## stroke, so it cannot be mistaken for the ordinary cue.
func _windup_heavy(e: Dictionary, _t: float) -> Dictionary:
	var c: Vector2 = e["at"]
	var k: float = float(e["size"])
	var pulse: float = 0.5 + 0.5 * sin(clock * 14.0)
	_glow(c, 40.0 * k, DuskStyle.LIFE, 0.45 + 0.35 * pulse)
	_ring(c, (42.0 + 10.0 * pulse) * k, Color(DuskStyle.LIFE, 0.8), 4.5, e["seed"], 3.0)
	_ring(c, (58.0 + 10.0 * pulse) * k, Color(DuskStyle.LIFE, 0.45), 2.5, e["seed"] + 5, 3.0)
	var dir: Vector2 = e["dir"]
	_line(c + dir * 48.0 * k, c + dir * 120.0 * k, Color(DuskStyle.LIFE, 0.9), 5.0)
	for i: int in range(5):
		var p: Vector2 = c + Vector2.from_angle(TAU * _n(i, e["seed"])) * (50.0 + 14.0 * _n(i, e["seed"] + 1)) * k
		_dot(p, 3.0 * k, Color(DuskStyle.LIFE, 0.6 + 0.3 * pulse))
	return {"heavy": true}

## A Boss is defeated: a large warm burst, a vermilion ink ring opening wide
## and many pearl shards; longer and larger than an ordinary defeat.
func _boss_death(e: Dictionary, t: float) -> Dictionary:
	var c: Vector2 = e["at"]
	var k: float = float(e["size"])
	var a: float = 1.0 - t
	_glow(c, 90.0 * k * (1.0 - t * 0.4), DuskStyle.SUN, a)
	_ring(c, (40.0 + t * 200.0) * k, Color(DuskStyle.LIFE, 0.8 * a), 6.0, e["seed"], 4.0)
	_ring(c, (20.0 + t * 120.0) * k, Color(DuskStyle.PEARL, 0.6 * a), 3.0, e["seed"] + 3, 2.0)
	for i: int in range(18):
		var dir: Vector2 = Vector2.from_angle(TAU * i / 18.0 + _n(i, e["seed"]))
		var p: Vector2 = c + dir * (20.0 + t * 220.0 * (0.6 + 0.4 * _n(i, e["seed"] + 1))) * k
		_poly(PackedVector2Array([p, p + dir.rotated(0.5) * 14.0 * k, p + dir * 26.0 * k]), Color(DuskStyle.PEARL, a), 2.5)
	return {}

## A reinforcement arrives: brush strokes gathering onto the spot and a
## closing ring; vermilion accents for enemies, possibility teal for allies.
func _arrival_enemy(e: Dictionary, t: float) -> Dictionary:
	return _arrival(e, t, DuskStyle.LIFE)

func _arrival_ally(e: Dictionary, t: float) -> Dictionary:
	return _arrival(e, t, DuskStyle.POSSIBILITY_GLOW)

func _arrival(e: Dictionary, t: float, tint: Color) -> Dictionary:
	var c: Vector2 = e["at"]
	var a: float = _fade(t)
	_glow(c, 36.0, tint, a * 0.7)
	_ring(c, 70.0 - t * 40.0, Color(DuskStyle.PAPER_DAY, a), 2.5, e["seed"], 2.0)
	for i: int in range(6):
		var dir: Vector2 = Vector2.from_angle(TAU * i / 6.0 + _n(i, e["seed"]) * 0.5)
		var far: float = 90.0 * (1.0 - t)
		_line(c + dir * (far + 24.0), c + dir * far, Color(tint, a), 3.0)
	return {}
