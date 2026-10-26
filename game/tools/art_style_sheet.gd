extends SceneTree
## ART-001: draws the style sheet the user signs the art style off against
## (`codexandclaude/tasks/ART-001/style_sheet.png`). A tool, not part of the
## game: run this script with the windowed Godot, `--path game -s` and its
## resource path (tools folder).
## Silhouettes only show line, colour, light and proportion; the real figures
## come from the generated art (ART-002 onward).

const OUT: String = "res://../codexandclaude/tasks/ART-001/style_sheet.png"
const OUT_CLOSE_UP: String = "res://../codexandclaude/tasks/ART-001/style_sheet_close_up.png"
const OUT_BOSSES: String = "res://../codexandclaude/tasks/ART-001/style_sheet_bosses.png"
const CLOSE_UP_ORIGIN: Vector2 = Vector2(240, 410)
const CLOSE_UP_SCALE: float = 3.0
const FLOOR: float = 640.0
const PLAYER_H: float = 112.0
## Rim light comes from the left (the low sun), shadows lean cool violet.
const SUN_SIDE: float = -1.0
var font: Font
var boss_mode: bool = false

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
	# Both bosses at their real display size, on a sheet of their own.
	boss_mode = true
	sheet.scale = Vector2.ONE
	sheet.position = Vector2.ZERO
	sheet.queue_redraw()
	for i: int in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT_BOSSES)
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
	if boss_mode:
		boss_sheet(ci)
		return
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

## A 2.5-heads-tall human in ink: a big round head (40 % of the height), a
## short chubby body and stubby limbs, dot eyes. Only people (and the Tian,
## still human inside) get the warm rim on the sun side and the violet shade.
func figure(ci: CanvasItem, feet: Vector2, h: float, fill: Color, seed: int, rim: bool = true, facing: float = 1.0) -> Dictionary:
	var k: float = h / PLAYER_H
	var head: Vector2 = feet + Vector2(0, -88) * k
	var neck: Vector2 = feet + Vector2(0, -66) * k
	var hip: Vector2 = feet + Vector2(0, -30) * k
	for leg: float in [-1.0, 1.0]:
		stroke(ci, PackedVector2Array([hip + Vector2(6 * leg, 0) * k, feet + Vector2(7 * leg, -4) * k]), DuskStyle.INK, 9.0 * k, seed + int(leg * 3))
		blob(ci, feet + Vector2(7 * leg + 2 * facing, -2) * k, Vector2(6, 3) * k, DuskStyle.INK, seed + 5 + int(leg), 0.05)
	for arm: float in [-1.0, 1.0]:
		stroke(ci, PackedVector2Array([neck + Vector2(12 * arm, 4) * k, neck + Vector2(17 * arm, 16) * k, neck + Vector2(15 * arm, 28) * k]), DuskStyle.INK, 7.0 * k, seed + 10 + int(arm * 3))
	var body: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in [Vector2(-12, -66), Vector2(12, -66), Vector2(15, -48), Vector2(12, -30), Vector2(-12, -30), Vector2(-15, -48)]:
		body.append(feet + p * k)
	ci.draw_colored_polygon(body, fill)
	stroke(ci, body + PackedVector2Array([body[0]]), DuskStyle.INK, 3.0, seed + 20)
	InkDraw.paper_disc(ci, head, 22.0 * k, fill, seed + 30, 0.4)
	InkDraw.rough_circle(ci, head, 22.0 * k, DuskStyle.INK, 3.0, seed + 31, 0.5)
	for e: float in [-1.0, 1.0]:
		ci.draw_circle(head + Vector2(7 * facing + e * 6, 1) * k, 2.2 * k, DuskStyle.INK)
	if rim:
		InkDraw.rough_line(ci, neck + Vector2(13 * SUN_SIDE, 2) * k, hip + Vector2(13 * SUN_SIDE, -4) * k, DuskStyle.SUN, 2.5, seed + 40)
		InkDraw.rough_line(ci, head + Vector2(21 * SUN_SIDE, -6) * k, head + Vector2(17 * SUN_SIDE, -14) * k, DuskStyle.SUN, 2.5, seed + 42)
		InkDraw.rough_line(ci, neck + Vector2(-11 * SUN_SIDE, 6) * k, hip + Vector2(-11 * SUN_SIDE, -4) * k, Color(DuskStyle.DUSK_TOP, 0.55), 4.0, seed + 41)
	return {"head": head, "neck": neck, "hip": hip, "k": k}

func player(ci: CanvasItem, feet: Vector2) -> void:
	var f: Dictionary = figure(ci, feet, PLAYER_H, DuskStyle.PAPER_DAY, 100)
	var k: float = f["k"]
	var neck: Vector2 = f["neck"]
	# A scarf tail and the starter blade: the player's two marks.
	stroke(ci, PackedVector2Array([neck + Vector2(-12, 0) * k, neck + Vector2(12, 0) * k]), DuskStyle.LIFE, 6.0, 109)
	stroke(ci, PackedVector2Array([neck + Vector2(-8, 2) * k, neck + Vector2(-24, 8) * k, neck + Vector2(-36, 4) * k]), DuskStyle.LIFE, 6.0, 110)
	var hand: Vector2 = neck + Vector2(15, 28) * k
	stroke(ci, PackedVector2Array([hand, hand + Vector2(28, -20) * k]), DuskStyle.INK, 4.0, 120)
	InkDraw.rough_line(ci, hand + Vector2(4, -4) * k, hand + Vector2(26, -19) * k, DuskStyle.PEARL, 1.5, 121)

## A point given in player units from the feet (enemies face left, toward the player).
func pt(feet: Vector2, k: float, x: float, y: float) -> Vector2:
	return feet + Vector2(x, y) * k

## A thin leg that tapers to a point (Silksong-style spindly legs).
func spike_leg(ci: CanvasItem, points: PackedVector2Array, color: Color, width: float, seed: int) -> void:
	for i: int in range(points.size() - 1):
		var w: float = lerpf(width, width * 0.35, float(i + 1) / float(points.size() - 1))
		InkDraw.rough_line(ci, points[i], points[i + 1], color, w, seed + i, 0.3)

## A smooth carapace: a dome over a flatter belly, with one sheen arc.
func shell(ci: CanvasItem, c: Vector2, r: Vector2, color: Color, seed: int) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(33):
		var a: float = PI + PI * i / 32.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	for i: int in range(1, 16):
		var a: float = PI * i / 16.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y * 0.35))
	ci.draw_colored_polygon(pts, color)
	for i: int in range(pts.size()):
		InkDraw.rough_line(ci, pts[i], pts[(i + 1) % pts.size()], DuskStyle.INK, 2.0, seed + i, 0.15)
	var sheen: PackedVector2Array = PackedVector2Array()
	for i: int in range(9):
		var a: float = PI * 1.2 + PI * 0.45 * i / 8.0
		sheen.append(c + Vector2(cos(a) * r.x * 0.72, sin(a) * r.y * 0.72))
	stroke(ci, sheen, Color("6a5e56"), 2.0, seed + 1)
	return pts

## Colourless: a person and their shovel compressed into a little shelled
## crawler. A domed ink carapace, a blank paper face-plate with no eyes at
## all, four spindly pointed legs; the shovel blade juts out under the plate
## as a jaw, its shaft set into the back of the shell. The one human thing
## left is a rough hand, now a foreleg. Object and remnant greyed; no rim light.
func colorless(ci: CanvasItem, feet: Vector2) -> void:
	var k: float = 0.8
	var grey: Color = Color("9a958e")
	for leg: Array in [[[18, -16], [28, -12], [30, 0], 260], [[10, -15], [14, -8], [12, 0], 263], [[-4, -15], [-6, -8], [-4, 0], 266]]:
		spike_leg(ci, PackedVector2Array([pt(feet, k, leg[0][0], leg[0][1]), pt(feet, k, leg[1][0], leg[1][1]), pt(feet, k, leg[2][0], leg[2][1])]), DuskStyle.INK, 3.5 * k, leg[3])
	# The shovel: blade out under the face-plate, shaft along the back.
	var jaw: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in [Vector2(-20, -18), Vector2(-20, -10), Vector2(-32, -9), Vector2(-36, -13), Vector2(-32, -18)]:
		jaw.append(pt(feet, k, p.x, p.y))
	ci.draw_colored_polygon(jaw, grey)
	stroke(ci, jaw + PackedVector2Array([jaw[0]]), DuskStyle.INK, 1.5, 268)
	shell(ci, pt(feet, k, 4, -16), Vector2(22, 20) * k, Color(DuskStyle.INK, 0.96), 270)
	InkDraw.rough_line(ci, pt(feet, k, 2, -34), pt(feet, k, 26, -44), Color("8f8a84"), 3.0, 272, 0.15)
	# A blank paper face-plate: no eyes, no features.
	var plate: Vector2 = pt(feet, k, -16, -20)
	blob(ci, plate, Vector2(8, 10) * k, DuskStyle.PAPER_DAY, 274, 0.04)
	InkDraw.rough_circle(ci, plate, 9.0 * k, DuskStyle.INK, 1.8, 275, 0.2)
	# The remnant: a rough human hand, now its near foreleg, drawn in more detail.
	var wrist: Vector2 = pt(feet, k, -10, -6)
	stroke(ci, PackedVector2Array([pt(feet, k, -6, -14), wrist]), grey, 4.5 * k, 290)
	blob(ci, wrist + Vector2(-1, 3) * k, Vector2(5, 3.5) * k, grey, 291, 0.05)
	for f: int in range(4):
		var base: Vector2 = wrist + Vector2(-5 + f * 2.6, 5.5) * k
		InkDraw.rough_line(ci, base, base + Vector2(-2 + f * 0.5, 2) * k, DuskStyle.INK, 1.4, 292 + f, 0.1)

## Single-colour: reshaped by its obsession into a quick little predator. A
## rounded ink shell on six spindly pointed legs, front pair raised; a paper
## face-plate with two wide hollow eyes and a pair of curved horns. The old
## coat is now a ragged cloak over the shell (flying ones spread it as wings).
## Violet only on what it clings to (the pipe, now a curled sting) and the
## cloak's edge. A weak rim light.
func monochrome(ci: CanvasItem, feet: Vector2) -> void:
	var k: float = 0.8
	var violet: Color = DuskStyle.DUSK_TOP
	# The curled tail-sting: the pipe, wrapped in violet where it was held.
	var tail: PackedVector2Array = PackedVector2Array([pt(feet, k, 20, -30), pt(feet, k, 32, -44), pt(feet, k, 30, -58), pt(feet, k, 20, -62), pt(feet, k, 16, -54)])
	stroke(ci, PackedVector2Array([tail[0], tail[1], tail[2]]), Color("5a5550"), 4.0, 360)
	stroke(ci, PackedVector2Array([tail[2], tail[3], tail[4]]), violet, 6.0, 361)
	stroke(ci, PackedVector2Array([tail[3], tail[3] + Vector2(8, -8) * k, tail[3] + Vector2(16, -6) * k]), violet, 2.5, 362)
	# Six spindly pointed legs; the front pair raised.
	for leg: Array in [[[-8, -32], [-20, -50], [-34, -46], 364], [[-2, -24], [-10, -14], [-14, 0], 367],
			[[8, -22], [6, -12], [2, 0], 370], [[16, -24], [24, -12], [28, 0], 373]]:
		spike_leg(ci, PackedVector2Array([pt(feet, k, leg[0][0], leg[0][1]), pt(feet, k, leg[1][0], leg[1][1]), pt(feet, k, leg[2][0], leg[2][1])]), DuskStyle.INK, 3.5 * k, leg[3])
	shell(ci, pt(feet, k, 6, -24), Vector2(18, 14) * k, Color(DuskStyle.INK, 0.96), 376)
	# The remnant: the coat, a ragged cloak with a collar and buttons.
	var cloak: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in [Vector2(-8, -36), Vector2(10, -40), Vector2(24, -30), Vector2(26, -20), Vector2(21, -23), Vector2(18, -16), Vector2(13, -22), Vector2(8, -15), Vector2(3, -21), Vector2(-2, -16), Vector2(-6, -24)]:
		cloak.append(pt(feet, k, p.x, p.y))
	ci.draw_colored_polygon(cloak, Color("7a6a5a"))
	stroke(ci, cloak + PackedVector2Array([cloak[0]]), DuskStyle.INK, 1.8, 380)
	stroke(ci, PackedVector2Array([cloak[3], cloak[4], cloak[5], cloak[6], cloak[7], cloak[8], cloak[9]]), violet, 2.0, 381)
	for b: int in range(3):
		ci.draw_circle(pt(feet, k, 0 + b * 6, -32 + b), 1.2, DuskStyle.PEARL)
	# Face-plate with two wide hollow eyes, and curved horns behind it.
	var head: Vector2 = pt(feet, k, -16, -40)
	for h: float in [0.0, 6.0]:
		stroke(ci, PackedVector2Array([head + Vector2(4 + h, -8) * k, head + Vector2(8 + h, -18) * k, head + Vector2(16 + h, -22) * k]), DuskStyle.INK, 3.0, 385 + int(h))
	blob(ci, head, Vector2(9, 11) * k, DuskStyle.PAPER_DAY, 388, 0.04)
	InkDraw.rough_circle(ci, head, 10.0 * k, DuskStyle.INK, 1.8, 389, 0.2)
	for e: float in [-1.0, 1.0]:
		blob(ci, head + Vector2(-2 + e * 3.5, -1) * k, Vector2(2.2, 3.4) * k, DuskStyle.INK, 390 + int(e), 0.05)
	InkDraw.rough_line(ci, head + Vector2(-10, -2) * k, head + Vector2(-8, -8) * k, Color(DuskStyle.SUN, 0.45), 1.5, 393)

## Tian warrior: being assimilated, still human inside, 2.5 heads tall. Top
## of the outside world, drawn like Silksong's elite: a rounded pearl-white
## shell of armour, a helmet with a pointed crest, a knee-length white cloak
## edged in gold, glowing seams; the issued smile mask; a needle-thin
## standard-issue polearm; all identical, upright. Ink climbs up from the
## thin, clawed hands and feet. Full rim light.
func tian(ci: CanvasItem, feet: Vector2) -> void:
	var k: float = 0.8
	var shell_c: Color = DuskStyle.PEARL
	var gold: Color = DuskStyle.GROWTH
	var neck: Vector2 = pt(feet, k, 0, -66)
	# The cloak hangs behind everything.
	var cloak: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in [Vector2(-10, -64), Vector2(12, -64), Vector2(22, -14), Vector2(16, -18), Vector2(12, -10), Vector2(6, -16), Vector2(2, -12)]:
		cloak.append(pt(feet, k, p.x, p.y))
	ci.draw_colored_polygon(cloak, Color("e6dac4"))
	stroke(ci, PackedVector2Array([cloak[1], cloak[2], cloak[3], cloak[4], cloak[5], cloak[6]]), gold, 2.0, 468)
	# Thin legs: ink up from clawed feet.
	for leg: float in [-1.0, 1.0]:
		var top: Vector2 = pt(feet, k, 5 * leg, -30)
		var knee: Vector2 = pt(feet, k, 6 * leg, -16)
		var foot: Vector2 = pt(feet, k, 6 * leg, -1)
		InkDraw.rough_line(ci, top, knee, DuskStyle.INK, 7.0 * k, 470 + int(leg))
		InkDraw.rough_line(ci, top, knee, shell_c, 4.0 * k, 472 + int(leg), 0.2)
		spike_leg(ci, PackedVector2Array([knee, foot]), DuskStyle.INK, 6.0 * k, 474 + int(leg))
		for c: int in range(2):
			InkDraw.rough_line(ci, foot, foot + Vector2(-5 - c * 2, 1) * k, DuskStyle.INK, 1.4, 500 + c + int(leg) * 3, 0.1)
	# Arms: armoured upper arms, thin ink forearms, clawed hands.
	for arm: float in [-1.0, 1.0]:
		var shoulder: Vector2 = neck + Vector2(12 * arm, 4) * k
		var elbow: Vector2 = neck + Vector2(16 * arm, 16) * k
		var hand: Vector2 = neck + Vector2(14 * arm, 28) * k
		InkDraw.rough_line(ci, shoulder, elbow, DuskStyle.INK, 7.0 * k, 482 + int(arm))
		InkDraw.rough_line(ci, shoulder, elbow, shell_c, 4.0 * k, 484 + int(arm), 0.2)
		spike_leg(ci, PackedVector2Array([elbow, hand]), DuskStyle.INK, 5.0 * k, 486 + int(arm))
		for c: int in range(3):
			InkDraw.rough_line(ci, hand, hand + Vector2(-2 + c * 2, 5) * k, DuskStyle.INK, 1.4, 506 + c + int(arm) * 4, 0.1)
	# Torso: a rounded shell of armour, gold trim, a glowing seam, warm rim.
	var torso: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in [Vector2(-11, -66), Vector2(11, -66), Vector2(15, -50), Vector2(10, -30), Vector2(-10, -30), Vector2(-15, -50)]:
		torso.append(pt(feet, k, p.x, p.y))
	ci.draw_colored_polygon(torso, shell_c)
	stroke(ci, torso + PackedVector2Array([torso[0]]), DuskStyle.INK, 2.5, 478)
	InkDraw.rough_line(ci, pt(feet, k, -14, -48), pt(feet, k, 14, -48), gold, 2.5, 479, 0.2)
	InkDraw.rough_line(ci, pt(feet, k, 0, -64), pt(feet, k, 0, -52), Color("fff2c0"), 2.0, 480, 0.1)
	InkDraw.rough_line(ci, pt(feet, k, -13, -64), pt(feet, k, -12, -34), DuskStyle.SUN, 2.5, 481)
	for arm: float in [-1.0, 1.0]:
		InkDraw.paper_disc(ci, neck + Vector2(12 * arm, 4) * k, 6.0 * k, gold, 488 + int(arm))
	# A round helmet with a pointed crest, and the issued smile mask.
	var head: Vector2 = pt(feet, k, 0, -88)
	var crest: PackedVector2Array = PackedVector2Array([head + Vector2(-5, -18) * k, head + Vector2(4, -40) * k, head + Vector2(9, -16) * k])
	ci.draw_colored_polygon(crest, shell_c)
	stroke(ci, crest, DuskStyle.INK, 2.0, 487)
	InkDraw.paper_disc(ci, head, 22.0 * k, shell_c, 490, 0.4)
	InkDraw.rough_circle(ci, head, 22.0 * k, DuskStyle.INK, 2.5, 491, 0.5)
	InkDraw.rough_line(ci, head + Vector2(-21, -6) * k, head + Vector2(-17, -14) * k, DuskStyle.SUN, 2.5, 489)
	var mask: Vector2 = head + Vector2(-4, 2) * k
	InkDraw.paper_disc(ci, mask, 16.0 * k, gold, 492, 0.3)
	InkDraw.rough_circle(ci, mask, 16.0 * k, DuskStyle.INK, 1.5, 493, 0.3)
	for e: float in [-1.0, 1.0]:
		var c: Vector2 = mask + Vector2(e * 6, -3) * k
		InkDraw.rough_line(ci, c + Vector2(-3, 1.5) * k, c + Vector2(0, -1.5) * k, DuskStyle.INK, 1.8, 494 + int(e), 0.1)
		InkDraw.rough_line(ci, c + Vector2(0, -1.5) * k, c + Vector2(3, 1.5) * k, DuskStyle.INK, 1.8, 496 + int(e), 0.1)
	var smile: PackedVector2Array = PackedVector2Array()
	for i: int in range(7):
		var t: float = -1.0 + 2.0 * i / 6.0
		smile.append(mask + Vector2(t * 8, 4.0 + 4.0 * (1.0 - t * t)) * k)
	for i: int in range(smile.size() - 1):
		InkDraw.rough_line(ci, smile[i], smile[i + 1], DuskStyle.INK, 1.8, 498 + i, 0.1)
	# Standard-issue polearm: needle-thin, segmented, a pearl light line on the blade.
	var low: Vector2 = pt(feet, k, -14, -12)
	var high: Vector2 = pt(feet, k, -30, -100)
	var d: Vector2 = (high - low).normalized()
	var n: Vector2 = Vector2(-d.y, d.x)
	InkDraw.rough_line(ci, low, high, DuskStyle.INK, 3.0, 430, 0.1)
	for i: int in range(1, 5):
		var p: Vector2 = low.lerp(high, i / 5.0)
		InkDraw.rough_line(ci, p - n * 2.5, p + n * 2.5, gold, 2.0, 432 + i, 0.1)
	var tip: Vector2 = high + d * 30 * k
	var blade: PackedVector2Array = PackedVector2Array([high - n * 2.5 * k, high + n * 2.5 * k, tip + d * 2 * k])
	ci.draw_colored_polygon(blade, DuskStyle.INK)
	InkDraw.rough_line(ci, high + d * 2, tip, DuskStyle.PEARL, 1.5, 438, 0.05)

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

# --- the boss sheet ----------------------------------------------------------

## Both bosses at their real display size (250 %), with the player for scale
## and Overlook's two faces enlarged.
func boss_sheet(ci: CanvasItem) -> void:
	var ground: float = 820.0
	InkDraw.wash(ci, Rect2(0, 0, 1920, ground), DuskStyle.DUSK_TOP, DuskStyle.DUSK_BOTTOM)
	InkDraw.glow(ci, Vector2(160, 640), 110.0, DuskStyle.SUN, 0.9)
	ci.draw_rect(Rect2(0, ground, 1920, 260), DuskStyle.PAPER_DUSK)
	for i: int in range(30):
		InkDraw.rough_line(ci, Vector2(i * 64, ground), Vector2(i * 64 + 64, ground), DuskStyle.INK, 3.0, 900 + i, 1.0)
	text(ci, Vector2(40, 50), "Boss 样张（按 1080p 实际显示大小：玩家 112 px，Boss 250% = 280 px）", 24, DuskStyle.PEARL)
	player(ci, Vector2(220, ground))
	overlook(ci, Vector2(820, 470))
	overlook_faces(ci, Vector2(40, 90))
	parasite(ci, Vector2(1440, ground))
	for pair: Array in [[190, "玩家"], [740, "渴望俯视"], [1380, "寄生同伴者"]]:
		text(ci, Vector2(float(pair[0]), ground + 50), String(pair[1]), 24)
	var notes: Array[String] = [
		"渴望俯视：住在精致皮鞋里的飞虫；皮鞋是壳，鞋底朝下，落击就是一脚踩下；金色只在鞋扣、鞋带孔；遗存：胸前的旧工牌。",
		"寄生同伴者：人与虫两个前半身在腰部拼接，两头都有主导意识；军用水壶成了胃囊；人的一端有边光，虫的一端没有。",
	]
	for i: int in range(notes.size()):
		text(ci, Vector2(40, ground + 110 + i * 40), notes[i], 20)

## Overlook (Boss, 250 %): a single-colour entity living in a polished leather
## shoe, the kind that once stood on its head. The shoe is its shell, sole
## down; a paper face-plate looks out of the opening; thin wings rise from the
## collar; spindly legs hang below. Its one colour, gold (the colour of the top
## it craves), only on the eyelets. A worn staff badge hangs on its chest.
func overlook(ci: CanvasItem, c: Vector2) -> void:
	var k: float = 2.5
	var gold: Color = DuskStyle.GROWTH
	# Wings behind the shoe.
	for w: Array in [[Vector2(10, 6), 0.5, 520], [Vector2(0, 0), 0.8, 524]]:
		var wing: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in [Vector2(28, -16), Vector2(36, -48), Vector2(54, -62), Vector2(62, -50), Vector2(48, -24)]:
			wing.append(c + (p + w[0]) * k)
		ci.draw_colored_polygon(wing, Color(DuskStyle.PAPER_DAY, float(w[1])))
		stroke(ci, wing + PackedVector2Array([wing[0]]), Color(DuskStyle.INK, 0.8), 2.0, int(w[2]))
		InkDraw.rough_line(ci, wing[0], wing[2], Color(DuskStyle.INK, 0.5), 1.5, int(w[2]) + 2, 0.3)
	# Spindly legs under the sole.
	for x: float in [-30.0, -12.0, 8.0, 26.0]:
		spike_leg(ci, PackedVector2Array([c + Vector2(x, 13) * k, c + Vector2(x - 4, 26) * k, c + Vector2(x - 9, 40) * k]), DuskStyle.INK, 3.0 * k, 530 + int(x))
	# The shoe: polished upper, a paler sole and heel, sheen arcs.
	var shoe: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in [Vector2(-48, 8), Vector2(-46, 0), Vector2(-36, -6), Vector2(-20, -11), Vector2(4, -15), Vector2(20, -13), Vector2(42, -17), Vector2(46, -8), Vector2(44, 8), Vector2(40, 12), Vector2(-44, 12)]:
		shoe.append(c + p * k)
	ci.draw_colored_polygon(shoe, Color("1f1a17"))
	for i: int in range(shoe.size()):
		InkDraw.rough_line(ci, shoe[i], shoe[(i + 1) % shoe.size()], DuskStyle.INK, 2.5, 540 + i, 0.15)
	ci.draw_rect(Rect2(c + Vector2(-44, 11) * k, Vector2(84, 4) * k), Color("5a4a40"))
	ci.draw_rect(Rect2(c + Vector2(30, 8) * k, Vector2(12, 7) * k), Color("4a3e36"))
	for arc: Array in [[Vector2(-40, 0), Vector2(-24, -8)], [Vector2(20, -8), Vector2(38, -12)]]:
		InkDraw.rough_line(ci, c + arc[0] * k, c + arc[1] * k, Color(DuskStyle.PEARL, 0.7), 3.0, 552, 0.1)
	# Gold eyelets and pearl laces: the only colour it has.
	for i: int in range(4):
		var e: Vector2 = c + Vector2(-12 + i * 4.5, -11.5 - i * 0.8) * k
		ci.draw_circle(e, 2.2 * k * 0.6, gold)
		if i < 3:
			InkDraw.rough_line(ci, e, e + Vector2(4.5, 4) * k, Color(DuskStyle.PEARL, 0.9), 1.5, 556 + i, 0.1)
	# The face-plate rising from the opening (scornful: it is above the player).
	overlook_face(ci, c + Vector2(24, -27) * k, 11.0 * k, true)
	# The remnant: a worn staff badge on a lanyard.
	var clip: Vector2 = c + Vector2(16, -16) * k
	InkDraw.rough_line(ci, c + Vector2(20, -18) * k, clip, DuskStyle.INK, 1.5, 560, 0.2)
	var card: Rect2 = Rect2(clip + Vector2(-5, 0) * k, Vector2(10, 12) * k)
	ci.draw_rect(card, Color("d8d2c4"))
	InkDraw.rough_rect(ci, card, DuskStyle.INK, 1.5, 561, 0.2)
	ci.draw_rect(Rect2(card.position + Vector2(2, 2) * k, Vector2(4, 4) * k), Color("8f8a84"))
	for i: int in range(2):
		InkDraw.rough_line(ci, card.position + Vector2(2, 8 + i * 2) * k, card.position + Vector2(8, 8 + i * 2) * k, Color(DuskStyle.INK, 0.6), 1.2, 562 + i, 0.1)
	InkDraw.rough_line(ci, c + Vector2(-47, 2) * k, c + Vector2(-38, -5) * k, Color(DuskStyle.SUN, 0.45), 2.0, 565)

## Overlook's face-plate. Scorn (above the player): tilted up, the hollow eyes
## narrowed to two slits. Fawn (below the player): bowed, the eyes turned up
## into two curves, a bead of sweat.
func overlook_face(ci: CanvasItem, c: Vector2, r: float, scorn: bool) -> void:
	blob(ci, c, Vector2(r, r * 1.15), DuskStyle.PAPER_DAY, 570, 0.04)
	InkDraw.rough_circle(ci, c, r * 1.05, DuskStyle.INK, maxf(r * 0.07, 1.8), 571, 0.2)
	var w: float = maxf(r * 0.1, 2.0)
	for e: float in [-1.0, 1.0]:
		var eye: Vector2 = c + Vector2(e * 0.36 - 0.12, -0.28 if scorn else 0.0) * r
		if scorn:
			InkDraw.rough_line(ci, eye + Vector2(-0.18, -0.04 * e) * r, eye + Vector2(0.18, 0.06 * e) * r, DuskStyle.INK, w, 572 + int(e), 0.05)
		else:
			InkDraw.rough_line(ci, eye + Vector2(-0.16, 0.06) * r, eye + Vector2(0, -0.1) * r, DuskStyle.INK, w, 574 + int(e), 0.05)
			InkDraw.rough_line(ci, eye + Vector2(0, -0.1) * r, eye + Vector2(0.16, 0.06) * r, DuskStyle.INK, w, 576 + int(e), 0.05)
	if not scorn:
		blob(ci, c + Vector2(0.72, -0.5) * r, Vector2(0.09, 0.15) * r, DuskStyle.PEARL, 578, 0.05)
		InkDraw.rough_circle(ci, c + Vector2(0.72, -0.48) * r, 0.12 * r, DuskStyle.INK, 1.2, 579, 0.1)

## The two faces side by side, enlarged.
func overlook_faces(ci: CanvasItem, at: Vector2) -> void:
	var box: Rect2 = Rect2(at, Vector2(420, 250))
	InkDraw.paper(ci, box, Color(DuskStyle.PAPER_DAY, 0.93), 580)
	InkDraw.rough_rect(ci, box, DuskStyle.INK, 1.5, 581)
	text(ci, at + Vector2(16, 30), "渴望俯视的两张面甲", 20)
	overlook_face(ci, at + Vector2(110, 130), 60.0, true)
	overlook_face(ci, at + Vector2(310, 130), 60.0, false)
	text(ci, at + Vector2(46, 232), "高于玩家：蔑视", 18)
	text(ci, at + Vector2(246, 232), "低于玩家：谄媚", 18)

## Parasite companion (Boss, 250 %): two front halves joined at the waist,
## each with a head and a will of its own. Left: a thin little deserter, 2.5
## heads tall, crawling on its arms, pleading, a broken shackle on each wrist,
## still in the warm light. Right: a Silksong-style parasite, segmented dark
## red, spindly legs, an eyeless head that is only a ring of teeth. A field
## canteen grown in at the waist is its stomach; flesh tubes bind the halves.
func parasite(ci: CanvasItem, feet: Vector2) -> void:
	var k: float = 2.5
	var red: Color = Color("6e1f3a")
	var waist: Vector2 = pt(feet, k, 0, -36)
	# The parasite half: segments rising to the right, spindly legs below.
	var spine: PackedVector2Array = PackedVector2Array([pt(feet, k, 8, -38), pt(feet, k, 20, -44), pt(feet, k, 31, -54), pt(feet, k, 39, -68), pt(feet, k, 44, -82)])
	for i: int in range(3):
		var root_at: Vector2 = spine[i]
		spike_leg(ci, PackedVector2Array([root_at, root_at + Vector2(10, 10 + i * 4) * k, Vector2(root_at.x + 16 * k, feet.y)]), DuskStyle.INK, 3.0 * k, 640 + i * 3)
	for i: int in range(spine.size()):
		var rad: float = (12.0 - i * 0.8) * k
		InkDraw.paper_disc(ci, spine[i], rad, red, 650 + i, 0.2)
		InkDraw.rough_circle(ci, spine[i], rad, DuskStyle.INK, 2.0, 655 + i, 0.2)
		InkDraw.rough_line(ci, spine[i] + Vector2(-rad * 0.6, -rad * 0.6), spine[i] + Vector2(-rad * 0.2, -rad * 0.9), Color("a04a62"), 2.0, 660 + i, 0.1)
	var head: Vector2 = pt(feet, k, 52, -90)
	InkDraw.paper_disc(ci, head, 13.0 * k, red, 665, 0.2)
	InkDraw.rough_circle(ci, head, 13.0 * k, DuskStyle.INK, 2.5, 666, 0.2)
	var mouth: Vector2 = head + Vector2(5, 0) * k
	ci.draw_circle(mouth, 8.0 * k, Color("2a0e18"))
	for i: int in range(12):
		var a: float = TAU * i / 12.0
		var o: Vector2 = Vector2(cos(a), sin(a))
		var base: Vector2 = mouth + o * 8.0 * k
		ci.draw_colored_polygon(PackedVector2Array([base + o.orthogonal() * 2.0 * k, base - o.orthogonal() * 2.0 * k, base - o * 4.0 * k]), DuskStyle.PEARL)
	# The human half: a thin deserter crawling on its arms toward the player.
	var shoulder: Vector2 = pt(feet, k, -32, -46)
	var coat: Color = Color("7a7058")
	for arm: Array in [[Vector2(2, 4), Vector2(-36, -18), Vector2(-36, 0), 670], [Vector2(-4, 6), Vector2(-44, -20), Vector2(-46, 0), 674]]:
		var hand: Vector2 = pt(feet, k, arm[2].x, arm[2].y)
		stroke(ci, PackedVector2Array([shoulder + arm[0] * k, pt(feet, k, arm[1].x, arm[1].y), hand]), coat.darkened(0.3), 7.0 * k, arm[3])
		InkDraw.rough_rect(ci, Rect2(hand + Vector2(-4, -9) * k, Vector2(8, 5) * k), Color("6a6058"), 3.0, int(arm[3]) + 2)
		InkDraw.rough_line(ci, hand + Vector2(2, -9) * k, hand + Vector2(6, -14) * k, Color("6a6058"), 2.0, int(arm[3]) + 3, 0.4)
	var torso: PackedVector2Array = PackedVector2Array([waist + Vector2(0, -10) * k, shoulder + Vector2(0, -12) * k, shoulder + Vector2(-2, 10) * k, waist + Vector2(0, 8) * k])
	ci.draw_colored_polygon(torso, coat)
	stroke(ci, torso + PackedVector2Array([torso[0]]), DuskStyle.INK, 2.5, 678)
	InkDraw.rough_line(ci, shoulder + Vector2(-1, -11) * k, waist + Vector2(0, -9) * k, DuskStyle.SUN, 2.5, 679)
	# The pleading human head: big hollow eyes, brows up, a tear.
	var face: Vector2 = shoulder + Vector2(-14, -14) * k
	InkDraw.paper_disc(ci, face, 22.0 * k, DuskStyle.PAPER_DAY, 680, 0.4)
	InkDraw.rough_circle(ci, face, 22.0 * k, DuskStyle.INK, 3.0, 681, 0.5)
	InkDraw.rough_line(ci, face + Vector2(-21, -6) * k, face + Vector2(-16, -15) * k, DuskStyle.SUN, 2.5, 682)
	for e: float in [-1.0, 1.0]:
		var eye: Vector2 = face + Vector2(-6 + e * 7, 0) * k
		blob(ci, eye, Vector2(3.2, 4.4) * k, DuskStyle.INK, 683 + int(e), 0.05)
		InkDraw.rough_line(ci, eye + Vector2(-4 * e, -11) * k, eye + Vector2(3 * e, -7.5) * k, DuskStyle.INK, 2.0, 685 + int(e), 0.1)
	blob(ci, face + Vector2(-15, 7) * k, Vector2(1.4, 2.4) * k, DuskStyle.PEARL, 687, 0.05)
	blob(ci, face + Vector2(-6, 10) * k, Vector2(2.0, 2.6) * k, DuskStyle.INK, 688, 0.1)
	# The canteen at the waist, its stomach, greyed out.
	var can: Vector2 = waist + Vector2(2, 2) * k
	blob(ci, can, Vector2(9, 11) * k, Color("8f8a7e"), 690, 0.05)
	InkDraw.rough_circle(ci, can, 10.0 * k, DuskStyle.INK, 2.0, 691, 0.2)
	ci.draw_rect(Rect2(can + Vector2(-2.5, -15) * k, Vector2(5, 5) * k), Color("6a665c"))
	InkDraw.rough_line(ci, can + Vector2(-9, -4) * k, can + Vector2(9, -4) * k, Color("6a665c"), 3.0, 692, 0.2)
	# Flesh tubes binding the halves.
	for tube: Array in [[Vector2(-4, -44), Vector2(-14, -50), Vector2(-26, -48)], [Vector2(6, -30), Vector2(-10, -26), Vector2(-28, -36)],
			[Vector2(8, -46), Vector2(16, -56), Vector2(28, -60)], [Vector2(6, -28), Vector2(18, -30), Vector2(26, -44)]]:
		var pts: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in tube:
			pts.append(pt(feet, k, p.x, p.y))
		stroke(ci, pts, red, 6.0, 694 + pts.size())

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
		"比例：人形 2.5 头身，圆润可爱；敌人造型参照丝之歌：壳、面甲、细尖的腿、角、披布。",
		"敌人：同化＝压缩，细节越少意识越少；颜色即身份；手里的物件说明生前是谁。",
		"　逐级去人化：无色＝与生前物件压成一体的非人墨团；单色＝六足捕食者＋唯一的紫；",
		"　天人＝唯一的人形。无色、单色各留生前最重要的一处（样张：人手、外套）。Boss 另见 Boss 样张。",
		"特效沿用 FX-001 / FX-002，不重做；读招提示照常清楚。",
	]
	for i: int in range(lines.size()):
		text(ci, at + Vector2(0, 40 + i * 33), lines[i], 19)
