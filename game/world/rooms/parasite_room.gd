class_name ParasiteRoom
extends WorldRoom
var opened: bool = false

func clear_projectiles() -> void:
	for child: Node in $Enemies.get_children():
		child.set_physics_process(false)
		child.queue_free()

func set_opened(value: bool, animate: bool = false) -> void:
	var changed: bool = opened != value
	opened = value
	if value and changed and animate:
		var falling: Polygon2D = Polygon2D.new()
		falling.name = "FallingBoards"
		falling.polygon = $Boards.polygon
		falling.color = $Boards.color
		falling.position = $Boards.position
		add_child(falling)
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(falling,"position",falling.position+Vector2(-32,300),0.65)
		tween.tween_property(falling,"rotation",0.6,0.65)
		tween.tween_property(falling,"modulate:a",0.0,0.65)
		tween.chain().tween_callback(falling.queue_free)
	$Boards.visible = not value
	$Corpse.visible = not value
	$ExitLabel.text = "木板已落下 · 通往逆时战场" if value else "击败寄生同伴者后开启"
	queue_redraw()

func _draw() -> void:
	draw_rect(config.bounds,Color(0.065,0.06,0.075))
	for x: int in [80,400,720,1040,1360,1680,1840]:
		draw_line(Vector2(x,120),Vector2(x,1536),Color(0.16,0.17,0.18),9)
	if opened:
		draw_rect(Rect2(1480,816,144,240),Color(0.018,0.023,0.028))
