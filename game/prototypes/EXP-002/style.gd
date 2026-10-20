extends RefCounted
## EXP-002 visual direction: 甲（褪色手札）as the base with 丙（黄昏余辉）texture.
## The dusk amount grows as doom approaches; key colours never change so that
## life, possibility and warnings stay readable on every day.
const Ink = preload("res://prototypes/EXP-002/ink.gd")

const SAMPLES: Array[String] = [
	"样张一 · 手札为主（甲的纸与墨为底，丙的光只落在关键处）",
	"样张二 · 黄昏为主（丙的渐变与玻璃感，甲的墨线点缀）",
]
# Key colours: identical in both samples and on every day.
const LIFE: Color = Color("b8382c")
const POSSIBILITY: Color = Color("2f8f88")
const POSSIBILITY_GLOW: Color = Color("9fe6d6")
const GROWTH: Color = Color("d9a03a")
const OVERDRAFT: Color = Color("6e1f3a")
const DENY: Color = Color("ff4636")
const INK: Color = Color("2b2420")
const PEARL: Color = Color("fbf6ec")
# Mood colours: these are what the dusk amount moves.
const PAPER_DAY: Color = Color("efe4cc")
const PAPER_DUSK: Color = Color("f0cfb6")
const DUSK_TOP: Color = Color("7d4a8c")
const DUSK_BOTTOM: Color = Color("f0a050")
const SUN: Color = Color("f4b860")
## Per-day dusk ranges (start of day, end of day); final battle is 1.0.
const DAY_RANGE: Array[Vector2] = [Vector2.ZERO, Vector2(0.0, 0.25), Vector2(0.35, 0.6), Vector2(0.7, 0.95)]
const FIXED_DUSK: float = 0.5
const FINAL_GLOW_SCALE: float = 0.7

var sample: int = 0
var progressive: bool = true

func title() -> String:
	return SAMPLES[sample]

## 0 = plain paper daylight, 1 = full dusk. Sample one moves within a narrower band.
func dusk(state: RefCounted) -> float:
	var amount: float = FIXED_DUSK
	if progressive:
		if state.final_active:
			amount = 1.0
		else:
			var span: Vector2 = DAY_RANGE[clampi(state.day, 1, 3)]
			amount = lerpf(span.x, span.y, state.day_progress())
	return amount * (0.55 if sample == 0 else 1.0)

func paper_color(state: RefCounted) -> Color:
	return PAPER_DAY.lerp(PAPER_DUSK, dusk(state))

func panel_alpha() -> float:
	return 0.94 if sample == 0 else 0.78

## How much of the dusk gradient lies over paper panels (glass feel).
func glass(state: RefCounted) -> float:
	return 0.0 if sample == 0 else 0.35 + 0.5 * dusk(state)

func glow_strength(state: RefCounted) -> float:
	var strength: float = (0.35 + 0.65 * dusk(state)) * (0.7 if sample == 0 else 1.0)
	# User G4 (2026-10-20): the final battle's dusk glow about 30% softer.
	return strength * (FINAL_GLOW_SCALE if state.final_active else 1.0)

## Slow breathing pulse, stronger at dusk (丙).
func breath(state: RefCounted) -> float:
	return 1.0 + sin(state.clock * 1.3) * 0.25 * dusk(state)

func ink_width() -> float:
	return 2.6 if sample == 0 else 1.7

func wobble() -> float:
	return 1.8 if sample == 0 else 0.7

func edge_wash(state: RefCounted) -> float:
	return dusk(state) * (0.25 if sample == 0 else 0.45)

func panel(ci: CanvasItem, rect: Rect2, state: RefCounted, seed: int) -> void:
	Ink.paper(ci, rect, Color(paper_color(state), panel_alpha()), seed, wobble(), 24 if sample == 0 else 8)
	var g: float = glass(state)
	if g > 0.0:
		Ink.wash(ci, rect.grow(-2.0), Color(DUSK_TOP, 0.45 * g), Color(DUSK_BOTTOM, 0.4 * g))
	Ink.rough_rect(ci, rect, Color(INK, 0.85), ink_width(), seed, wobble())
