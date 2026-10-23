extends Node2D
## EXP-005 combat feedback effects in three looks, drawn in code with the
## UI-001 palette (no art assets). Every effect is an entry with a kind, a
## place and a life; loops (healing, invulnerability) last until stopped.
## `drawn` lists what the last frame put on screen, built from what each draw
## call returned.
const STYLES: Array[String] = ["A · 墨迹飞溅", "B · 光痕", "C · 极简几何", "D · 融合（A 的攻击 + B）"]
## Look D (user feedback 2026-10-23): A's swing and hit, with B's warm glow
## under them so they sit in B's light; every other effect is B.
const FUSION: int = 3
const FUSION_FROM_A: Array[String] = ["swing", "hit"]
## Seconds per kind and style (A, B, C). C is the shortest and lightest.
const LIFE: Dictionary = {
	"swing": [0.22, 0.17, 0.12], "hit": [0.40, 0.30, 0.18], "bounce": [0.34, 0.28, 0.18],
	"reflect": [0.40, 0.32, 0.20], "dodge": [0.34, 0.28, 0.20], "poor_dodge": [0.44, 0.36, 0.24],
	"spend": [0.50, 0.42, 0.30], "gain": [0.60, 0.50, 0.36], "heal_done": [0.62, 0.52, 0.36],
	"hurt": [0.38, 0.30, 0.20], "enemy_hurt": [0.26, 0.20, 0.14], "enemy_death": [0.80, 0.66, 0.40],
	"revive": [1.00, 0.86, 0.60],
}
const LOOPS: Array[String] = ["heal_loop", "invuln"]
const KINDS: Array[String] = ["swing", "hit", "bounce", "reflect", "dodge", "poor_dodge", "spend", "gain", "heal_done", "hurt", "enemy_hurt", "enemy_death", "revive", "heal_loop", "invuln"]

var style: int = 0
var entries: Array[Dictionary] = []
var drawn: Array[Dictionary] = []
var clock: float = 0.0
var _serial: int = 0

## Starts an effect at `at` (world space). `follow` makes it track a node.
func spawn(kind: String, at: Vector2, direction: Vector2 = Vector2.RIGHT, follow: Node2D = null) -> Dictionary:
	_serial += 1
	var look: int = look_for(kind, style)
	var life: float = INF if kind in LOOPS else float(LIFE[kind][look])
	var entry: Dictionary = {"kind": kind, "at": at, "dir": direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT,
		"age": 0.0, "life": life, "seed": _serial * 37, "follow": follow, "style": style, "look": look, "fusion": style == FUSION}
	entries.append(entry)
	queue_redraw()
	return entry

## Which of A, B, C draws this kind under the chosen style.
func look_for(kind: String, chosen: int) -> int:
	if chosen != FUSION:
		return chosen
	return 0 if kind in FUSION_FROM_A else 1

## Freezes the newest effect of this kind for `seconds` (used by the
## hit-stop on the swing that just landed). Returns whether one was found.
func hold(kind: String, seconds: float) -> bool:
	for i: int in range(entries.size() - 1, -1, -1):
		if entries[i]["kind"] == kind:
			entries[i]["hold"] = maxf(float(entries[i].get("hold", 0.0)), seconds)
			return true
	return false

func stop(kind: String) -> void:
	entries = entries.filter(func(entry: Dictionary) -> bool: return entry["kind"] != kind)
	queue_redraw()

func active(kind: String) -> bool:
	return entries.any(func(entry: Dictionary) -> bool: return entry["kind"] == kind)

func clear() -> void:
	entries.clear()
	drawn.clear()
	queue_redraw()

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	clock += delta
	for entry: Dictionary in entries:
		# A held effect stays exactly where it is (the blade caught in the
		# target during the hit-stop), then carries on.
		var held: float = float(entry.get("hold", 0.0))
		if held > 0.0:
			entry["hold"] = maxf(0.0, held - delta)
		else:
			entry["age"] = float(entry["age"]) + delta
		var follow: Variant = entry["follow"]
		if follow is Node2D and is_instance_valid(follow):
			entry["at"] = (follow as Node2D).position + Vector2(0, -48)
	entries = entries.filter(func(entry: Dictionary) -> bool: return float(entry["age"]) < float(entry["life"]))
	queue_redraw()

func _draw() -> void:
	drawn = []
	for entry: Dictionary in entries:
		var t: float = 0.0 if is_inf(float(entry["life"])) else clampf(float(entry["age"]) / float(entry["life"]), 0.0, 1.0)
		var record: Dictionary = call("_" + str(entry["kind"]), entry, t, int(entry["look"]))
		record["kind"] = entry["kind"]
		record["style"] = entry["style"]
		record["look"] = entry["look"]
		record["held"] = float(entry.get("hold", 0.0)) > 0.0
		record["age"] = entry["age"]
		record["life"] = entry["life"]
		record["at"] = entry["at"]
		drawn.append(record)

# --- drawing helpers that return what they drew ---------------------------

func _line(a: Vector2, b: Vector2, color: Color, width: float) -> Color:
	draw_line(a, b, color, width, true)
	return color

func _poly(points: PackedVector2Array, color: Color, width: float) -> Color:
	if points.size() >= 2:
		draw_polyline(points, color, width, true)
	return color

func _dot(at: Vector2, radius: float, color: Color) -> Color:
	draw_circle(at, maxf(radius, 0.5), color)
	return color

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

## The attack's trail: an arc sweeping through the attack direction.
func _swing(e: Dictionary, t: float, s: int) -> Dictionary:
	var c: Vector2 = e["at"]
	var base: float = (e["dir"] as Vector2).angle()
	var sweep: float = deg_to_rad(120.0)
	var head: float = base - sweep * 0.5 + sweep * minf(1.0, t * 1.6)
	var tail: float = maxf(base - sweep * 0.5, head - sweep * 0.7)
	var a: float = 1.0 - t
	var color: Color
	var record_glow: Color = Color.TRANSPARENT
	match s:
		0:
			# A dry paper-coloured brush with a bristle edge and a vermilion fleck.
			if e.get("fusion", false):
				# Fusion: B's warm light under A's brush.
				record_glow = _poly(_arc_points(c, 72.0, tail, head, 18), Color(DuskStyle.SUN, 0.28 * a), 28.0)
			for k: int in range(4):
				var r: float = 64.0 + k * 7.0
				color = _poly(_arc_points(c, r, tail + k * 0.03, head, 16), Color(DuskStyle.PAPER_DAY, a * (0.9 - k * 0.18)), 12.0 - k * 2.6)
			_dot(c + Vector2.from_angle(head) * 70.0, 4.0 * a, Color(DuskStyle.LIFE, a))
		1:
			# A thin hot core inside a wide soft glow.
			_poly(_arc_points(c, 70.0, tail, head, 18), Color(DuskStyle.SUN, 0.25 * a), 18.0)
			color = _poly(_arc_points(c, 70.0, tail, head, 18), Color(DuskStyle.PEARL, a), 4.0)
		_:
			color = _poly(_arc_points(c, 70.0, tail, head, 12), Color(DuskStyle.PAPER_DAY, 0.8 * a), 2.0)
	return {"color": color, "glow": record_glow}

## A blow landing on a target.
func _hit(e: Dictionary, t: float, s: int) -> Dictionary:
	var c: Vector2 = e["at"]
	var dir: Vector2 = e["dir"]
	var a: float = _fade(t)
	var color: Color
	var record_glow: Color = Color.TRANSPARENT
	match s:
		0:
			# Ink-like splatter thrown along the blow, vermilion and paper.
			var light: Color = DuskStyle.PAPER_DAY
			if e.get("fusion", false):
				# Fusion: a short warm flash at the point of impact, pearl specks.
				InkDraw.glow(self, c, 22.0 + t * 18.0, DuskStyle.SUN, a)
				record_glow = Color(DuskStyle.SUN, a)
				light = DuskStyle.PEARL
			for i: int in range(12):
				var spread: float = (_n(i, e["seed"]) - 0.5) * 1.6
				var reach: float = (18.0 + _n(i, e["seed"] + 1) * 52.0) * minf(1.0, t * 3.0)
				var p: Vector2 = c + dir.rotated(spread) * reach
				color = _dot(p, (3.0 + _n(i, e["seed"] + 2) * 5.0) * (1.0 - t * 0.6), Color(DuskStyle.LIFE if i % 3 else light, a))
			InkDraw.rough_circle(self, c, 10.0 + t * 26.0, Color(light, 0.7 * a), 3.0, e["seed"], 2.0)
		1:
			# A white star with a short glow.
			InkDraw.glow(self, c, 18.0 + t * 20.0, DuskStyle.SUN, a)
			for i: int in range(8):
				var ray: Vector2 = Vector2.from_angle(TAU * i / 8.0 + 0.2) * (12.0 + t * 40.0) * (1.4 if i % 2 == 0 else 0.8)
				color = _line(c + ray * 0.3, c + ray, Color(DuskStyle.PEARL, a), 3.0 if i % 2 == 0 else 1.6)
		_:
			# A small cross that opens up.
			var k: float = 8.0 + t * 14.0
			color = _line(c + Vector2(-k, -k), c + Vector2(k, k), Color(DuskStyle.PAPER_DAY, a), 2.0)
			_line(c + Vector2(-k, k), c + Vector2(k, -k), Color(DuskStyle.PAPER_DAY, a), 2.0)
	return {"color": color, "glow": record_glow}

## The downward attack's rebound: a ring at the feet and lift lines.
func _bounce(e: Dictionary, t: float, s: int) -> Dictionary:
	var c: Vector2 = e["at"] + Vector2(0, 48)
	var a: float = 1.0 - t
	var color: Color
	var tint: Color = [DuskStyle.PAPER_DAY, DuskStyle.POSSIBILITY_GLOW, DuskStyle.PAPER_DAY][s]
	color = _poly(_arc_points(c, 20.0 + t * 60.0, PI * 0.05, PI * 0.95, 14), Color(tint, a), [5.0, 4.0, 2.0][s])
	for i: int in range(3 if s < 2 else 2):
		var x: float = (i - 1) * 16.0
		_line(c + Vector2(x, -10 - t * 30.0), c + Vector2(x, -34 - t * 60.0), Color(tint, 0.8 * a), [3.0, 2.4, 1.4][s])
	return {"color": color}

## A projectile knocked back: a flash and an arrow along its new path.
func _reflect(e: Dictionary, t: float, s: int) -> Dictionary:
	var c: Vector2 = e["at"]
	var dir: Vector2 = e["dir"]
	var a: float = _fade(t)
	var tint: Color = [DuskStyle.GROWTH, DuskStyle.SUN, DuskStyle.GROWTH][s]
	if s == 1:
		InkDraw.glow(self, c, 26.0, DuskStyle.SUN, a)
	var color: Color = _poly(_arc_points(c, 22.0 + t * 18.0, dir.angle() - 1.2, dir.angle() + 1.2, 12), Color(tint, a), [4.0, 3.0, 1.6][s])
	_line(c, c + dir * (30.0 + t * 50.0), Color(tint, a), [3.0, 2.4, 1.4][s])
	return {"color": color}

## Dodging with enough possibility: after-images along the dash.
func _dodge(e: Dictionary, t: float, s: int) -> Dictionary:
	return _ghosts(e, t, s, false)

## Dodging into overdraft: the same, broken and vermilion.
func _poor_dodge(e: Dictionary, t: float, s: int) -> Dictionary:
	return _ghosts(e, t, s, true)

func _ghosts(e: Dictionary, t: float, s: int, poor: bool) -> Dictionary:
	var c: Vector2 = e["at"]
	var back: Vector2 = -(e["dir"] as Vector2)
	var a: float = 1.0 - t
	var tint: Color = DuskStyle.LIFE if poor else [DuskStyle.PAPER_DAY, DuskStyle.POSSIBILITY_GLOW, DuskStyle.PAPER_DAY][s]
	var color: Color = tint
	for k: int in range(3):
		var at: Vector2 = c + back * (24.0 + k * 26.0) * (0.5 + t)
		var alpha: float = a * (0.9 - k * 0.25)
		match s:
			0:
				# Ink smears: three horizontal strokes, ragged when poor.
				for j: int in range(3):
					var y: float = -30.0 + j * 30.0
					var length: float = 30.0 * (1.0 - k * 0.2) * (0.6 if poor and j == 1 else 1.0)
					color = _line(at + Vector2(-length * 0.5, y), at + Vector2(length * 0.5, y), Color(tint, alpha), 8.0 - k * 2.0)
			1:
				InkDraw.glow(self, at, 22.0, tint, alpha)
				color = _dot(at, 10.0 - k * 2.0, Color(tint, alpha))
			_:
				var rect: Rect2 = Rect2(at - Vector2(16, 46), Vector2(32, 92))
				draw_rect(rect, Color(tint, alpha), false, 1.5)
				color = Color(tint, alpha)
	if poor:
		# A crack mark at the start of the dash.
		_line(c + Vector2(-10, -10), c + Vector2(10, 10), Color(DuskStyle.LIFE, a), 3.0)
	return {"color": color, "poor": poor}

## Invulnerability around the player (a loop).
func _invuln(e: Dictionary, _t: float, s: int) -> Dictionary:
	var c: Vector2 = e["at"]
	var pulse: float = 0.5 + 0.5 * sin(clock * 14.0)
	var color: Color
	match s:
		0: color = _poly(InkDraw.circle_points(c, 54.0, int(clock * 10.0), 3.0, 36), Color(DuskStyle.PAPER_DAY, 0.25 + 0.25 * pulse), 2.4)
		1:
			InkDraw.glow(self, c, 40.0, DuskStyle.POSSIBILITY_GLOW, 0.4 + 0.4 * pulse)
			color = Color(DuskStyle.POSSIBILITY_GLOW, 0.4 + 0.4 * pulse)
		_:
			for i: int in range(12):
				if i % 2 == 0:
					color = _poly(_arc_points(c, 54.0, TAU * i / 12.0 + clock, TAU * (i + 1) / 12.0 + clock, 3), Color(DuskStyle.PAPER_DAY, 0.5), 1.4)
	return {"color": color}

## Possibility spent (dodge, heal): teal drops leaving the player.
func _spend(e: Dictionary, t: float, s: int) -> Dictionary:
	var c: Vector2 = e["at"]
	var a: float = 1.0 - t
	var color: Color = DuskStyle.POSSIBILITY
	for i: int in range(6 if s < 2 else 3):
		var angle: float = -PI * 0.5 + (_n(i, e["seed"]) - 0.5) * 2.2
		var p: Vector2 = c + Vector2.from_angle(angle) * (14.0 + t * 46.0) + Vector2(0, t * t * 40.0)
		match s:
			0: color = _dot(p, 4.0 * a + 1.0, Color(DuskStyle.POSSIBILITY, a))
			1:
				InkDraw.glow(self, p, 6.0, DuskStyle.POSSIBILITY_GLOW, a)
				color = _dot(p, 2.5, Color(DuskStyle.POSSIBILITY_GLOW, a))
			_: color = _dot(p, 2.0, Color(DuskStyle.POSSIBILITY, a))
	return {"color": color}

## Possibility gained at a defeated target (the HUD's flyer takes it on).
func _gain(e: Dictionary, t: float, s: int) -> Dictionary:
	var c: Vector2 = e["at"]
	var a: float = _fade(t)
	var color: Color = DuskStyle.POSSIBILITY_GLOW
	for i: int in range(5 if s < 2 else 3):
		var p: Vector2 = c + Vector2((_n(i, e["seed"]) - 0.5) * 50.0, -t * (40.0 + _n(i, e["seed"] + 3) * 40.0))
		if s == 1:
			InkDraw.glow(self, p, 8.0, DuskStyle.POSSIBILITY_GLOW, a)
		color = _dot(p, [4.0, 3.0, 2.0][s], Color(DuskStyle.POSSIBILITY_GLOW, a))
	return {"color": color}

## Healing in progress (a loop): motes circling inward.
func _heal_loop(e: Dictionary, _t: float, s: int) -> Dictionary:
	var c: Vector2 = e["at"]
	var color: Color = DuskStyle.POSSIBILITY_GLOW
	for i: int in range(6 if s < 2 else 4):
		var phase: float = fmod(clock * 0.9 + i / 6.0, 1.0)
		var p: Vector2 = c + Vector2.from_angle(TAU * i / 6.0 + clock * 2.0) * (60.0 * (1.0 - phase))
		match s:
			0: color = _dot(p, 3.0 + 3.0 * phase, Color(DuskStyle.PAPER_DAY, 0.8 * phase))
			1:
				InkDraw.glow(self, p, 8.0, DuskStyle.POSSIBILITY_GLOW, phase)
				color = _dot(p, 2.5, Color(DuskStyle.POSSIBILITY_GLOW, phase))
			_: color = _dot(p, 2.0, Color(DuskStyle.PAPER_DAY, phase))
	return {"color": color}

## Healing completed: a closing ring and a vermilion life mark.
func _heal_done(e: Dictionary, t: float, s: int) -> Dictionary:
	var c: Vector2 = e["at"]
	var a: float = 1.0 - t
	if s == 1:
		InkDraw.glow(self, c, 30.0 + t * 30.0, DuskStyle.LIFE, a)
	var color: Color = _poly(InkDraw.circle_points(c, 70.0 - t * 40.0, e["seed"], [2.5, 0.5, 0.0][s], 36), Color(DuskStyle.PAPER_DAY, a), [3.0, 2.0, 1.4][s])
	_dot(c, [8.0, 6.0, 4.0][s] * a, Color(DuskStyle.LIFE, a))
	return {"color": color}

## The player is hit.
func _hurt(e: Dictionary, t: float, s: int) -> Dictionary:
	var c: Vector2 = e["at"]
	var a: float = 1.0 - t
	var color: Color = DuskStyle.LIFE
	match s:
		0:
			for i: int in range(10):
				var p: Vector2 = c + Vector2.from_angle(TAU * _n(i, e["seed"])) * (16.0 + t * 50.0 * _n(i, e["seed"] + 1))
				color = _dot(p, 5.0 * a + 1.0, Color(DuskStyle.LIFE, a))
		1:
			InkDraw.glow(self, c, 40.0, DuskStyle.DENY, a)
			color = _poly(InkDraw.circle_points(c, 30.0 + t * 30.0, 0, 0.0, 32), Color(DuskStyle.DENY, a), 3.0)
		_:
			color = _poly(InkDraw.circle_points(c, 26.0 + t * 20.0, 0, 0.0, 24), Color(DuskStyle.LIFE, a), 2.0)
	return {"color": color}

## A target is hit (the target's own flash).
func _enemy_hurt(e: Dictionary, t: float, s: int) -> Dictionary:
	var c: Vector2 = e["at"]
	var a: float = 1.0 - t
	var color: Color = Color(DuskStyle.PAPER_DAY, a * [0.55, 0.7, 0.4][s])
	# A and B flash the body; C only outlines it.
	draw_rect(Rect2(c - Vector2(30, 40), Vector2(60, 80)), color, s != 2, 2.0 if s == 2 else -1.0)
	return {"color": color}

## A target is defeated.
func _enemy_death(e: Dictionary, t: float, s: int) -> Dictionary:
	var c: Vector2 = e["at"]
	var a: float = 1.0 - t
	var color: Color
	match s:
		0:
			# A burst of paper strokes, then drops that fall.
			for i: int in range(14):
				var dir: Vector2 = Vector2.from_angle(TAU * _n(i, e["seed"]))
				var p: Vector2 = c + dir * (20.0 + t * 90.0 * _n(i, e["seed"] + 1)) + Vector2(0, t * t * 120.0)
				color = _line(p, p + dir * 12.0 * a, Color(DuskStyle.PAPER_DAY if i % 4 else DuskStyle.LIFE, a), 4.0)
		1:
			InkDraw.glow(self, c, 50.0 * (1.0 - t * 0.5), DuskStyle.SUN, a)
			for i: int in range(10):
				var dir: Vector2 = Vector2.from_angle(TAU * i / 10.0 + _n(i, e["seed"]))
				var p: Vector2 = c + dir * (10.0 + t * 110.0)
				color = _poly(PackedVector2Array([p, p + dir.rotated(0.5) * 10.0, p + dir * 18.0]), Color(DuskStyle.PEARL, a), 2.0)
		_:
			var k: float = 34.0 * (1.0 - t)
			draw_rect(Rect2(c - Vector2(k, k), Vector2(k, k) * 2.0), Color(DuskStyle.PAPER_DAY, a), false, 1.6)
			color = Color(DuskStyle.PAPER_DAY, a)
	return {"color": color}

## Revival at a checkpoint.
func _revive(e: Dictionary, t: float, s: int) -> Dictionary:
	var c: Vector2 = e["at"] + Vector2(0, 48)
	var a: float = _fade(t)
	var color: Color
	match s:
		0:
			for i: int in range(5):
				var x: float = (i - 2) * 14.0
				color = _line(c + Vector2(x, 0), c + Vector2(x, -t * 140.0 * (0.6 + _n(i, e["seed"]) * 0.4)), Color(DuskStyle.PAPER_DAY, a * 0.8), 5.0)
		1:
			InkDraw.glow(self, c + Vector2(0, -60), 60.0, DuskStyle.SUN, a)
			color = _line(c, c + Vector2(0, -180.0 * t), Color(DuskStyle.PEARL, a), 6.0)
		_:
			color = _poly(InkDraw.circle_points(c + Vector2(0, -48), 20.0 + t * 60.0, 0, 0.0, 32), Color(DuskStyle.PAPER_DAY, a), 1.6)
	return {"color": color}
