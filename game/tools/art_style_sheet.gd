extends SceneTree
## ART-001: draws the style sheet the user signs the art style off against
## (`codexandclaude/tasks/ART-001/style_sheet.png`). A tool, not part of the
## game: run this script with the windowed Godot, `--path game -s` and its
## resource path (tools folder).
## Silhouettes only show line, colour, light and proportion; the real figures
## come from the generated art (ART-002 onward).

const OUT: String = "res://../codexandclaude/tasks/ART-001/style_sheet.png"
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
	colorless(ci, Vector2(520, FLOOR))
	monochrome(ci, Vector2(660, FLOOR))
	tian(ci, Vector2(800, FLOOR))
	overlook(ci, Vector2(1070, FLOOR - 170))
	InkDraw.rough_rect(ci, box, DuskStyle.INK, 2.5, 7, 1.0)
	text(ci, Vector2(36, 54), "样张：荒地 · 黄昏（远景淡紫，中景灰褐，近景纸色地面；角色深墨轮廓）", 22, DuskStyle.PEARL)
	for pair: Array in [[300, "玩家"], [520, "无色实体"], [660, "单色实体"], [800, "天人战士"], [1070, "渴望俯视"]]:
		text(ci, Vector2(float(pair[0]) - 30, FLOOR + 46), String(pair[1]), 20)

## A human figure in ink: head, torso, limbs; paper fill, warm rim on the sun side.
func figure(ci: CanvasItem, feet: Vector2, h: float, fill: Color, seed: int) -> Dictionary:
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
	# Warm rim light on the sun side, cool violet shade on the other.
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

## Colourless: an ink mass with no colour of its own, dripping, one pearl eye.
func colorless(ci: CanvasItem, feet: Vector2) -> void:
	var h: float = PLAYER_H * 0.8
	var c: Vector2 = feet + Vector2(0, -h * 0.5)
	var pts: PackedVector2Array = blob(ci, c, Vector2(h * 0.32, h * 0.5), Color(DuskStyle.INK, 0.88), 200, 0.35)
	stroke(ci, pts + PackedVector2Array([pts[0]]), DuskStyle.INK, 2.0, 201)
	for i: int in range(4):
		var x: float = c.x + (i - 1.5) * 10.0
		InkDraw.rough_line(ci, Vector2(x, feet.y - 4), Vector2(x + 2, feet.y + 8 + i * 3), Color(DuskStyle.INK, 0.7), 2.5, 210 + i)
	ci.draw_circle(c + Vector2(8, -h * 0.22), 3.5, DuskStyle.PEARL)

## Single-colour: a lean ink body edged in one accent colour (violet), built for speed.
func monochrome(ci: CanvasItem, feet: Vector2) -> void:
	var h: float = PLAYER_H * 0.8
	var body: PackedVector2Array = PackedVector2Array([feet + Vector2(-8, 0), feet + Vector2(-16, -h * 0.55), feet + Vector2(-4, -h), feet + Vector2(14, -h * 0.7), feet + Vector2(10, 0)])
	ci.draw_colored_polygon(body, Color(DuskStyle.INK, 0.9))
	stroke(ci, body + PackedVector2Array([body[0]]), DuskStyle.DUSK_TOP, 3.0, 300)
	for i: int in range(3):
		InkDraw.rough_line(ci, feet + Vector2(-24 - i * 10, -h * (0.3 + i * 0.15)), feet + Vector2(-60 - i * 14, -h * (0.3 + i * 0.15)), Color(DuskStyle.DUSK_TOP, 0.6), 2.0, 310 + i)
	ci.draw_circle(feet + Vector2(6, -h * 0.82), 3.0, DuskStyle.DUSK_TOP.lightened(0.4))

## Tian warrior: an armoured ink figure with gold ornaments and a long blade.
func tian(ci: CanvasItem, feet: Vector2) -> void:
	var f: Dictionary = figure(ci, feet, PLAYER_H * 0.8, Color("3a302a"), 400)
	var k: float = f["k"]
	InkDraw.rough_line(ci, f["head"] + Vector2(-10, -10) * k, f["head"] + Vector2(10, -10) * k, DuskStyle.GROWTH, 3.5, 410)
	for s: float in [-1.0, 1.0]:
		InkDraw.paper_disc(ci, f["neck"] + Vector2(15 * s, 4) * k, 6.0 * k, DuskStyle.GROWTH, 420 + int(s))
	stroke(ci, PackedVector2Array([f["neck"] + Vector2(18, 40) * k, f["neck"] + Vector2(30, -40) * k]), DuskStyle.INK, 4.0, 430)
	InkDraw.rough_line(ci, f["neck"] + Vector2(28, -30) * k, f["neck"] + Vector2(31, -44) * k, DuskStyle.GROWTH, 4.0, 431)

## Overlook (Boss, 250%): a hovering eye of ink, vermilion iris looking down.
func overlook(ci: CanvasItem, c: Vector2) -> void:
	var w: float = PLAYER_H * 2.5 * 0.5
	var pts: PackedVector2Array = blob(ci, c, Vector2(w, w * 0.6), Color(DuskStyle.INK, 0.92), 500, 0.08)
	stroke(ci, pts + PackedVector2Array([pts[0]]), DuskStyle.INK, 3.0, 501)
	var lid: PackedVector2Array = PackedVector2Array()
	for i: int in range(17):
		var a: float = PI + PI * i / 16.0
		lid.append(c + Vector2(cos(a) * w * 0.62, sin(a) * w * 0.3))
	for i: int in range(17):
		var a: float = PI * i / 16.0
		lid.append(c + Vector2(cos(a) * w * 0.62, sin(a) * w * 0.22))
	ci.draw_colored_polygon(lid, DuskStyle.PAPER_DAY)
	ci.draw_circle(c + Vector2(-6, 8), w * 0.16, DuskStyle.LIFE)
	ci.draw_circle(c + Vector2(-6, 10), w * 0.07, DuskStyle.INK)
	for i: int in range(5):
		var x: float = c.x - w * 0.6 + i * w * 0.3
		InkDraw.rough_line(ci, Vector2(x, c.y + w * 0.5), Vector2(x + 4, c.y + w * 0.5 + 30 + 20 * InkDraw.noise(i, 5)), Color(DuskStyle.INK, 0.8), 4.0, 510 + i)

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
		"光：黄昏暖光从一侧（左）打来，亮面暖色边光，暗部偏冷紫。",
		"明度：角色深、背景远景浅而淡；生命红与可能性青不做大面积底色。",
		"敌人：无色＝无自身颜色的墨块，单色＝一种强调色，天人＝墨中加金；",
		"　　　Boss 各有标志（渴望俯视＝悬空的眼，寄生同伴者＝口与触须）。",
		"特效沿用 FX-001 / FX-002，不重做；敌人表现不借用玩家的样子。",
	]
	for i: int in range(lines.size()):
		text(ci, at + Vector2(0, 40 + i * 36), lines[i], 19)
