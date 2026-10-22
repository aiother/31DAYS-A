class_name ConnectionRoom
extends WorldRoom
@export var return_key: String = "gate:HD_10003_1:return"
@export var forward_key: String = "gate:HD_10003_1:forward"
@export var interaction_radius: float = 88.0
var return_open: bool = false
var forward_open: bool = false

func refresh(player: PlayerController, events: Dictionary, cleared: bool) -> void:
	return_open = bool(events.get(return_key, false))
	forward_open = bool(events.get(forward_key, false))
	$ReturnLabel.text = "返回通路已开启" if return_open else "清敌后可返回"
	$ExitLabel.text = "前路已开启" if forward_open else "机关尚未开启"
	var nearby: bool = (player.global_position + Vector2(0, -44)).distance_to($Switch.global_position) <= interaction_radius
	$Switch/Prompt.text = "已开启" if forward_open else ("" if cleared else "需要先清敌")
	$Switch/Prompt.visible = nearby and not $Switch/Prompt.text.is_empty()
	queue_redraw()

func _draw() -> void:
	draw_rect(config.bounds, Color(0.06, 0.08, 0.10))
	for x: int in [96, 416, 960, 1312]:
		draw_rect(Rect2(x, 240, 48, 656), Color(0.12, 0.145, 0.16))
	for gate: Vector2 in [Vector2(48, 896), Vector2(1488, 896)]:
		var opened: bool = return_open if gate.x < 100 else forward_open
		var color: Color = Color(0.4, 0.75, 0.55) if opened else Color(0.75, 0.4, 0.28)
		draw_line(gate, gate + Vector2(0, -200), color, 6)
	draw_rect(Rect2(1170, 804, 28, 92), Color(0.48, 0.5, 0.52))
	draw_line(Vector2(1184, 826), Vector2(1216 if forward_open else 1152, 800), Color(0.85, 0.8, 0.5), 8)
