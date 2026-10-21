extends "res://prototypes/EXP-003/title_base.gd"
## Variant B · 纸页水墨: the whole screen is a dusk-tinted paper page with a
## faint ink-wash sketch of ruins and soft light spots; ink title at the top,
## the menu written down the lower left like a table of contents.

func variant_name() -> String:
	return "B · 纸页水墨"

func menu_container() -> Container:
	var menu: VBoxContainer = VBoxContainer.new()
	menu.position = Vector2(250, 560)
	menu.add_theme_constant_override("separation", 6)
	return menu

func _draw() -> void:
	InkDraw.paper(self, Rect2(Vector2.ZERO, size), DuskStyle.paper_color(MOOD), 61, 0.0, 40)
	InkDraw.wash(self, Rect2(Vector2.ZERO, size), Color(DuskStyle.DUSK_TOP, 0.18), Color(DuskStyle.DUSK_BOTTOM, 0.22))
	# Soft light spots drifting slowly, like late sun through dust.
	for i: int in range(9):
		var at: Vector2 = Vector2(fposmod(InkDraw.noise(i, 62) * size.x + clock * 6.0 * (InkDraw.noise(i, 63) - 0.5), size.x), InkDraw.noise(i, 64) * size.y)
		InkDraw.glow(self, at, 40.0 + InkDraw.noise(i, 65) * 70.0, DuskStyle.SUN, 0.5 + 0.2 * sin(clock + i))
	# Ink-wash ruins on the right half of the page.
	var base: float = size.y * 0.82
	for i: int in range(9):
		var x: float = size.x * 0.48 + i * 105.0
		var h: float = 120.0 + InkDraw.noise(i, 66) * 320.0
		var outline: Rect2 = Rect2(x, base - h, 70.0 + InkDraw.noise(i, 67) * 40.0, h)
		draw_rect(outline, Color(DuskStyle.INK, 0.06 + InkDraw.noise(i, 68) * 0.05))
		InkDraw.rough_rect(self, outline, Color(DuskStyle.INK, 0.35), 1.6, 70 + i, 1.8)
		for w: int in range(3):
			draw_rect(Rect2(outline.position + Vector2(14, 30 + w * 52), Vector2(16, 22)), Color(DuskStyle.INK, 0.12))
	InkDraw.rough_line(self, Vector2(size.x * 0.45, base), Vector2(size.x - 60, base), Color(DuskStyle.INK, 0.6), 2.4, 80, 1.6)
	var title: Rect2 = title_rect()
	ink_text(Vector2(0, title.end.y - 96), TITLE, 132, DuskStyle.INK, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	# A vermilion seal beside the title.
	var seal: Rect2 = Rect2(size.x * 0.5 + 360, title.end.y - 214, 70, 70)
	draw_rect(seal, Color(DuskStyle.LIFE, 0.85))
	ink_text(seal.position + Vector2(0, 47), "末日", 26, DuskStyle.PAPER_DAY, HORIZONTAL_ALIGNMENT_CENTER, seal.size.x)
	ink_text(Vector2(0, title.end.y - 40), "V0.1 灰盒", UiTheme.SIZE_SMALL, Color(DuskStyle.INK, 0.6), HORIZONTAL_ALIGNMENT_CENTER, size.x)
	# Table-of-contents rule beside the menu.
	InkDraw.rough_line(self, Vector2(226, 560), Vector2(226, 560 + buttons.size() * 64), Color(DuskStyle.LIFE, 0.6), 2.0, 81, 1.0)
	drawn["title"] = {"text": TITLE, "rect": title, "variant": variant_name()}
