class_name InkDraw
extends RefCounted
## Hand-drawn primitives for the formal UI (EXP-002 sample two). Jitter is
## deterministic per stroke seed, so strokes look inked but never shimmer.

static func noise(i: int, seed: int) -> float:
	var x: float = sin(float(i) * 12.9898 + float(seed) * 78.233) * 43758.5453
	return x - floor(x)

static func rough_line(ci: CanvasItem, a: Vector2, b: Vector2, color: Color, width: float, seed: int, wobble: float = 0.7) -> void:
	var steps: int = maxi(2, int(a.distance_to(b) / 16.0))
	var normal: Vector2 = (b - a).orthogonal().normalized()
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(steps + 1):
		points.append(a.lerp(b, float(i) / steps) + normal * (noise(i, seed) - 0.5) * 2.0 * wobble)
	ci.draw_polyline(points, color, width, true)

## Four strokes that overshoot the corners slightly, like a quick pen outline.
static func rough_rect(ci: CanvasItem, rect: Rect2, color: Color, width: float, seed: int, wobble: float = 0.7) -> void:
	var o: float = wobble * 2.0
	var tl: Vector2 = rect.position
	var tr: Vector2 = Vector2(rect.end.x, rect.position.y)
	var br: Vector2 = rect.end
	var bl: Vector2 = Vector2(rect.position.x, rect.end.y)
	rough_line(ci, tl + Vector2(-o, 0), tr + Vector2(o, 0), color, width, seed, wobble)
	rough_line(ci, tr + Vector2(0, -o), br + Vector2(0, o), color, width, seed + 1, wobble)
	rough_line(ci, br + Vector2(o, 0), bl + Vector2(-o, 0), color, width, seed + 2, wobble)
	rough_line(ci, bl + Vector2(0, o), tl + Vector2(0, -o), color, width, seed + 3, wobble)

static func circle_points(center: Vector2, radius: float, seed: int, wobble: float, count: int = 48) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(count + 1):
		var angle: float = TAU * float(i) / count
		points.append(center + Vector2.from_angle(angle) * (radius + (noise(i, seed) - 0.5) * 2.0 * wobble))
	return points

static func rough_circle(ci: CanvasItem, center: Vector2, radius: float, color: Color, width: float, seed: int, wobble: float = 0.7) -> void:
	ci.draw_polyline(circle_points(center, radius, seed, wobble), color, width, true)

static func paper_disc(ci: CanvasItem, center: Vector2, radius: float, color: Color, seed: int, wobble: float = 0.7) -> void:
	var points: PackedVector2Array = circle_points(center, radius, seed, wobble)
	points.remove_at(points.size() - 1)
	ci.draw_colored_polygon(points, color)

## Paper sheet with a slightly irregular edge and faint fibres.
static func paper(ci: CanvasItem, rect: Rect2, color: Color, seed: int, wobble: float = 0.7, fibres: int = 8) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var corners: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for side: int in range(4):
		var a: Vector2 = corners[side]
		var b: Vector2 = corners[(side + 1) % 4]
		var normal: Vector2 = (b - a).orthogonal().normalized()
		var steps: int = maxi(2, int(a.distance_to(b) / 22.0))
		for i: int in range(steps):
			points.append(a.lerp(b, float(i) / steps) + normal * (noise(i + side * 97, seed) - 0.5) * 2.0 * wobble)
	ci.draw_colored_polygon(points, color)
	var fibre: Color = Color(0.35, 0.25, 0.15, 0.07 * color.a)
	for i: int in range(fibres):
		var start: Vector2 = rect.position + Vector2(noise(i, seed + 11) * rect.size.x, noise(i, seed + 13) * rect.size.y)
		var direction: Vector2 = Vector2.from_angle(noise(i, seed + 17) * TAU) * (6.0 + noise(i, seed + 19) * 14.0)
		ci.draw_line(start, (start + direction).clamp(rect.position, rect.end), fibre, 1.0)

## Many faint layers instead of a few strong ones, so large glows do not band.
static func glow(ci: CanvasItem, center: Vector2, radius: float, color: Color, strength: float) -> void:
	for k: int in range(16):
		ci.draw_circle(center, radius * (1.0 + k * 0.13), Color(color, color.a * strength * 0.06 * (1.0 - k / 16.0)))

static func wash(ci: CanvasItem, rect: Rect2, top: Color, bottom: Color) -> void:
	ci.draw_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))
