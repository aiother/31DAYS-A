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
	overlook(ci, Vector2(880, 300))
	overlook_faces(ci, Vector2(420, 80))
	parasite(ci, Vector2(1180, FLOOR))
	InkDraw.rough_rect(ci, box, DuskStyle.INK, 2.5, 7, 1.0)
	text(ci, Vector2(36, 54), "样张：荒地 · 黄昏（人是暖的，有暖色边光；敌人依稀人形、扭曲、嵌入异物、不受暖光）", 22, DuskStyle.PEARL)
	for pair: Array in [[300, "玩家"], [500, "无色实体"], [650, "单色实体"], [800, "天人战士"], [930, "渴望俯视"], [1150, "寄生同伴者"]]:
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

## Colourless: human parts in an order no human uses. Upside down, it walks
## on its clawed hands, legs up in the air, the faceless head hanging under
## the chest. What it carries and what is grown into it vary per individual
## (here an umbrella hooked on a raised foot and a stopped clock in the chest).
func colorless(ci: CanvasItem, feet: Vector2) -> void:
	var k: float = 0.8
	var ink: Color = Color(DuskStyle.INK, 0.94)
	# Legs up in the air, one bent back down; drawn first, behind the torso.
	stroke(ci, PackedVector2Array([pt(feet, k, -6, -78), pt(feet, k, -20, -96), pt(feet, k, -12, -114)]), ink, 7.0 * k, 202)
	stroke(ci, PackedVector2Array([pt(feet, k, 8, -78), pt(feet, k, 26, -92), pt(feet, k, 34, -76)]), ink, 7.0 * k, 203)
	# An umbrella hooked on the raised foot.
	var tip: Vector2 = pt(feet, k, -30, -140)
	InkDraw.rough_line(ci, pt(feet, k, -12, -114), tip, Color("4a403a"), 2.0, 204, 0.3)
	var canopy: PackedVector2Array = PackedVector2Array()
	for i: int in range(13):
		var a: float = PI + PI * i / 12.0
		canopy.append(tip + Vector2(cos(a) * 22, sin(a) * 11 + 6) * k)
	ci.draw_colored_polygon(canopy, Color("5a4e46"))
	stroke(ci, canopy + PackedVector2Array([canopy[0]]), DuskStyle.INK, 2.0, 205)
	# Torso upside down: shoulders at the bottom, hips at the top.
	var torso: PackedVector2Array = PackedVector2Array([pt(feet, k, -14, -40), pt(feet, k, 12, -42), pt(feet, k, 10, -80), pt(feet, k, -8, -78)])
	ci.draw_colored_polygon(torso, ink)
	stroke(ci, torso + PackedVector2Array([torso[0]]), DuskStyle.INK, 2.0, 201)
	# Arms as legs, the near elbow bent the wrong way, claws splayed on the ground.
	for arm: Array in [[[-12, -42], [-24, -22], [-16, 0], 220], [[10, -42], [22, -24], [14, 0], 230]]:
		var hand: Vector2 = pt(feet, k, arm[2][0], arm[2][1])
		stroke(ci, PackedVector2Array([pt(feet, k, arm[0][0], arm[0][1]), pt(feet, k, arm[1][0], arm[1][1]), hand]), ink, 5.0 * k, arm[3])
		for c: int in range(3):
			InkDraw.rough_line(ci, hand, hand + Vector2(-8 + c * 5, 2), DuskStyle.INK, 1.8, int(arm[3]) + 5 + c)
	# The faceless head hangs under the chest, blank paper turned down and forward.
	stroke(ci, PackedVector2Array([pt(feet, k, 0, -40), pt(feet, k, -2, -30)]), ink, 5.0 * k, 239)
	var head: Vector2 = pt(feet, k, -3, -22)
	blob(ci, head, Vector2(10, 12) * k, ink, 240, 0.12)
	blob(ci, head + Vector2(-4, 3) * k, Vector2(6, 8) * k, DuskStyle.PAPER_DAY, 241, 0.08)
	# A stopped clock grown into the chest, and ink dripping off the shoulders.
	var clock: Vector2 = pt(feet, k, 0, -62)
	InkDraw.paper_disc(ci, clock, 6.0 * k, DuskStyle.PEARL, 250)
	InkDraw.rough_circle(ci, clock, 6.0 * k, DuskStyle.INK, 2.0, 251)
	InkDraw.rough_line(ci, clock, clock + Vector2(0, -4) * k, DuskStyle.INK, 1.5, 252)
	InkDraw.rough_line(ci, clock, clock + Vector2(3, 2) * k, DuskStyle.INK, 1.5, 253)
	for i: int in range(3):
		var drip: Vector2 = pt(feet, k, 6 + i * 3, -40)
		InkDraw.rough_line(ci, drip, drip + Vector2(0, 8 + i * 4) * k, Color(DuskStyle.INK, 0.7), 2.0, 210 + i)

## Single-colour: too long and too many. The torso is an arch walking on far
## more than four over-long limbs; the head hangs upside down under the arch
## with one violet slit for a face; rebar out of the back; one hand holds up
## whatever it found (here a coat hanger). Violet is its only colour.
func monochrome(ci: CanvasItem, feet: Vector2) -> void:
	var k: float = 0.8
	var ink: Color = Color(DuskStyle.INK, 0.92)
	var violet: Color = DuskStyle.DUSK_TOP
	var arch: PackedVector2Array = PackedVector2Array([pt(feet, k, 40, -8), pt(feet, k, 28, -52), pt(feet, k, 4, -74), pt(feet, k, -22, -62), pt(feet, k, -42, -26)])
	# Rebar out of the back, behind the arch.
	for i: int in range(3):
		var root_at: Vector2 = arch[1].lerp(arch[2], 0.3 + i * 0.3)
		InkDraw.rough_line(ci, root_at, root_at + Vector2(18 + i * 8, -34 + i * 6) * k, Color("4a403a"), 2.5, 320 + i, 0.3)
	# Limbs: seven over-long legs with high knees, like a many-legged thing.
	for i: int in range(7):
		var t: float = 0.05 + 0.9 * i / 6.0
		var seg: int = mini(int(t * 4.0), 3)
		var root_at: Vector2 = arch[seg].lerp(arch[seg + 1], t * 4.0 - seg)
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var knee: Vector2 = root_at + Vector2(side * 14, -18) * k
		var foot: Vector2 = Vector2(root_at.x + side * 20 * k, feet.y)
		stroke(ci, PackedVector2Array([root_at, knee, foot]), ink, 3.0 * k, 340 + i * 3)
	stroke(ci, arch, ink, 11.0 * k, 300)
	var rim: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in arch:
		rim.append(p + Vector2(0, -5) * k)
	stroke(ci, rim, violet, 2.5, 301)
	# The neck drops from the top of the arch; the head hangs upside down.
	var head: Vector2 = pt(feet, k, -10, -30)
	stroke(ci, PackedVector2Array([arch[2], pt(feet, k, -4, -52), head + Vector2(2, -6) * k]), ink, 4.0 * k, 310)
	blob(ci, head, Vector2(9, 7) * k, ink, 311, 0.1)
	InkDraw.rough_line(ci, head + Vector2(-9, 2) * k, head + Vector2(8, 0) * k, violet.lightened(0.25), 2.5, 312)
	# One arm held high with a coat hanger.
	var hand: Vector2 = pt(feet, k, -34, -104)
	stroke(ci, PackedVector2Array([arch[3], pt(feet, k, -40, -84), hand]), ink, 3.5 * k, 350)
	var wire: Color = Color("6a6058")
	InkDraw.rough_line(ci, hand, hand + Vector2(0, 6) * k, wire, 1.8, 351, 0.2)
	var hanger: PackedVector2Array = PackedVector2Array([hand + Vector2(0, 6) * k, hand + Vector2(-16, 18) * k, hand + Vector2(16, 18) * k, hand + Vector2(0, 6) * k])
	for i: int in range(3):
		InkDraw.rough_line(ci, hanger[i], hanger[i + 1], wire, 1.8, 352 + i, 0.2)
	# Dash streaks behind it stay violet (FX-002).
	for i: int in range(3):
		InkDraw.rough_line(ci, pt(feet, k, 46 + i * 6, -20 - i * 16), pt(feet, k, 82 + i * 12, -20 - i * 16), Color(violet, 0.6), 2.0, 330 + i)

## Tian warrior: ornate armour that is empty inside, every one identical. A gold
## mask grinning from edge to edge with crescent eyes, ink leaking from the
## joints, a halo of broken blades grown into its back, and a standard-issue
## polearm: straight segmented shaft, geometric blade, a pearl light line.
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
	# Gold mask, tilted; a grin from edge to edge with pearl teeth, crescent eyes.
	var tilt: float = -0.3
	InkDraw.paper_disc(ci, head, 12.0 * k, DuskStyle.GROWTH, 412)
	InkDraw.rough_circle(ci, head, 12.0 * k, DuskStyle.INK, 2.0, 413)
	var grin: PackedVector2Array = PackedVector2Array()
	for i: int in range(9):
		var t: float = -1.0 + 2.0 * i / 8.0
		grin.append(head + Vector2(t * 11, -1.5 + 3.0 * (1.0 - t * t)).rotated(tilt) * k)
	for i: int in range(9):
		var t: float = 1.0 - 2.0 * i / 8.0
		grin.append(head + Vector2(t * 11, -1.5 + 9.0 * (1.0 - t * t)).rotated(tilt) * k)
	ci.draw_colored_polygon(grin, DuskStyle.INK)
	for i: int in range(5):
		var x: float = -6.0 + i * 3.0
		InkDraw.rough_line(ci, head + Vector2(x, 1.5 + 2.5 * (1.0 - x * x / 121.0)).rotated(tilt) * k, head + Vector2(x, 4.5 + 3.5 * (1.0 - x * x / 121.0)).rotated(tilt) * k, DuskStyle.PEARL, 1.2, 440 + i, 0.1)
	for e: float in [-1.0, 1.0]:
		var c: Vector2 = Vector2(e * 5.0, -5.0)
		var arc: PackedVector2Array = PackedVector2Array([head + (c + Vector2(-3, 1.5)).rotated(tilt) * k, head + (c + Vector2(0, -1.5)).rotated(tilt) * k, head + (c + Vector2(3, 1.5)).rotated(tilt) * k])
		for i: int in range(2):
			InkDraw.rough_line(ci, arc[i], arc[i + 1], DuskStyle.INK, 1.8, 414 + i + int(e) * 2, 0.1)
	# Ink leaking from the hip and shoulder joints.
	var joints: Array = [f["hip"] + Vector2(-9, 0) * k, f["hip"] + Vector2(9, 0) * k, f["neck"] + Vector2(-14, 6) * k]
	for i: int in range(joints.size()):
		var j: Vector2 = joints[i]
		InkDraw.rough_line(ci, j, j + Vector2(1, 10 + i * 3) * k, Color(DuskStyle.INK, 0.8), 2.5, 420 + i)
	# Standard-issue polearm: straight, segmented, a pearl light line on the blade.
	var low: Vector2 = f["neck"] + Vector2(-12, 50) * k
	var high: Vector2 = f["neck"] + Vector2(-30, -40) * k
	var d: Vector2 = (high - low).normalized()
	var n: Vector2 = Vector2(-d.y, d.x)
	InkDraw.rough_line(ci, low, high, DuskStyle.INK, 4.0, 430, 0.1)
	for i: int in range(1, 5):
		var p: Vector2 = low.lerp(high, i / 5.0)
		InkDraw.rough_line(ci, p - n * 3.0, p + n * 3.0, DuskStyle.GROWTH, 2.0, 432 + i, 0.1)
	var tip: Vector2 = high + d * 26 * k
	var blade: PackedVector2Array = PackedVector2Array([high - n * 3.5 * k, high + n * 3.5 * k, tip + n * 1.5 * k, tip + d * 4 * k, tip - n * 1.5 * k])
	ci.draw_colored_polygon(blade, DuskStyle.INK)
	InkDraw.rough_line(ci, high + d * 2, tip + d * 2 * k, DuskStyle.PEARL, 1.8, 438, 0.05)

## Overlook (Boss, 250%): a single-colour entity, hunched, flying without
## wings, carrying a huge polished leather shoe on its back. Its face changes
## with height: scornful above the player (as here), fawning below.
func overlook(ci: CanvasItem, c: Vector2) -> void:
	var k: float = 2.1
	var ink: Color = Color(DuskStyle.INK, 0.94)
	var violet: Color = DuskStyle.DUSK_TOP
	# Over-long limbs hanging below it, an extra joint each.
	# Arms reach down and forward toward the player; legs trail behind and below.
	for limb: Array in [[[-16, -8], [-34, 14], [-30, 38], [-44, 52], 560], [[-6, 0], [-20, 24], [-12, 46], [-24, 62], 564],
			[[28, 6], [40, 26], [48, 48], [62, 60], 568], [[34, 2], [52, 18], [60, 40], [76, 50], 572]]:
		var pts: PackedVector2Array = PackedVector2Array()
		for j: int in range(4):
			pts.append(c + Vector2(limb[j][0], limb[j][1]) * k)
		stroke(ci, pts, ink, 3.5 * k, limb[4])
	# Hunched torso, edged in violet.
	var torso: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in [Vector2(36, 2), Vector2(30, -16), Vector2(12, -26), Vector2(-10, -22), Vector2(-24, -8), Vector2(-16, 8), Vector2(8, 12), Vector2(30, 10)]:
		torso.append(c + p * k)
	ci.draw_colored_polygon(torso, ink)
	stroke(ci, torso + PackedVector2Array([torso[0]]), violet, 3.0, 501)
	# The polished shoe pressing on its back, flesh straps grown into the body.
	var shoe: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in [Vector2(-20, -26), Vector2(-14, -36), Vector2(0, -41), Vector2(14, -46), Vector2(26, -55), Vector2(40, -57), Vector2(45, -47), Vector2(45, -32), Vector2(36, -28), Vector2(-14, -24)]:
		shoe.append(c + p * k)
	ci.draw_colored_polygon(shoe, Color("1c1714"))
	stroke(ci, shoe + PackedVector2Array([shoe[0]]), DuskStyle.INK, 3.0, 580)
	InkDraw.rough_line(ci, c + Vector2(-16, -26) * k, c + Vector2(44, -30) * k, Color("6a5a4c"), 4.0, 581, 0.2)
	InkDraw.rough_line(ci, c + Vector2(-14, -33) * k, c + Vector2(-2, -38) * k, DuskStyle.PEARL, 2.5, 582, 0.1)
	InkDraw.rough_line(ci, c + Vector2(30, -53) * k, c + Vector2(41, -54) * k, DuskStyle.PEARL, 2.5, 583, 0.1)
	for i: int in range(4):
		var lace: Vector2 = c + Vector2(4 + i * 4, -42 - i * 2.5) * k
		InkDraw.rough_line(ci, lace + Vector2(-3, -2) * k, lace + Vector2(3, 2) * k, DuskStyle.PEARL, 1.5, 584 + i, 0.1)
		InkDraw.rough_line(ci, lace + Vector2(-3, 2) * k, lace + Vector2(3, -2) * k, DuskStyle.PEARL, 1.5, 588 + i, 0.1)
	for strap: Array in [[Vector2(-6, -26), Vector2(-12, -6)], [Vector2(28, -28), Vector2(24, 8)]]:
		InkDraw.rough_line(ci, c + strap[0] * k, c + strap[1] * k, Color(violet, 0.85), 5.0, 590)
	# A long neck thrust forward; the scornful face looks down at the player.
	stroke(ci, PackedVector2Array([c + Vector2(-20, -14) * k, c + Vector2(-28, -6) * k, c + Vector2(-32, 2) * k]), ink, 8.0 * k, 595)
	overlook_face(ci, c + Vector2(-34, 8) * k, 11.0 * k, true)

## One of Overlook's two faces. Scorn (above the player): brows crushed down,
## slanted eyes, a gaping mouth of crooked teeth. Fawn (below the player):
## eyes curved shut, pleading brows, a wide ingratiating grin, a bead of sweat.
func overlook_face(ci: CanvasItem, c: Vector2, r: float, scorn: bool) -> void:
	var violet: Color = DuskStyle.DUSK_TOP.lightened(0.15)
	var pts: PackedVector2Array = blob(ci, c, Vector2(r, r * 1.1), Color(DuskStyle.INK, 0.96), 596, 0.08)
	stroke(ci, pts + PackedVector2Array([pts[0]]), DuskStyle.DUSK_TOP, 2.5, 597)
	var w: float = maxf(r * 0.09, 1.5)
	for e: float in [-1.0, 1.0]:
		if scorn:
			InkDraw.rough_line(ci, c + Vector2(e * 0.62, -0.5) * r, c + Vector2(e * 0.1, -0.2) * r, violet, w * 1.4, 600 + int(e), 0.1)
			InkDraw.rough_line(ci, c + Vector2(e * 0.56, -0.28) * r, c + Vector2(e * 0.18, -0.12) * r, DuskStyle.PEARL, w, 602 + int(e), 0.1)
		else:
			InkDraw.rough_line(ci, c + Vector2(e * 0.58, -0.3) * r, c + Vector2(e * 0.14, -0.46) * r, violet, w * 1.2, 604 + int(e), 0.1)
			var eye: Vector2 = c + Vector2(e * 0.36, -0.12) * r
			InkDraw.rough_line(ci, eye + Vector2(-0.16, 0.04) * r, eye + Vector2(0, -0.08) * r, DuskStyle.PEARL, w, 606 + int(e), 0.1)
			InkDraw.rough_line(ci, eye + Vector2(0, -0.08) * r, eye + Vector2(0.16, 0.04) * r, DuskStyle.PEARL, w, 608 + int(e), 0.1)
	if scorn:
		var mouth: PackedVector2Array = PackedVector2Array([c + Vector2(-0.55, 0.12) * r, c + Vector2(0.5, 0.18) * r, c + Vector2(0.36, 0.72) * r, c + Vector2(-0.3, 0.66) * r])
		ci.draw_colored_polygon(mouth, Color("4a2a55"))
		for row: Array in [[mouth[0], mouth[1], 1.0], [mouth[3], mouth[2], -1.0]]:
			for i: int in range(6):
				var a: Vector2 = (row[0] as Vector2).lerp(row[1], i / 6.0)
				var b: Vector2 = (row[0] as Vector2).lerp(row[1], (i + 1) / 6.0)
				var spike: Vector2 = a.lerp(b, 0.5) + Vector2(0, 0.14 * r * float(row[2]) * (0.6 + 0.4 * InkDraw.noise(i, 610)))
				ci.draw_colored_polygon(PackedVector2Array([a, spike, b]), DuskStyle.PEARL)
		for i: int in range(3):
			InkDraw.rough_line(ci, c + Vector2(-0.12 + i * 0.1, -0.06) * r, c + Vector2(-0.08 + i * 0.1, 0.06) * r, violet, w * 0.8, 612 + i, 0.1)
	else:
		var grin: PackedVector2Array = PackedVector2Array()
		for i: int in range(9):
			var t: float = -1.0 + 2.0 * i / 8.0
			grin.append(c + Vector2(t * 0.62, 0.06 + 0.12 * (1.0 - t * t)) * r)
		for i: int in range(9):
			var t: float = 1.0 - 2.0 * i / 8.0
			grin.append(c + Vector2(t * 0.62, 0.06 + 0.5 * (1.0 - t * t)) * r)
		ci.draw_colored_polygon(grin, DuskStyle.PEARL)
		for i: int in range(8):
			var t: float = -1.0 + 2.0 * i / 7.0
			InkDraw.rough_line(ci, c + Vector2(t * 0.62, 0.06 + 0.3 * (1.0 - t * t)) * r, c + Vector2((t + 2.0 / 7.0) * 0.62, 0.06 + 0.3 * (1.0 - pow(t + 2.0 / 7.0, 2))) * r, DuskStyle.INK, w * 0.7, 614 + i, 0.05)
		blob(ci, c + Vector2(0.78, -0.4) * r, Vector2(0.08, 0.13) * r, DuskStyle.PEARL, 620, 0.05)
		for e: float in [-1.0, 1.0]:
			InkDraw.rough_line(ci, c + Vector2(e * 0.66, 0.0) * r, c + Vector2(e * 0.74, 0.2) * r, violet, w * 0.8, 622 + int(e), 0.1)

## The two faces side by side, enlarged, in the empty sky.
func overlook_faces(ci: CanvasItem, at: Vector2) -> void:
	var box: Rect2 = Rect2(at, Vector2(330, 200))
	InkDraw.paper(ci, box, Color(DuskStyle.PAPER_DAY, 0.92), 630)
	InkDraw.rough_rect(ci, box, DuskStyle.INK, 1.5, 631)
	text(ci, at + Vector2(14, 28), "渴望俯视的两张脸", 18)
	overlook_face(ci, at + Vector2(90, 104), 40.0, true)
	overlook_face(ci, at + Vector2(240, 104), 40.0, false)
	text(ci, at + Vector2(26, 186), "高于玩家：狰狞", 16)
	text(ci, at + Vector2(176, 186), "低于玩家：谄媚", 16)

## Parasite companion (Boss, 250%): a deserter half eaten by a parasite, with
## two heads. The human half is thin and pleading, a broken shackle on each
## wrist, and keeps a little warm rim light; the parasite half grows out of
## its back, segmented, its eyeless head nothing but a ring of teeth. Flesh
## tubes run over everything.
func parasite(ci: CanvasItem, feet: Vector2) -> void:
	var red: Color = Color("6e1f3a")
	var k: float = 2.5
	var neck: Vector2 = pt(feet, k, 0, -86)
	# The parasite body rises out of the back and arches toward the player.
	var spine: PackedVector2Array = PackedVector2Array([neck + Vector2(10, 10) * k, neck + Vector2(24, -12) * k, neck + Vector2(22, -38) * k, neck + Vector2(8, -54) * k, neck + Vector2(-12, -56) * k, neck + Vector2(-26, -46) * k])
	for i: int in range(spine.size() - 1):
		for j: int in range(3):
			var p: Vector2 = spine[i].lerp(spine[i + 1], j / 3.0)
			var rad: float = (9.0 - i * 0.8) * k
			InkDraw.paper_disc(ci, p, rad, red, 640 + i * 3 + j)
			InkDraw.rough_circle(ci, p, rad, Color(DuskStyle.INK, 0.8), 2.0, 660 + i * 3 + j)
	# The parasite head: no eyes, a round mouth ringed with teeth.
	var mouth: Vector2 = spine[spine.size() - 1] + Vector2(-6, 6) * k
	InkDraw.paper_disc(ci, mouth, 11.0 * k, red, 680)
	InkDraw.rough_circle(ci, mouth, 11.0 * k, DuskStyle.INK, 3.0, 681)
	ci.draw_circle(mouth + Vector2(-2, 2) * k, 7.0 * k, Color("2a0e18"))
	for i: int in range(12):
		var a: float = TAU * i / 12.0
		var o: Vector2 = Vector2(cos(a), sin(a))
		var base: Vector2 = mouth + Vector2(-2, 2) * k + o * 7.0 * k
		ci.draw_colored_polygon(PackedVector2Array([base + o.orthogonal() * 2.0 * k, base - o.orthogonal() * 2.0 * k, base - o * 4.0 * k]), DuskStyle.PEARL)
	# The human half: thin, hunched a little, warm rim light still on it.
	var f: Dictionary = figure(ci, feet, PLAYER_H * k, Color("8a7a6a"), 600, true)
	for s: float in [-1.0, 1.0]:
		var wrist: Vector2 = f["neck"] + Vector2(16 * s, 36) * k
		InkDraw.rough_rect(ci, Rect2(wrist - Vector2(4, 3) * k, Vector2(8, 6) * k), Color("6a6058"), 3.0, 690 + int(s))
		InkDraw.rough_line(ci, wrist + Vector2(0, 3) * k, wrist + Vector2(2 * s, 12) * k, Color("6a6058"), 2.0, 692 + int(s), 0.4)
	# Flesh tubes over the limbs and torso, running into the parasite body.
	for tube: Array in [[Vector2(10, 10), Vector2(4, 22), Vector2(-8, 30), Vector2(-12, 40)], [Vector2(12, 12), Vector2(10, 30), Vector2(6, 50), Vector2(10, 70)],
			[Vector2(14, 8), Vector2(20, 24), Vector2(18, 38)], [Vector2(8, 6), Vector2(-4, 4), Vector2(-14, 12), Vector2(-18, 30)]]:
		var pts: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in tube:
			pts.append(neck + p * k)
		stroke(ci, pts, red, 5.0, 700 + pts.size())
	# The human head: tilted, brows up, eyes wet, mouth open in a plea.
	var head: Vector2 = f["head"]
	for e: float in [-1.0, 1.0]:
		InkDraw.rough_line(ci, head + Vector2(e * 6.5, -4) * k, head + Vector2(e * 2, -6.5) * k, DuskStyle.INK, 2.0, 710 + int(e), 0.1)
		ci.draw_circle(head + Vector2(e * 4.5 - 1, -1.5) * k, 1.4 * k, DuskStyle.INK)
	blob(ci, head + Vector2(-6.5, 2) * k, Vector2(0.8, 1.6) * k, DuskStyle.PEARL, 714, 0.05)
	blob(ci, head + Vector2(-1, 5.5) * k, Vector2(2.2, 2.8) * k, DuskStyle.INK, 715, 0.1)

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
		"　无色＝无脸、颠倒的人体；单色＝过长多肢的拱＋紫缝；手持物取日常办公用品，不限品类；",
		"　天人＝咧到耳根的金色笑面＋刃环＋制式光刃；渴望俯视＝背皮鞋的佝偻飞人，高狰狞低谄媚；",
		"　寄生同伴者＝双头：哀求的人头＋只有口器的虫头，浑身肉管。",
		"特效沿用 FX-001 / FX-002，不重做；读招提示照常清楚。",
	]
	for i: int in range(lines.size()):
		text(ci, at + Vector2(0, 40 + i * 33), lines[i], 19)
