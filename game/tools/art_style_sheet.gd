extends SceneTree
## ART-001: draws the style sheet the user signs the art style off against
## (`codexandclaude/tasks/ART-001/style_sheet.png`). A tool, not part of the
## game: run this script with the windowed Godot, `--path game -s` and its
## resource path (tools folder).
## Silhouettes only show line, colour, light and proportion; the real figures
## come from the generated art (ART-002 onward).

const OUT: String = "res://../codexandclaude/tasks/ART-001/style_sheet.png"
const OUT_CLOSE_UP: String = "res://../codexandclaude/tasks/ART-001/style_sheet_close_up.png"
const CLOSE_UP_ORIGIN: Vector2 = Vector2(240, 410)
const CLOSE_UP_SCALE: float = 3.0
const FLOOR: float = 640.0
const PLAYER_H: float = 112.0
## Rim light comes from the left (the low sun), shadows lean cool violet.
const SUN_SIDE: float = -1.0
var font: Font

class Sheet extends Node2D:
	var owner_tree: SceneTree
	func _draw() -> void:
		owner_tree.call("paint", self)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1920, 1080)
	font = load("res://assets/fonts/LXGWWenKai-Regular.ttf") as Font
	var sheet: Sheet = Sheet.new()
	sheet.owner_tree = self
	root.add_child(sheet)
	for i: int in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT)
	# Close-up of the player and the three ordinary enemies, so faces and
	# embedded objects can be judged at a readable size.
	sheet.scale = Vector2(CLOSE_UP_SCALE, CLOSE_UP_SCALE)
	sheet.position = -CLOSE_UP_ORIGIN * CLOSE_UP_SCALE
	sheet.queue_redraw()
	for i: int in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT_CLOSE_UP)
	quit()

func text(ci: CanvasItem, at: Vector2, s: String, size: int = 22, color: Color = DuskStyle.INK) -> void:
	ci.draw_string(font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func stroke(ci: CanvasItem, points: PackedVector2Array, color: Color, width: float, seed: int) -> void:
	for i: int in range(points.size() - 1):
		InkDraw.rough_line(ci, points[i], points[i + 1], color, width, seed + i, 1.2)

func blob(ci: CanvasItem, center: Vector2, radius: Vector2, color: Color, seed: int, wobble: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(40):
		var a: float = TAU * i / 40.0
		var r: float = 1.0 + (InkDraw.noise(i, seed) - 0.5) * wobble
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y) * r)
	ci.draw_colored_polygon(pts, color)
	return pts

func paint(ci: CanvasItem) -> void:
	ci.draw_rect(Rect2(0, 0, 1920, 1080), DuskStyle.PAPER_DAY)
	scene(ci)
	palette(ci, Vector2(1300, 40))
	regions(ci, Vector2(1300, 470))
	scale_ruler(ci, Vector2(40, 770))
	rules(ci, Vector2(760, 760))

# --- the sample scene: wasteland at dusk -----------------------------------

func scene(ci: CanvasItem) -> void:
	var box: Rect2 = Rect2(20, 20, 1260, 700)
	InkDraw.wash(ci, Rect2(box.position, Vector2(box.size.x, 460)), DuskStyle.DUSK_TOP, DuskStyle.DUSK_BOTTOM)
	ci.draw_rect(Rect2(box.position + Vector2(0, 460), Vector2(box.size.x, 240)), DuskStyle.PAPER_DUSK)
	InkDraw.glow(ci, Vector2(220, 380), 90.0, DuskStyle.SUN, 0.9)
	# Far: pale violet ruins, low contrast.
	var far: Color = Color(DuskStyle.DUSK_TOP.lerp(DuskStyle.PAPER_DUSK, 0.55), 0.85)
	for i: int in range(9):
		var x: float = 40 + i * 140 + InkDraw.noise(i, 3) * 40
		var h: float = 90 + InkDraw.noise(i, 4) * 120
		var w: float = 50 + InkDraw.noise(i, 5) * 60
		var ruin: PackedVector2Array = PackedVector2Array([Vector2(x, 480), Vector2(x, 480 - h * 0.8), Vector2(x + w * 0.3, 480 - h), Vector2(x + w * 0.55, 480 - h * 0.86), Vector2(x + w * 0.7, 480 - h * 0.95), Vector2(x + w, 480 - h * 0.6), Vector2(x + w, 480)])
		ci.draw_colored_polygon(ruin, far)
	# Mid: grey-brown rubble.
	var mid: Color = Color("8a7566")
	var ridge: PackedVector2Array = PackedVector2Array([Vector2(20, 600)])
	for i: int in range(26):
		ridge.append(Vector2(20 + i * 50, 520 - InkDraw.noise(i, 9) * 50))
	ridge.append(Vector2(1280, 600))
	ci.draw_colored_polygon(ridge, mid.lerp(DuskStyle.PAPER_DUSK, 0.35))
	# Near: 64 px ground tiles, ink top edge, paper fill (tiles are code-drawn).
	for i: int in range(20):
		var tile: Rect2 = Rect2(20 + i * 64, FLOOR, 64, 64)
		ci.draw_rect(tile, Color("c9ad92"))
		InkDraw.rough_line(ci, tile.position, tile.position + Vector2(64, 0), DuskStyle.INK, 3.0, i, 1.0)
		if i % 3 == 0:
			InkDraw.rough_line(ci, tile.position + Vector2(10, 22), tile.position + Vector2(40, 30), Color(DuskStyle.INK, 0.35), 1.5, i + 50, 1.0)
	ci.draw_rect(Rect2(20, FLOOR + 64, 1260, 16), Color("b2957c"))
	player(ci, Vector2(300, FLOOR))
	colorless(ci, Vector2(500, FLOOR))
	monochrome(ci, Vector2(650, FLOOR))
	tian(ci, Vector2(800, FLOOR))
	overlook(ci, Vector2(960, 270))
	parasite(ci, Vector2(1200, FLOOR))
	InkDraw.rough_rect(ci, box, DuskStyle.INK, 2.5, 7, 1.0)
	text(ci, Vector2(36, 54), "样张：荒地 · 黄昏（人是暖的，有暖色边光；敌人依稀人形、扭曲、嵌入异物、不受暖光）", 22, DuskStyle.PEARL)
	for pair: Array in [[300, "玩家"], [500, "无色实体"], [650, "单色实体"], [800, "天人战士"], [960, "渴望俯视"], [1160, "寄生同伴者"]]:
		text(ci, Vector2(float(pair[0]) - 30, FLOOR + 46), String(pair[1]), 20)

## A human figure in ink: head, torso, limbs; paper fill. Only people get the
## warm rim on the sun side and the cool violet shade; enemies take no warm light.
func figure(ci: CanvasItem, feet: Vector2, h: float, fill: Color, seed: int, rim: bool = true) -> Dictionary:
	var k: float = h / PLAYER_H
	var head: Vector2 = feet + Vector2(0, -100) * k
	var neck: Vector2 = feet + Vector2(0, -86) * k
	var hip: Vector2 = feet + Vector2(0, -48) * k
	var body: PackedVector2Array = PackedVector2Array([neck + Vector2(-13, 0) * k, neck + Vector2(13, 0) * k, hip + Vector2(11, 0) * k, hip + Vector2(-11, 0) * k])
	ci.draw_colored_polygon(body, fill)
	for leg: float in [-1.0, 1.0]:
		stroke(ci, PackedVector2Array([hip + Vector2(6 * leg, 0) * k, feet + Vector2(9 * leg, -22) * k, feet + Vector2(12 * leg, 0) * k]), DuskStyle.INK, 7.0 * k, seed + int(leg * 3))
	for arm: float in [-1.0, 1.0]:
		stroke(ci, PackedVector2Array([neck + Vector2(12 * arm, 4) * k, neck + Vector2(18 * arm, 24) * k, neck + Vector2(16 * arm, 42) * k]), DuskStyle.INK, 6.0 * k, seed + 10 + int(arm * 3))
	stroke(ci, body + PackedVector2Array([body[0]]), DuskStyle.INK, 3.0, seed + 20)
	InkDraw.paper_disc(ci, head, 11.0 * k, fill, seed + 30)
	InkDraw.rough_circle(ci, head, 11.0 * k, DuskStyle.INK, 3.0, seed + 31)
	if rim:
		InkDraw.rough_line(ci, neck + Vector2(13 * SUN_SIDE, 2) * k, hip + Vector2(11 * SUN_SIDE, -2) * k, DuskStyle.SUN, 2.5, seed + 40)
		InkDraw.rough_line(ci, neck + Vector2(-11 * SUN_SIDE, 6) * k, hip + Vector2(-9 * SUN_SIDE, -4) * k, Color(DuskStyle.DUSK_TOP, 0.55), 4.0, seed + 41)
	return {"head": head, "neck": neck, "hip": hip, "k": k}

func player(ci: CanvasItem, feet: Vector2) -> void:
	var f: Dictionary = figure(ci, feet, PLAYER_H, DuskStyle.PAPER_DAY, 100)
	var k: float = f["k"]
	# A scarf tail and the starter blade: the player's two marks.
	stroke(ci, PackedVector2Array([f["neck"] + Vector2(-6, 2), f["neck"] + Vector2(-26, 8), f["neck"] + Vector2(-40, 4)]), DuskStyle.LIFE, 5.0, 110)
	stroke(ci, PackedVector2Array([f["neck"] + Vector2(16, 42) * k, f["neck"] + Vector2(54, 10) * k]), DuskStyle.INK, 4.0, 120)
	InkDraw.rough_line(ci, f["neck"] + Vector2(20, 38) * k, f["neck"] + Vector2(52, 12) * k, DuskStyle.PEARL, 1.5, 121)

## A point given in player units from the feet (enemies face left, toward the player).
func pt(feet: Vector2, k: float, x: float, y: float) -> Vector2:
	return feet + Vector2(x, y) * k

## Colourless: a faceless human with no colour of its own. Blank paper face,
## over-long clawed arms, one knee bent backwards, melting legs, a stopped
## clock grown into its chest.
func colorless(ci: CanvasItem, feet: Vector2) -> void:
	var k: float = 0.8
	var ink: Color = Color(DuskStyle.INK, 0.94)
	var torso: PackedVector2Array = PackedVector2Array([pt(feet, k, -16, -88), pt(feet, k, 10, -90), pt(feet, k, 12, -48), pt(feet, k, -8, -44)])
	ci.draw_colored_polygon(torso, ink)
	stroke(ci, torso + PackedVector2Array([torso[0]]), DuskStyle.INK, 2.0, 201)
	# Legs: the near knee bends the wrong way; both melt into drips.
	stroke(ci, PackedVector2Array([pt(feet, k, -4, -46), pt(feet, k, -14, -24), pt(feet, k, -8, 0)]), ink, 7.0 * k, 202)
	stroke(ci, PackedVector2Array([pt(feet, k, 6, -46), pt(feet, k, 18, -22), pt(feet, k, 6, 0)]), ink, 7.0 * k, 203)
	for i: int in range(5):
		var x: float = feet.x + (i - 2) * 7.0
		InkDraw.rough_line(ci, Vector2(x, feet.y - 6), Vector2(x + 1, feet.y + 6 + i * 2), Color(DuskStyle.INK, 0.7), 2.5, 210 + i)
	# Arms: too long, hanging past the knees, ending in claws.
	for arm: Array in [[-1.0, 220], [1.0, 230]]:
		var s: float = arm[0]
		var hand: Vector2 = pt(feet, k, -30 + 8 * s, -8)
		stroke(ci, PackedVector2Array([pt(feet, k, -4 + 10 * s, -84), pt(feet, k, -24 + 8 * s, -56), hand]), ink, 4.5 * k, arm[1])
		for c: int in range(3):
			InkDraw.rough_line(ci, hand, hand + Vector2(-6 - c * 2, 4 + c * 3), DuskStyle.INK, 1.8, int(arm[1]) + 5 + c)
	# Head tilted forward; the face is a blank of paper, no features at all.
	var head: Vector2 = pt(feet, k, -10, -102)
	blob(ci, head, Vector2(10, 13) * k, ink, 240, 0.12)
	blob(ci, head + Vector2(-4, 1) * k, Vector2(6, 10) * k, DuskStyle.PAPER_DAY, 241, 0.08)
	# The stopped clock, grown into the chest.
	var clock: Vector2 = pt(feet, k, 0, -72)
	InkDraw.paper_disc(ci, clock, 7.0 * k, DuskStyle.PEARL, 250)
	InkDraw.rough_circle(ci, clock, 7.0 * k, DuskStyle.INK, 2.0, 251)
	InkDraw.rough_line(ci, clock, clock + Vector2(0, -5) * k, DuskStyle.INK, 1.5, 252)
	InkDraw.rough_line(ci, clock, clock + Vector2(-4, 2) * k, DuskStyle.INK, 1.5, 253)

## Single-colour: a stretched human. Limbs and neck too long with an extra
## joint each, hunched; rebar pierces out of its back like extra legs; one
## violet slit across the face, the only colour it has.
func monochrome(ci: CanvasItem, feet: Vector2) -> void:
	var k: float = 0.8
	var ink: Color = Color(DuskStyle.INK, 0.92)
	var violet: Color = DuskStyle.DUSK_TOP
	var torso: PackedVector2Array = PackedVector2Array([pt(feet, k, 2, -62), pt(feet, k, 14, -64), pt(feet, k, 4, -100), pt(feet, k, -10, -96)])
	ci.draw_colored_polygon(torso, ink)
	stroke(ci, torso + PackedVector2Array([torso[0]]), violet, 2.5, 300)
	# Legs and arms with one joint too many.
	for leg: Array in [[0.0, 301], [10.0, 302]]:
		var x: float = leg[0]
		stroke(ci, PackedVector2Array([pt(feet, k, 6 + x, -62), pt(feet, k, 22 + x, -46), pt(feet, k, 4 + x, -26), pt(feet, k, 14 + x, 0)]), ink, 4.0 * k, leg[1])
	for arm: Array in [[0.0, 305], [8.0, 306]]:
		var x: float = arm[0]
		stroke(ci, PackedVector2Array([pt(feet, k, -6 + x, -96), pt(feet, k, -22 + x, -76), pt(feet, k, -14 + x, -48), pt(feet, k, -36 + x, -22), pt(feet, k, -42 + x, -4)]), ink, 3.5 * k, arm[1])
	# A long neck bent forward, a small head, a violet slit for a smile.
	var head: Vector2 = pt(feet, k, -30, -108)
	stroke(ci, PackedVector2Array([pt(feet, k, -4, -98), pt(feet, k, -16, -112), head + Vector2(6, 2) * k]), ink, 4.0 * k, 310)
	blob(ci, head, Vector2(9, 7) * k, ink, 311, 0.1)
	InkDraw.rough_line(ci, head + Vector2(-9, 1) * k, head + Vector2(8, 3) * k, violet.lightened(0.25), 2.5, 312)
	# Rebar out of the back.
	for i: int in range(3):
		var root_at: Vector2 = pt(feet, k, 6 + i * 3, -92 + i * 10)
		InkDraw.rough_line(ci, root_at, root_at + Vector2(28 + i * 6, -30 + i * 14) * k, Color("4a403a"), 2.5, 320 + i, 0.3)
	# Dash streaks behind it stay violet (FX-002).
	for i: int in range(3):
		InkDraw.rough_line(ci, pt(feet, k, 30 + i * 6, -30 - i * 16), pt(feet, k, 66 + i * 12, -30 - i * 16), Color(violet, 0.6), 2.0, 330 + i)

## Tian warrior: ornate armour that is empty inside. A gold mask with a calm,
## fixed smile on a tilted head, ink leaking from the joints, a halo of broken
## blades grown into its back.
func tian(ci: CanvasItem, feet: Vector2) -> void:
	var k: float = 0.8
	# The halo sits behind the body, so it is drawn first.
	var halo: Vector2 = pt(feet, k, 4, -90)
	for i: int in range(7):
		var a: float = -PI * 0.1 - PI * 0.8 * i / 6.0
		var dir: Vector2 = Vector2(cos(a), sin(a))
		InkDraw.rough_line(ci, halo + dir * 16 * k, halo + dir * 34 * k, DuskStyle.GROWTH, 3.0, 405 + i, 0.3)
	var f: Dictionary = figure(ci, feet, PLAYER_H * k, Color("3a302a"), 400, false)
	var head: Vector2 = f["head"]
	# Gold mask, tilted, with a fixed smile and two slit eyes.
	var tilt: float = -0.35
	InkDraw.paper_disc(ci, head, 11.0 * k, DuskStyle.GROWTH, 412)
	InkDraw.rough_circle(ci, head, 11.0 * k, DuskStyle.INK, 2.0, 413)
	for e: float in [-1.0, 1.0]:
		var eye: Vector2 = head + Vector2(e * 4.5 - 1, -2.5).rotated(tilt) * k
		InkDraw.rough_line(ci, eye - Vector2(2, 0) * k, eye + Vector2(2, 0) * k, DuskStyle.INK, 1.5, 414 + int(e))
	var smile: PackedVector2Array = PackedVector2Array()
	for i: int in range(7):
		var t: float = -1.0 + 2.0 * i / 6.0
		smile.append(head + Vector2(t * 5 - 1, 3.0 + 2.0 * (1.0 - t * t)).rotated(tilt) * k)
	for i: int in range(smile.size() - 1):
		InkDraw.rough_line(ci, smile[i], smile[i + 1], DuskStyle.INK, 1.5, 416 + i, 0.15)
	# Ink leaking from the hip and shoulder joints.
	var joints: Array = [f["hip"] + Vector2(-9, 0) * k, f["hip"] + Vector2(9, 0) * k, f["neck"] + Vector2(-14, 6) * k]
	for i: int in range(joints.size()):
		var j: Vector2 = joints[i]
		InkDraw.rough_line(ci, j, j + Vector2(1, 10 + i * 3) * k, Color(DuskStyle.INK, 0.8), 2.5, 420 + i)
	# The long blade.
	stroke(ci, PackedVector2Array([f["neck"] + Vector2(-16, 42) * k, f["neck"] + Vector2(-30, -40) * k]), DuskStyle.INK, 4.0, 430)
	InkDraw.rough_line(ci, f["neck"] + Vector2(-28, -30) * k, f["neck"] + Vector2(-31, -44) * k, DuskStyle.GROWTH, 4.0, 431)

## Overlook (Boss, 250%): a hovering mass with one eye that has human lids and
## lashes, vermilion iris on the player; small eyes scattered over the mass;
## the eye sits in a broken window frame; ink threads hang it from above.
func overlook(ci: CanvasItem, c: Vector2) -> void:
	var w: float = PLAYER_H * 2.5 * 0.5
	for i: int in range(5):
		var x: float = c.x - w * 0.7 + i * w * 0.35
		InkDraw.rough_line(ci, Vector2(x + 10 * InkDraw.noise(i, 6), 22), Vector2(x, c.y - w * 0.4), Color(DuskStyle.INK, 0.55), 2.0, 505 + i)
	var pts: PackedVector2Array = blob(ci, c, Vector2(w, w * 0.6), Color(DuskStyle.INK, 0.94), 500, 0.12)
	stroke(ci, pts + PackedVector2Array([pts[0]]), DuskStyle.INK, 3.0, 501)
	# Broken window frame the eye is grown into.
	var frame: Rect2 = Rect2(c - Vector2(w * 0.74, w * 0.4), Vector2(w * 1.48, w * 0.8))
	var wood: Color = Color("6a5a4c")
	InkDraw.rough_line(ci, frame.position, frame.position + Vector2(frame.size.x * 0.7, 0), wood, 5.0, 520)
	InkDraw.rough_line(ci, frame.position, frame.position + Vector2(0, frame.size.y), wood, 5.0, 521)
	InkDraw.rough_line(ci, frame.end, frame.end - Vector2(frame.size.x, 0), wood, 5.0, 522)
	InkDraw.rough_line(ci, frame.end, frame.end - Vector2(0, frame.size.y * 0.55), wood, 5.0, 523)
	InkDraw.rough_line(ci, frame.position + Vector2(frame.size.x * 0.5, 0), frame.position + Vector2(frame.size.x * 0.5, frame.size.y * 0.25), wood, 4.0, 524)
	# The eye: human lids, a crease and lashes.
	var upper: PackedVector2Array = PackedVector2Array()
	for i: int in range(17):
		var a: float = PI + PI * i / 16.0
		upper.append(c + Vector2(cos(a) * w * 0.6, sin(a) * w * 0.28))
	var lid: PackedVector2Array = upper.duplicate()
	for i: int in range(17):
		var a: float = PI * i / 16.0
		lid.append(c + Vector2(cos(a) * w * 0.6, sin(a) * w * 0.2))
	ci.draw_colored_polygon(lid, DuskStyle.PAPER_DAY)
	ci.draw_circle(c + Vector2(-14, 6), w * 0.16, DuskStyle.LIFE)
	ci.draw_circle(c + Vector2(-16, 8), w * 0.07, DuskStyle.INK)
	stroke(ci, upper, DuskStyle.INK, 3.5, 530)
	var crease: PackedVector2Array = PackedVector2Array()
	for i: int in range(13):
		var a: float = PI + PI * (2 + i) / 16.0
		crease.append(c + Vector2(cos(a) * w * 0.56, sin(a) * w * 0.38))
	stroke(ci, crease, Color(DuskStyle.PAPER_DAY, 0.5), 2.0, 531)
	for i: int in range(2, 15):
		var p: Vector2 = upper[i]
		InkDraw.rough_line(ci, p, p + (p - c).normalized() * 12, DuskStyle.INK, 2.0, 540 + i)
	# Small eyes scattered over the mass.
	for e: Vector2 in [Vector2(-0.86, -0.1), Vector2(0.82, 0.15), Vector2(0.3, 0.46), Vector2(-0.45, 0.44)]:
		var p: Vector2 = c + Vector2(e.x * w, e.y * w * 0.6)
		blob(ci, p, Vector2(8, 4), DuskStyle.PAPER_DAY, 550 + int(e.x * 10), 0.05)
		ci.draw_circle(p + Vector2(-2, 0), 2.5, DuskStyle.LIFE)
	for i: int in range(5):
		var x: float = c.x - w * 0.6 + i * w * 0.3
		InkDraw.rough_line(ci, Vector2(x, c.y + w * 0.52), Vector2(x + 4, c.y + w * 0.52 + 30 + 20 * InkDraw.noise(i, 5)), Color(DuskStyle.INK, 0.8), 4.0, 510 + i)

## Parasite companion (Boss, 250%): looks like a survivor with a pack until the
## face splits open top to bottom into a mouth; tentacles come out of the mouth
## and out of the pack, which has grown into its back.
func parasite(ci: CanvasItem, feet: Vector2) -> void:
	var red: Color = Color("6e1f3a")
	var k: float = 2.5
	var neck: Vector2 = pt(feet, k, 0, -86)
	var pack: Rect2 = Rect2(neck + Vector2(8, 2) * k, Vector2(14, 30) * k)
	# Tentacles out of the pack sit behind it.
	for i: int in range(2):
		var start: Vector2 = pack.position + Vector2(10, 2 + i * 10) * k
		stroke(ci, PackedVector2Array([start, start + Vector2(30, -26 - i * 10), start + Vector2(16, -60 - i * 6), start + Vector2(30, -84)]), red, 4.0, 650 + i * 4)
	InkDraw.paper(ci, pack, Color("6e5e50"), 610)
	InkDraw.rough_rect(ci, pack, DuskStyle.INK, 2.5, 611)
	var f: Dictionary = figure(ci, feet, PLAYER_H * k, Color("8a7a6a"), 600, false)
	# Flesh growing over the strap where the pack meets the back.
	InkDraw.rough_line(ci, pack.position + Vector2(0, 4) * k, pack.position + Vector2(0, 26) * k, red, 6.0, 612)
	# The face split top to bottom.
	var head: Vector2 = f["head"]
	var mouth: PackedVector2Array = PackedVector2Array([head + Vector2(-2, -10) * k, head + Vector2(-7, 0) * k, head + Vector2(-2, 11) * k, head + Vector2(3, 0) * k])
	ci.draw_colored_polygon(mouth, red)
	stroke(ci, mouth + PackedVector2Array([mouth[0]]), DuskStyle.INK, 2.0, 615)
	for i: int in range(4):
		var y: float = -6 + i * 4
		InkDraw.rough_line(ci, head + Vector2(-5, y) * k, head + Vector2(-2, y + 1) * k, DuskStyle.PEARL, 1.5, 620 + i)
	# Tentacles from the mouth reach toward the player.
	for i: int in range(3):
		var start: Vector2 = head + Vector2(-5, -2 + i * 4) * k
		var reach: PackedVector2Array = PackedVector2Array([start, start + Vector2(-30, -10 + i * 14), start + Vector2(-58, 6 + i * 10), start + Vector2(-76, -6 + i * 18)])
		stroke(ci, reach, red, 4.5 - i * 0.6, 630 + i * 4)

# --- the side panels ---------------------------------------------------------

func palette(ci: CanvasItem, at: Vector2) -> void:
	text(ci, at + Vector2(0, 22), "色板（与 DuskStyle 一致）", 24)
	var colors: Array = [["墨 INK", DuskStyle.INK, "轮廓、暗部"], ["珍珠白", DuskStyle.PEARL, "高光"], ["白日纸色", DuskStyle.PAPER_DAY, "田野底色"],
		["黄昏纸色", DuskStyle.PAPER_DUSK, "荒地底色"], ["黄昏顶", DuskStyle.DUSK_TOP, "天空上部、冷暗部、单色实体"], ["黄昏底", DuskStyle.DUSK_BOTTOM, "天空下部"],
		["日光", DuskStyle.SUN, "边光"], ["生命红", DuskStyle.LIFE, "生命，角色上慎用"], ["可能性青", DuskStyle.POSSIBILITY, "只给可能性"], ["成长金", DuskStyle.GROWTH, "成长、天人装饰"]]
	for i: int in range(colors.size()):
		var row: Vector2 = at + Vector2((i % 2) * 300, 44 + (i / 2) * 72)
		InkDraw.paper(ci, Rect2(row, Vector2(56, 52)), colors[i][1], 600 + i)
		InkDraw.rough_rect(ci, Rect2(row, Vector2(56, 52)), DuskStyle.INK, 1.5, 620 + i)
		text(ci, row + Vector2(66, 22), "%s  #%s" % [colors[i][0], (colors[i][1] as Color).to_html(false)], 18)
		text(ci, row + Vector2(66, 46), String(colors[i][2]), 16, Color(DuskStyle.INK, 0.7))

func regions(ci: CanvasItem, at: Vector2) -> void:
	text(ci, at + Vector2(0, 22), "三个区域主色调", 24)
	var bands: Array = [["荒地 HD", DuskStyle.DUSK_TOP, DuskStyle.DUSK_BOTTOM, DuskStyle.PAPER_DUSK, Color("8a7566")],
		["田野 TY", Color("9fc0d8"), DuskStyle.PAPER_DAY, DuskStyle.PAPER_DAY, Color("d8b25a")],
		["逆时战场 NSZC", Color("5a3a3a"), Color("c0703a"), Color("9a7e6e"), Color("6e5e58")]]
	for i: int in range(bands.size()):
		var r: Rect2 = Rect2(at + Vector2(0, 44 + i * 74), Vector2(580, 62))
		InkDraw.wash(ci, Rect2(r.position, Vector2(r.size.x, 36)), bands[i][1], bands[i][2])
		ci.draw_rect(Rect2(r.position + Vector2(0, 36), Vector2(r.size.x, 26)), bands[i][3])
		for j: int in range(7):
			ci.draw_rect(Rect2(r.position + Vector2(40 + j * 76, 22 - InkDraw.noise(j, i) * 14), Vector2(30, 14 + InkDraw.noise(j, i) * 14)), Color(bands[i][4], 0.8))
		InkDraw.rough_rect(ci, r, DuskStyle.INK, 1.5, 700 + i)
		text(ci, r.position + Vector2(8, 58), String(bands[i][0]), 18, DuskStyle.INK)

## Display heights (T6-E): player 112 px; ordinary NPC and enemy 80 %%; key NPC and elite 200 %%; Boss 250 %%.
func scale_ruler(ci: CanvasItem, at: Vector2) -> void:
	text(ci, at + Vector2(0, 0), "比例（1080p 显示高度，T6-E；图中按 75% 画）", 24)
	var base: float = at.y + 262
	var shrink: float = 0.75
	var rows: Array = [["玩家", 1.0], ["普通敌人 / NPC", 0.8], ["7、10 / 精英", 2.0], ["Boss", 2.5]]
	for i: int in range(rows.size()):
		var h: float = PLAYER_H * float(rows[i][1]) * shrink
		var x: float = at.x + 20 + i * 170
		ci.draw_rect(Rect2(x, base - h, 40, h), Color(DuskStyle.INK, 0.75))
		text(ci, Vector2(x - 10, base + 26), String(rows[i][0]), 16)
		text(ci, Vector2(x - 6, base - h - 8), "%d px" % int(round(h / shrink)), 16)
	InkDraw.rough_line(ci, Vector2(at.x, base), Vector2(at.x + 680, base), DuskStyle.INK, 2.0, 800)

func rules(ci: CanvasItem, at: Vector2) -> void:
	text(ci, at, "要点", 24)
	var lines: Array[String] = [
		"线条：深墨轮廓，略带手绘抖动与粗细变化，不用干净矢量线。",
		"上色：平涂为主，少量水墨晕染与纸纹；不厚涂，不写实光影。",
		"光：黄昏暖光从一侧（左）打来；人有暖色边光、暗部偏冷紫，敌人不受暖光。",
		"明度：角色深、背景远景浅而淡；生命红与可能性青不做大面积底色。",
		"敌人：依稀人形，肢体器官扭曲、嵌入异物，恐怖谷，动作抽帧；惊悚不血腥。",
		"　无色＝无脸＋胸口停钟；单色＝过长多节＋背上钢筋＋紫缝；天人＝金色笑面＋刃环；",
		"　渴望俯视＝人眼皮巨眼嵌在窗框里；寄生同伴者＝像幸存者，脸裂成口器、背包触须。",
		"特效沿用 FX-001 / FX-002，不重做；读招提示照常清楚。",
	]
	for i: int in range(lines.size()):
		text(ci, at + Vector2(0, 40 + i * 33), lines[i], 19)
