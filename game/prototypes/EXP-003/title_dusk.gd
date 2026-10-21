extends "res://prototypes/EXP-003/title_base.gd"
## Variant A · 黄昏远景: a dusk sky over ruined skyline silhouettes, a low sun,
## drifting dust. Title in paper ink across the upper third; menu centred below.

func variant_name() -> String:
	return "A · 黄昏远景"

func menu_container() -> Container:
	var menu: VBoxContainer = VBoxContainer.new()
	menu.position = Vector2(800, 400)
	menu.add_theme_constant_override("separation", 10)
	return menu

func button_tone() -> String:
	return "light"

func _draw() -> void:
	InkDraw.wash(self, Rect2(Vector2.ZERO, size), DuskStyle.DUSK_TOP.darkened(0.35), DuskStyle.DUSK_BOTTOM)
	var sun: Vector2 = Vector2(size.x * 0.5, size.y * 0.66)
	InkDraw.glow(self, sun, 220, DuskStyle.SUN, 1.3 + 0.1 * sin(clock * 0.8))
	draw_circle(sun, 90, Color(DuskStyle.SUN, 0.85))
	_skyline(size.y * 0.72, 0.45, 11, Color(0.30, 0.15, 0.20, 0.75))
	_skyline(size.y * 0.80, 0.75, 29, Color(0.13, 0.07, 0.10, 0.95))
	draw_rect(Rect2(0, size.y * 0.86, size.x, size.y * 0.14), Color(0.07, 0.04, 0.06, 1.0))
	# Low haze over the ruins.
	InkDraw.wash(self, Rect2(0, size.y * 0.55, size.x, size.y * 0.25), Color(DuskStyle.DUSK_BOTTOM, 0.0), Color(DuskStyle.PAPER_DUSK, 0.18))
	for i: int in range(48):
		var x: float = fposmod(InkDraw.noise(i, 5) * size.x + clock * (8.0 + InkDraw.noise(i, 6) * 18.0), size.x)
		var y: float = fposmod(InkDraw.noise(i, 7) * size.y - clock * (4.0 + InkDraw.noise(i, 8) * 6.0), size.y)
		draw_circle(Vector2(x, y), 1.2 + InkDraw.noise(i, 9) * 1.8, Color(DuskStyle.PAPER_DAY, 0.25))
	var title: Rect2 = title_rect()
	ink_text(Vector2(0, title.end.y - 92) + Vector2(4, 5), TITLE, 132, Color(0, 0, 0, 0.35), HORIZONTAL_ALIGNMENT_CENTER, size.x)
	ink_text(Vector2(0, title.end.y - 92), TITLE, 132, DuskStyle.PAPER_DAY, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	InkDraw.rough_line(self, Vector2(size.x * 0.5 - 220, title.end.y - 64), Vector2(size.x * 0.5 + 220, title.end.y - 64), Color(DuskStyle.LIFE, 0.85), 3.0, 41, 1.2)
	ink_text(Vector2(0, title.end.y - 22), "V0.1 灰盒", UiTheme.SIZE_SMALL, Color(DuskStyle.PAPER_DAY, 0.7), HORIZONTAL_ALIGNMENT_CENTER, size.x)
	drawn["title"] = {"text": TITLE, "rect": title, "variant": variant_name()}

## Broken building silhouettes with ragged tops, deterministic per seed.
func _skyline(base: float, height: float, seed: int, color: Color) -> void:
	var x: float = -20.0
	var i: int = 0
	while x < size.x + 40.0:
		var w: float = 60.0 + InkDraw.noise(i, seed) * 90.0
		var h: float = (90.0 + InkDraw.noise(i, seed + 1) * 300.0) * height
		var top: float = base - h
		var broken: float = InkDraw.noise(i, seed + 2) * 40.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, base + 200), Vector2(x, top + broken), Vector2(x + w * 0.4, top), Vector2(x + w * 0.55, top + broken * 0.6), Vector2(x + w, top + broken * 1.4), Vector2(x + w, base + 200)]), color)
		x += w + InkDraw.noise(i, seed + 3) * 20.0
		i += 1
