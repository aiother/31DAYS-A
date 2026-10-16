class_name RubbleBarrier
extends StaticBody2D
signal break_requested
@export var max_health: int = 10
var health: int = 10
var unlocked: bool = false
var broken: bool = false
var pending_break: bool = false
@onready var hurtbox: CombatHurtbox = $Hurtbox

func _ready() -> void:
	health = max_health
	hurtbox.hit_received.connect(_on_hit)
	refresh(false,false)

func refresh(can_attack: bool, opened: bool) -> void:
	unlocked = can_attack
	broken = opened
	hurtbox.accepts_hits = unlocked and not broken and not pending_break
	$CollisionShape2D.set_deferred("disabled",broken)
	$Label.text = "前路已开启" if broken else ("已打碎·E / RB重试保存" if pending_break else ("攻击打碎碎石堆 %d/%d" % [health,max_health] if unlocked else "需清敌并通过落石通道"))
	queue_redraw()

func _on_hit(damage: int, _impulse: Vector2, _source: Node2D, _id: int) -> void:
	if not unlocked or broken or pending_break or damage<=0:
		return
	health = maxi(0,health-damage)
	if health==0:
		pending_break = true
		break_requested.emit()
	refresh(unlocked,broken)

func _draw() -> void:
	if broken:
		for i: int in range(4):
			draw_circle(Vector2(-24+i*16,-5),9,Color(0.4,0.35,0.29))
		return
	draw_colored_polygon(PackedVector2Array([Vector2(-32,0),Vector2(-28,-320),Vector2(4,-360),Vector2(32,-288),Vector2(32,0)]),Color(0.38,0.33,0.27))
	for y: int in [40,120,200,280]:
		draw_line(Vector2(-28,-y),Vector2(28,-y-24),Color(0.65,0.55,0.42),3)
