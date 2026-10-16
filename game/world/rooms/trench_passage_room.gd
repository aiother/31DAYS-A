class_name TrenchPassageRoom
extends WorldRoom
signal challenge_requested
const CLEARED: String = "gate:NSZC_10002_2:cleared"
const CHALLENGE: String = "gate:NSZC_10002_2:challenge"
const FORWARD: String = "gate:NSZC_10002_2:forward"
@export var rockfall: RockfallConfig
var target: PlayerController
var return_open: bool = false
var challenge_saved: bool = false
var forward_open: bool = false
var challenge_armed: bool = false
var challenge_earned: bool = false
var warning_lane: int = -1
var next_lane: int = 0
var warning_remaining: float = 0
var next_warning: float = 0
@onready var rubble: RubbleBarrier = $Rubble

func refresh(events: Dictionary) -> void:
	return_open = bool(events.get(CLEARED,false))
	challenge_saved = bool(events.get(CHALLENGE,false))
	forward_open = bool(events.get(FORWARD,false))
	$ReturnGate/CollisionShape2D.set_deferred("disabled",return_open)
	$ReturnGate/GateVisual.visible = not return_open
	$ReturnLabel.text = "返回通路已开启" if return_open else "清敌后返回"
	rubble.refresh(return_open and challenge_saved,forward_open)
	queue_redraw()

func clear_rocks() -> void:
	for rock: Node in $Rocks.get_children():
		rock.set_physics_process(false)
		rock.queue_free()
	warning_lane = -1
	warning_remaining = 0
	next_warning = 0
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or not target.life.is_alive():
		clear_rocks()
		return
	var active: bool = rockfall.active_bounds.has_point(target.position)
	if not active:
		clear_rocks()
		challenge_armed = false
		return
	if not challenge_saved and not challenge_earned:
		if _currently_overlaps($ChallengeStart,target):
			challenge_armed = true
		if challenge_armed and _currently_overlaps($ChallengeEnd,target):
			challenge_earned = true
			challenge_requested.emit()
	next_warning = maxf(0,next_warning-delta)
	if warning_lane>=0:
		warning_remaining = maxf(0,warning_remaining-delta)
		if warning_remaining==0:
			var rock: FallingRock = FallingRock.new()
			rock.position = Vector2(rockfall.lanes[warning_lane],rockfall.spawn_y)
			rock.damage = rockfall.damage
			rock.speed = rockfall.speed
			$Rocks.add_child(rock)
			next_lane = (warning_lane+1)%rockfall.lanes.size()
			warning_lane = -1
	if warning_lane<0 and next_warning==0:
		warning_lane = next_lane
		warning_remaining = rockfall.warning
		next_warning = rockfall.interval
	queue_redraw()

func _draw() -> void:
	draw_rect(config.bounds,Color(0.065,0.065,0.07))
	for x: int in [48,784,1840]:
		draw_rect(Rect2(x,160,48,1888),Color(0.15,0.14,0.13))
	for y: int in [384,944,1504]:
		draw_line(Vector2(64,y),Vector2(1856,y-24),Color(0.24,0.21,0.18),5)
	if rockfall != null:
		for x: float in rockfall.lanes:
			draw_line(Vector2(x-24,rockfall.floor_y),Vector2(x+24,rockfall.floor_y),Color(0.6,0.4,0.25),3)
		if warning_lane>=0:
			var x: float = rockfall.lanes[warning_lane]
			draw_line(Vector2(x,rockfall.spawn_y),Vector2(x,rockfall.floor_y),Color(1,0.45,0.15,0.4),4)
			draw_circle(Vector2(x,rockfall.floor_y-8),28,Color(1,0.45,0.15,0.5))
