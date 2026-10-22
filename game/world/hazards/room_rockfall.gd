class_name RoomRockfall
extends Node2D
## Non-solid presentation and rocks: never adds a movement or exit lock.
var config: RoomRockfallConfig
var target: PlayerController
var disabled: bool = false
var warning_remaining: float = 0
var next_warning: float = 0
var warning_active: bool = false
var prompt: Label
var rocks: Node2D

func _ready() -> void:
	add_to_group("navigation_transients")
	rocks = Node2D.new()
	rocks.name = "Rocks"
	add_child(rocks)
	prompt = Label.new()
	prompt.position = config.switch_position+Vector2(-136,-100)
	prompt.add_theme_font_size_override("font_size",20)
	add_child(prompt)
	prompt.hide()
	queue_redraw()

func can_interact(player: PlayerController) -> bool:
	return not disabled and is_instance_valid(player) and player.life.can_control() and not player.possibility.busy() and not player.combat.is_attacking() and (player.global_position+Vector2(0,-44)).distance_to(to_global(config.switch_position))<=config.interaction_radius

func refresh(player: PlayerController, events: Dictionary) -> void:
	target = player
	var stopped: bool = bool(events.get(config.persistence_key,false))
	if stopped!=disabled:
		disabled = stopped
		clear_rocks()
	prompt.visible = disabled and is_instance_valid(player) and (player.global_position+Vector2(0,-44)).distance_to(to_global(config.switch_position))<=config.interaction_radius
	prompt.text = "落石已永久关闭" if disabled else ""
	queue_redraw()

func clear_rocks() -> void:
	for child: Node in rocks.get_children():
		child.set_physics_process(false)
		child.queue_free()
	warning_active = false
	warning_remaining = 0
	next_warning = 0
	queue_redraw()

func _physics_process(delta: float) -> void:
	if disabled or not is_instance_valid(target) or not target.life.is_alive() or not config.active_bounds.has_point(to_local(target.global_position)):
		if warning_active or rocks.get_child_count()>0 or next_warning>0:
			clear_rocks()
		return
	next_warning = maxf(0,next_warning-delta)
	if warning_active:
		warning_remaining = maxf(0,warning_remaining-delta)
		if warning_remaining==0:
			var rock: FallingRock = FallingRock.new()
			rock.position = Vector2(config.lane,config.spawn_y)
			rock.damage = config.damage
			rock.speed = config.speed
			rock.lifetime = (config.floor_y-config.spawn_y)/config.speed+1.0
			rocks.add_child(rock)
			warning_active = false
	if not warning_active and next_warning==0:
		warning_active = true
		warning_remaining = config.warning
		next_warning = config.interval
	queue_redraw()

func _draw() -> void:
	if config==null: return
	var point: Vector2 = config.switch_position
	draw_rect(Rect2(point+Vector2(-14,-28),Vector2(28,64)),Color(0.48,0.5,0.52))
	draw_line(point,point+Vector2(28 if disabled else -28,-28),Color(0.55,0.9,0.65) if disabled else Color(0.95,0.78,0.35),7)
	if not disabled:
		draw_line(Vector2(config.lane-28,config.floor_y-2),Vector2(config.lane+28,config.floor_y-2),Color(0.65,0.46,0.25),4)
	if warning_active:
		draw_line(Vector2(config.lane,config.spawn_y),Vector2(config.lane,config.floor_y),Color(1,0.45,0.15,0.5),4)
		draw_circle(Vector2(config.lane,config.floor_y-8),30,Color(1,0.45,0.15,0.5))
