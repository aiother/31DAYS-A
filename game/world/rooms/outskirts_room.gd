class_name OutskirtsRoom
extends WorldRoom
signal challenge_passed
signal challenge_failed
@export var challenge: SpikeChallengeConfig
@export var dialogue: DialogueConfig
var target: PlayerController
var opened: bool = false
var pending_open: bool = false
var _attempt: bool = false
var _serial: int = -1
var _previous: Vector2

func _ready() -> void:
	super._ready()
	process_physics_priority = 10

func bind_player(player: PlayerController) -> void:
	target = player
	reset_attempt()

func reset_attempt() -> void:
	_attempt = false
	_serial = -1
	if is_instance_valid(target): _previous = target.position

func refresh(open: bool, helped: bool, failed: bool, prompt: bool) -> void:
	opened = open
	$AbilityGate/Visual.visible = false
	$AbilityGate/Label.text = "尖刺已关闭 · 救助通路永久开启" if opened else "强化闪避穿过尖刺 · 建议至少1可能性"
	$Survivor/Prompt.text = ""
	$Survivor/Prompt.visible = prompt and not $Survivor/Prompt.text.is_empty()
	$Survivor/Name.text = "外围幸存者 · 已救助" if helped else ("外围幸存者 · 救助机会已失去" if failed else "外围幸存者")
	$Survivor/VisualRoot/Body.polygon = PackedVector2Array([Vector2(-24,0),Vector2(-24,-80),Vector2(24,-80),Vector2(24,0)]) if helped else PackedVector2Array([Vector2(-36,0),Vector2(-36,-40),Vector2(36,-40),Vector2(36,0)])
	queue_redraw()

func _crosses(from: Vector2, to: Vector2) -> bool:
	# Expand by the player's physical 44x88 body; sweep to reject skipped frames.
	var area: Rect2 = Rect2(challenge.hazard.position-Vector2(22,0),challenge.hazard.size+Vector2(44,88))
	if area.has_point(from) or area.has_point(to): return true
	var corners: Array[Vector2] = [area.position,Vector2(area.end.x,area.position.y),area.end,Vector2(area.position.x,area.end.y)]
	for i: int in range(4):
		if Geometry2D.segment_intersects_segment(from,to,corners[i],corners[(i+1)%4]) != null: return true
	return false

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or not target.life.is_alive() or opened or pending_open:
		reset_attempt()
		return
	var point: Vector2 = target.position
	var crosses: bool = _crosses(_previous,point)
	if crosses or _attempt:
		var action: PlayerPossibility = target.possibility
		var valid: bool = action.dodge_upgraded and action.state==PlayerPossibility.State.DODGE_ACTIVE and action.invincible_remaining>0 and action.dodge_direction>0 and point.x>=_previous.x and point.distance_to(_previous)<=action.config.enhanced_dodge_speed*delta+2
		if not _attempt:
			valid = valid and _previous.x+22<=challenge.hazard.position.x
			_attempt = valid
			_serial = action.dodge_serial
		valid = valid and _attempt and _serial==action.dodge_serial
		if not valid:
			reset_attempt()
			challenge_failed.emit()
		elif point.x-22>=challenge.hazard.end.x:
			pending_open = true
			reset_attempt()
			challenge_passed.emit()
	_previous = target.position

func _draw() -> void:
	draw_rect(config.bounds,Color(0.08,0.09,0.10))
	for x: int in [160,640,1216,2080,2688]:
		draw_colored_polygon(PackedVector2Array([Vector2(x,1280),Vector2(x+120,880),Vector2(x+168,992),Vector2(x+280,1280)]),Color(0.19,0.20,0.20))
	for x: int in [80,2720,2864]:
		draw_line(Vector2(x,1280),Vector2(x+32,1096),Color(0.31,0.32,0.29),6)
		draw_arc(Vector2(x+32,1152),64,0,TAU,24,Color(0.31,0.32,0.29),3)
	if challenge != null and not opened:
		for x: float in range(int(challenge.hazard.position.x),int(challenge.hazard.end.x),16):
			draw_colored_polygon(PackedVector2Array([Vector2(x,848),Vector2(x+8,802),Vector2(x+16,848)]),Color(0.85,0.35,0.18))
		draw_line(Vector2(2180,848),Vector2(2200,848),Color(0.9,0.8,0.3),5)
