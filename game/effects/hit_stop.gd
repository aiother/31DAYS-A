class_name HitStop
extends RefCounted
## FX-001 hit-stop: an actor that is held skips its own physics step, so its
## body and every timer it owns stay exactly where they are, then carry on.
## Actors call held() first thing in _physics_process. The count goes down
## once per physics frame of that actor, so the pause menu (no physics) and
## anything else that stops the actor freeze the stop as well. Clocks, other
## actors and projectiles are not touched.
const META: StringName = &"fx_hit_stop"
const EPSILON: float = 0.00001

## Starts a stop; an ongoing one is never extended or restarted.
## Returns whether a new stop began.
static func start(actor: Node, seconds: float) -> bool:
	if not is_instance_valid(actor) or seconds <= EPSILON or remaining(actor) > EPSILON:
		return false
	actor.set_meta(META, {"left": seconds, "frame": -1})
	return true

static func remaining(actor: Node) -> float:
	if not is_instance_valid(actor) or not actor.has_meta(META):
		return 0.0
	return float((actor.get_meta(META) as Dictionary)["left"])

## True while the actor must skip this physics step. Safe to call twice in a
## frame (a subclass and its super): the count only goes down once.
static func held(actor: Node, delta: float) -> bool:
	if not actor.has_meta(META):
		return false
	var stop: Dictionary = actor.get_meta(META)
	var frame: int = Engine.get_physics_frames()
	if int(stop["frame"]) == frame:
		return true
	if float(stop["left"]) <= EPSILON:
		actor.remove_meta(META)
		return false
	stop["left"] = maxf(0.0, float(stop["left"]) - delta)
	stop["frame"] = frame
	return true
