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
	compression_panel(ci, Vector2(440, 80))
	InkDraw.rough_rect(ci, box, DuskStyle.INK, 2.5, 7, 1.0)
	text(ci, Vector2(36, 54), "样张：荒地 · 黄昏（敌人按“同化 = 压缩”分层）", 22, DuskStyle.PEARL)
	for pair: Array in [[300, "玩家"], [500, "无色实体"], [650, "单色实体"], [800, "天人战士"]]:
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

## Colourless: no longer human in shape. A wasteland labourer and the shovel
## it used every day, compressed into one low four-legged crawler: the shovel
## blade is its jaw. All that is left of the person is one thing, here a rough
## human hand that became a foreleg. No face, no colour, no rim light; the
## object and the remnant are greyed out.
func colorless(ci: CanvasItem, feet: Vector2) -> void:
	var k: float = 0.8
	var ink: Color = Color(DuskStyle.INK, 0.92)
	var grey: Color = Color("9a958e")
	# Hind legs and the far foreleg: thin ink.
	stroke(ci, PackedVector2Array([pt(feet, k, 20, -24), pt(feet, k, 30, -12), pt(feet, k, 28, 0)]), ink, 4.0 * k, 260)
	stroke(ci, PackedVector2Array([pt(feet, k, 12, -22), pt(feet, k, 16, -10), pt(feet, k, 12, 0)]), ink, 4.0 * k, 262)
	stroke(ci, PackedVector2Array([pt(feet, k, -6, -24), pt(feet, k, -10, -12), pt(feet, k, -8, 0)]), ink, 4.0 * k, 264)
	# The shovel's shaft runs back through the body; its blade is the jaw.
	InkDraw.rough_line(ci, pt(feet, k, -30, -26), pt(feet, k, 14, -40), Color("8f8a84"), 3.0, 266, 0.2)
	var jaw: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in [Vector2(-28, -30), Vector2(-28, -20), Vector2(-44, -16), Vector2(-50, -22), Vector2(-46, -30)]:
		jaw.append(pt(feet, k, p.x, p.y))
	ci.draw_colored_polygon(jaw, grey)
	stroke(ci, jaw + PackedVector2Array([jaw[0]]), DuskStyle.INK, 1.5, 267)
	# The body: one low, bleeding mass with a snout over the blade.
	var body: PackedVector2Array = blob(ci, pt(feet, k, 2, -32), Vector2(26, 14) * k, ink, 270, 0.25)
	blob(ci, pt(feet, k, -26, -32), Vector2(10, 7) * k, ink, 271, 0.2)
	for i: int in range(0, body.size(), 2):
		InkDraw.rough_line(ci, body[i], body[(i + 2) % body.size()], Color(DuskStyle.INK, 0.4), 4.0, 272 + i, 1.6)
	# The remnant: a rough human hand, now its near foreleg, drawn in more detail.
	var wrist: Vector2 = pt(feet, k, -20, -8)
	stroke(ci, PackedVector2Array([pt(feet, k, -14, -26), pt(feet, k, -22, -16), wrist]), grey, 5.0 * k, 290)
	var palm: PackedVector2Array = PackedVector2Array([wrist + Vector2(-4, 0) * k, wrist + Vector2(4, 0) * k, wrist + Vector2(4, 6) * k, wrist + Vector2(-6, 7) * k])
	ci.draw_colored_polygon(palm, grey)
	stroke(ci, palm + PackedVector2Array([palm[0]]), DuskStyle.INK, 1.2, 291)
	for f: int in range(4):
		var base: Vector2 = wrist + Vector2(-5 + f * 2.8, 6.5) * k
		InkDraw.rough_line(ci, base, base + Vector2(-3 + f * 0.6, 2.5) * k, DuskStyle.INK, 1.4, 292 + f, 0.1)
	InkDraw.rough_line(ci, wrist + Vector2(4, 2) * k, wrist + Vector2(8, 5) * k, DuskStyle.INK, 1.4, 296, 0.1)

## Single-colour: reshaped by its obsession into a lean six-legged predator,
## front raised, quick. Its one colour, violet, is on what it clings to: an
## iron pipe wrapped in violet cloth, grown into a tail-sting curled high, and
## one line along its back. What is left of the person is an old coat draped
## over its back (flying ones spread it as wings). A weak rim light.
func monochrome(ci: CanvasItem, feet: Vector2) -> void:
	var k: float = 0.8
	var ink: Color = Color(DuskStyle.INK, 0.94)
	var violet: Color = DuskStyle.DUSK_TOP
	# The tail-sting: the pipe, wrapped in violet where it was held.
	var tail: PackedVector2Array = PackedVector2Array([pt(feet, k, 26, -36), pt(feet, k, 40, -54), pt(feet, k, 36, -76), pt(feet, k, 20, -86)])
	stroke(ci, tail, Color("5a5550"), 3.5, 360)
	stroke(ci, PackedVector2Array([tail[2], tail[3]]), violet, 5.0, 361)
	stroke(ci, PackedVector2Array([tail[3], tail[3] + Vector2(10, -8) * k, tail[3] + Vector2(20, -4) * k]), violet, 2.5, 362)
	# Six long jointed legs; the front pair raised to strike.
	for leg: Array in [[[-10, -38], [-22, -58], [-36, -52], 364], [[-2, -34], [-10, -52], [-22, 0], 367],
			[[8, -32], [4, -50], [-4, 0], 370], [[18, -32], [24, -50], [30, 0], 373]]:
		stroke(ci, PackedVector2Array([pt(feet, k, leg[0][0], leg[0][1]), pt(feet, k, leg[1][0], leg[1][1]), pt(feet, k, leg[2][0], leg[2][1])]), ink, 3.0 * k, leg[3])
	# Body and a small raised head; no human face.
	blob(ci, pt(feet, k, 6, -34), Vector2(24, 8) * k, ink, 376, 0.12)
	blob(ci, pt(feet, k, -22, -42), Vector2(8, 6) * k, ink, 377, 0.12)
	stroke(ci, PackedVector2Array([pt(feet, k, -16, -40), pt(feet, k, -8, -38)]), ink, 6.0 * k, 378)
	# The remnant: a torn coat over its back, with collar, pocket and buttons.
	var coat: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in [Vector2(-10, -40), Vector2(24, -44), Vector2(30, -30), Vector2(24, -26), Vector2(20, -31), Vector2(14, -24), Vector2(8, -30), Vector2(0, -25), Vector2(-6, -32)]:
		coat.append(pt(feet, k, p.x, p.y))
	ci.draw_colored_polygon(coat, Color("4a4038"))
	stroke(ci, coat + PackedVector2Array([coat[0]]), DuskStyle.INK, 1.8, 380)
	InkDraw.rough_line(ci, pt(feet, k, -10, -40), pt(feet, k, -2, -46), DuskStyle.INK, 2.0, 381)
	InkDraw.rough_line(ci, pt(feet, k, 10, -36), pt(feet, k, 18, -36), Color(DuskStyle.INK, 0.7), 1.2, 382)
	for b: int in range(3):
		ci.draw_circle(pt(feet, k, -2 + b * 6, -38), 1.2, DuskStyle.PEARL)
	# Its one violet line along the back, and a faint rim on the sun side.
	InkDraw.rough_line(ci, pt(feet, k, -8, -43), pt(feet, k, 24, -47), violet, 2.0, 383)
	InkDraw.rough_line(ci, pt(feet, k, -30, -44), pt(feet, k, -24, -48), Color(DuskStyle.SUN, 0.45), 1.5, 384)

## Tian warrior: being assimilated, still human inside. Top of the outside
## world: streamlined pearl-white armour with gold trim and glowing seams, the
## issued smile mask, a standard-issue polearm; all identical, upright. Ink
## climbs up from the hands and feet. Full rim light.
func tian(ci: CanvasItem, feet: Vector2) -> void:
	var k: float = 0.8
	var shell: Color = DuskStyle.PEARL
	var gold: Color = DuskStyle.GROWTH
	var hip: Vector2 = pt(feet, k, 0, -48)
	var neck: Vector2 = pt(feet, k, 0, -86)
	# Legs: armoured thighs, ink already up to the knees.
	for leg: float in [-1.0, 1.0]:
		var top: Vector2 = hip + Vector2(6 * leg, 0) * k
		var knee: Vector2 = pt(feet, k, 8 * leg, -24)
		var foot: Vector2 = pt(feet, k, 11 * leg, 0)
		InkDraw.rough_line(ci, top, knee, DuskStyle.INK, 8.0 * k, 470 + int(leg))
		InkDraw.rough_line(ci, top, knee, shell, 5.0 * k, 472 + int(leg), 0.2)
		InkDraw.rough_line(ci, knee, foot, DuskStyle.INK, 7.0 * k, 474 + int(leg))
		InkDraw.rough_line(ci, knee, knee + Vector2(2 * leg, -6) * k, DuskStyle.INK, 2.0, 476 + int(leg))
		for c: int in range(2):
			InkDraw.rough_line(ci, foot, foot + Vector2(-5 - c * 2, 1) * k, DuskStyle.INK, 1.6, 500 + c + int(leg) * 3, 0.1)
	# Torso: streamlined shell, gold trim, a glowing seam.
	var torso: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in [Vector2(-12, -86), Vector2(12, -86), Vector2(14, -70), Vector2(10, -48), Vector2(-10, -48), Vector2(-14, -70)]:
		torso.append(pt(feet, k, p.x, p.y))
	ci.draw_colored_polygon(torso, shell)
	stroke(ci, torso + PackedVector2Array([torso[0]]), DuskStyle.INK, 2.5, 478)
	InkDraw.rough_line(ci, pt(feet, k, -12, -64), pt(feet, k, 12, -64), gold, 2.0, 479, 0.2)
	InkDraw.rough_line(ci, pt(feet, k, 0, -84), pt(feet, k, 0, -66), Color("fff2c0"), 2.0, 480, 0.1)
	InkDraw.rough_line(ci, pt(feet, k, -14, -84), pt(feet, k, -11, -50), DuskStyle.SUN, 2.5, 481)
	# Arms: armoured upper arms, ink-dark forearms and hands.
	for arm: float in [-1.0, 1.0]:
		var shoulder: Vector2 = neck + Vector2(12 * arm, 4) * k
		var elbow: Vector2 = neck + Vector2(17 * arm, 22) * k
		var hand: Vector2 = neck + Vector2(14 * arm, 40) * k
		InkDraw.rough_line(ci, shoulder, elbow, DuskStyle.INK, 7.0 * k, 482 + int(arm))
		InkDraw.rough_line(ci, shoulder, elbow, shell, 4.0 * k, 484 + int(arm), 0.2)
		InkDraw.rough_line(ci, elbow, hand, DuskStyle.INK, 6.0 * k, 486 + int(arm))
		InkDraw.paper_disc(ci, shoulder, 5.0 * k, gold, 488 + int(arm))
		for c: int in range(3):
			InkDraw.rough_line(ci, hand, hand + Vector2(-2 + c * 2, 5) * k, DuskStyle.INK, 1.5, 506 + c + int(arm) * 4, 0.1)
	# Helmet and the issued smile mask.
	var head: Vector2 = pt(feet, k, 0, -100)
	InkDraw.paper_disc(ci, head + Vector2(3, -1) * k, 12.0 * k, shell, 490)
	InkDraw.rough_circle(ci, head + Vector2(3, -1) * k, 12.0 * k, DuskStyle.INK, 2.0, 491)
	InkDraw.paper_disc(ci, head + Vector2(-2, 1) * k, 9.5 * k, gold, 492)
	InkDraw.rough_circle(ci, head + Vector2(-2, 1) * k, 9.5 * k, DuskStyle.INK, 1.5, 493)
	for e: float in [-1.0, 1.0]:
		var c: Vector2 = head + Vector2(-2 + e * 4, -1.5) * k
		InkDraw.rough_line(ci, c + Vector2(-2, 1) * k, c + Vector2(0, -1) * k, DuskStyle.INK, 1.5, 494 + int(e), 0.1)
		InkDraw.rough_line(ci, c + Vector2(0, -1) * k, c + Vector2(2, 1) * k, DuskStyle.INK, 1.5, 496 + int(e), 0.1)
	var smile: PackedVector2Array = PackedVector2Array()
	for i: int in range(7):
		var t: float = -1.0 + 2.0 * i / 6.0
		smile.append(head + Vector2(-2 + t * 6, 3.0 + 2.5 * (1.0 - t * t)) * k)
	for i: int in range(smile.size() - 1):
		InkDraw.rough_line(ci, smile[i], smile[i + 1], DuskStyle.INK, 1.5, 498 + i, 0.1)
	# Standard-issue polearm: straight, segmented, a pearl light line on the blade.
	var low: Vector2 = neck + Vector2(-12, 50) * k
	var high: Vector2 = neck + Vector2(-30, -40) * k
	var d: Vector2 = (high - low).normalized()
	var n: Vector2 = Vector2(-d.y, d.x)
	InkDraw.rough_line(ci, low, high, DuskStyle.INK, 4.0, 430, 0.1)
	for i: int in range(1, 5):
		var p: Vector2 = low.lerp(high, i / 5.0)
		InkDraw.rough_line(ci, p - n * 3.0, p + n * 3.0, gold, 2.0, 432 + i, 0.1)
	var tip: Vector2 = high + d * 26 * k
	var blade: PackedVector2Array = PackedVector2Array([high - n * 3.5 * k, high + n * 3.5 * k, tip + n * 1.5 * k, tip + d * 4 * k, tip - n * 1.5 * k])
	ci.draw_colored_polygon(blade, DuskStyle.INK)
	InkDraw.rough_line(ci, high + d * 2, tip + d * 2 * k, DuskStyle.PEARL, 1.8, 438, 0.05)

## Assimilation is compression: the less detail left, the less of the person.
## A survivor, a Tian warrior, a single-colour and a colourless side by side.
func compression_panel(ci: CanvasItem, at: Vector2) -> void:
	var box: Rect2 = Rect2(at, Vector2(820, 360))
	InkDraw.paper(ci, box, Color(DuskStyle.PAPER_DAY, 0.93), 900)
	InkDraw.rough_rect(ci, box, DuskStyle.INK, 1.5, 901)
	text(ci, at + Vector2(16, 30), "同化 = 压缩：保留的细节 = 保留的意识", 20)
	var zoom: float = 2.0
	var steps: Array = [["人（幸存者）：完整", 0], ["天人：正在同化", 1], ["单色：只剩执念", 2], ["无色：压缩殆尽", 3]]
	for i: int in range(steps.size()):
		var foot: Vector2 = at + Vector2(110 + i * 200, 300)
		ci.draw_set_transform(foot, 0.0, Vector2(zoom, zoom))
		match int(steps[i][1]):
			0: figure(ci, Vector2.ZERO, PLAYER_H * 0.8, Color("8a7a6a"), 910)
			1: tian(ci, Vector2.ZERO)
			2: monochrome(ci, Vector2.ZERO)
			3: colorless(ci, Vector2.ZERO)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		text(ci, foot + Vector2(-80, 46), String(steps[i][0]), 17)
		if i < steps.size() - 1:
			text(ci, foot + Vector2(78, -80), "→", 26, Color(DuskStyle.INK, 0.6))

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
		"光：黄昏暖光从一侧（左）打来，亮面暖色边光，暗部偏冷紫；边光随意识递减。",
		"明度：角色深、背景远景浅而淡；生命红与可能性青不做大面积底色。",
		"敌人：同化＝压缩，细节越少意识越少；颜色即身份；手里的物件说明生前是谁。",
		"　逐级去人化：无色＝与生前物件压成一体的非人墨团；单色＝六足捕食者＋唯一的紫；",
		"　天人＝唯一的人形。无色、单色各留生前最重要的一处（样张：人手、外套）。Boss 重做中。",
		"特效沿用 FX-001 / FX-002，不重做；读招提示照常清楚。",
	]
	for i: int in range(lines.size()):
		text(ci, at + Vector2(0, 40 + i * 33), lines[i], 19)
