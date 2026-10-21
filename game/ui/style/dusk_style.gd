class_name DuskStyle
extends RefCounted
## Formal visual direction chosen in EXP-002 (sample two, dusk-led): paper and
## ink with a dusk gradient that deepens as doom approaches. Key colours never
## change; only mood (paper tint, glass, glow, edge wash) follows the dusk.
##
## Time input is a Dictionary shaped like FinalBattleSession.ui_time_state()
## (SYS-005): "day" (1-3), "day_progress" (0-1), "final_active" (bool).

# Key colours: identical on every day.
const LIFE: Color = Color("b8382c")
const POSSIBILITY: Color = Color("2f8f88")
const POSSIBILITY_GLOW: Color = Color("9fe6d6")
const GROWTH: Color = Color("d9a03a")
const OVERDRAFT: Color = Color("6e1f3a")
const DENY: Color = Color("ff4636")
const INK: Color = Color("2b2420")
const PEARL: Color = Color("fbf6ec")
# Mood colours: moved by the dusk amount.
const PAPER_DAY: Color = Color("efe4cc")
const PAPER_DUSK: Color = Color("f0cfb6")
const DUSK_TOP: Color = Color("7d4a8c")
const DUSK_BOTTOM: Color = Color("f0a050")
const SUN: Color = Color("f4b860")
## Per-day dusk range (start of day, end of day); the final battle is 1.0.
const DAY_RANGE: Array[Vector2] = [Vector2.ZERO, Vector2(0.0, 0.25), Vector2(0.35, 0.6), Vector2(0.7, 0.95)]
## User G4 (EXP-002): the final battle's dusk glow about 30% softer.
const FINAL_GLOW_SCALE: float = 0.7
const PANEL_ALPHA: float = 0.78
const INK_WIDTH: float = 1.7
const WOBBLE: float = 0.7

## 0 = plain paper daylight, 1 = full dusk.
static func dusk(time: Dictionary) -> float:
	if bool(time.get("final_active", false)):
		return 1.0
	var span: Vector2 = DAY_RANGE[clampi(int(time.get("day", 1)), 1, 3)]
	return lerpf(span.x, span.y, clampf(float(time.get("day_progress", 0.0)), 0.0, 1.0))

static func paper_color(time: Dictionary) -> Color:
	return PAPER_DAY.lerp(PAPER_DUSK, dusk(time))

## How much of the dusk gradient lies over paper panels (glass feel).
static func glass(time: Dictionary) -> float:
	return 0.35 + 0.5 * dusk(time)

static func glow_strength(time: Dictionary) -> float:
	var strength: float = 0.35 + 0.65 * dusk(time)
	return strength * (FINAL_GLOW_SCALE if bool(time.get("final_active", false)) else 1.0)

## Slow breathing pulse, stronger at dusk.
static func breath(time: Dictionary, clock: float) -> float:
	return 1.0 + sin(clock * 1.3) * 0.25 * dusk(time)

static func edge_wash(time: Dictionary) -> float:
	return dusk(time) * 0.45

## A paper tag: irregular sheet, dusk glass over it, ink outline.
static func panel(ci: CanvasItem, rect: Rect2, time: Dictionary, seed: int) -> void:
	InkDraw.paper(ci, rect, Color(paper_color(time), PANEL_ALPHA), seed, WOBBLE, 8)
	var g: float = glass(time)
	InkDraw.wash(ci, rect.grow(-2.0), Color(DUSK_TOP, 0.45 * g), Color(DUSK_BOTTOM, 0.4 * g))
	InkDraw.rough_rect(ci, rect, Color(INK, 0.85), INK_WIDTH, seed, WOBBLE)
