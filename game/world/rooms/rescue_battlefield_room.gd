class_name RescueBattlefieldRoom
extends BattlefieldRoom
signal rescue_requested(reason: String)
signal hostile_spawned(actor: ColorlessEntity)
enum Phase { OPENING, RESCUE, COOP }
const TEN: PackedScene = preload("res://allies/ten_fighter.tscn")
const WARRIOR: PackedScene = preload("res://enemies/tian_warrior.tscn")
const MONO: PackedScene = preload("res://enemies/monochrome_entity.tscn")
var phase: Phase = Phase.OPENING
var rescue_done: bool = false
var rescue_reason: String = ""
var ten: TenFighter
var _loss_check_queued: bool = false

func _ready() -> void:
	super._ready()
	$StageLabel.text = "中心战场 · 首次危机\n守住阵线，等待援手\n10救场后进入协同测试"

func _on_tian_defeated(reward: int) -> void:
	if phase==Phase.OPENING:
		super._on_tian_defeated(reward)

func _physics_process(delta: float) -> void:
	if phase==Phase.RESCUE:
		return
	if rescue_done and phase==Phase.OPENING and is_instance_valid(target):
		start_coop(true)
	super._physics_process(delta)
	if phase==Phase.COOP and started and not stopped and is_instance_valid(ten):
		ten.set_physics_process(true)
	if phase==Phase.OPENING and arrivals==2 and not stopped and not _loss_check_queued:
		# Settle non-lethal triggers after this physics frame, allowing a lethal hit first.
		_loss_check_queued = true
		_check_losses.call_deferred()

func _check_losses() -> void:
	_loss_check_queued = false
	if phase!=Phase.OPENING or stopped or arrivals!=2:
		return
	for child: Node in $Allies.get_children():
		if (child as SurvivorFighter).health>0:
			return
	rescue_requested.emit("allies_lost")

func _spawn_ten() -> void:
	if is_instance_valid(ten):
		return
	ten = TEN.instantiate() as TenFighter
	ten.opponents = $Enemies
	ten.position = Vector2(clampf(target.position.x+160,300,1700),896)
	$Allies.add_child(ten)
	ten.set_physics_process(false)

func begin_rescue(reason: String) -> void:
	phase = Phase.RESCUE
	rescue_reason = reason
	stop_attempt()
	_spawn_ten()
	ten.get_node("HealthLabel").text = "10 · 登场"
	for child: Node in $Enemies.get_children():
		if child is ColorlessEntity:
			var enemy: ColorlessEntity = child as ColorlessEntity
			# Scripted time stop overrides attacks explicitly; no stagger meter is granted.
			enemy._interrupt_action()
			enemy._release_slot()
			if enemy.health>0:
				enemy.state = ColorlessEntity.State.IDLE
			enemy.velocity = Vector2.ZERO
			enemy.hurtbox.accepts_hits = false
			enemy._update_status_label()
			enemy.visual.queue_redraw()
			for audio: Node in enemy.visual.get_children():
				if audio is AudioStreamPlayer:
					(audio as AudioStreamPlayer).stop()

func clear_hostiles() -> void:
	for child: Node in $Enemies.get_children():
		if child is ColorlessEntity and (child as ColorlessEntity).health>0:
			var enemy: ColorlessEntity = child as ColorlessEntity
			# The cinematic kill bypasses dodge/guard; ordinary player damage does not.
			enemy._on_hit(enemy.health,Vector2.ZERO,ten,0)

func replace_wave() -> void:
	for child: Node in $Enemies.get_children():
		$Enemies.remove_child(child)
		child.queue_free()
	for i: int in range(3):
		var enemy: ColorlessEntity = (WARRIOR if i<2 else MONO).instantiate() as ColorlessEntity
		enemy.position = Vector2(1050+i*270,896)
		enemy.target = target
		enemy.coordinator = $AttackCoordinator
		if enemy is TianWarrior:
			(enemy as TianWarrior).flank_side = -1 if i==0 else 1
		$Enemies.add_child(enemy)
		enemy.set_physics_process(false)
		hostile_spawned.emit(enemy)

func start_coop(use_current_wave: bool = false) -> void:
	rescue_done = true
	phase = Phase.COOP
	if not use_current_wave:
		replace_wave()
	_spawn_ten()
	ten.position.y = 896
	arrivals = 2
	arrival_remaining = -1
	completed = false
	stopped = false
	started = not use_current_wave
	for child: Node in $Enemies.get_children():
		if child is ColorlessEntity:
			child.set_physics_process(started)
	for child: Node in $Allies.get_children():
		if (child as SurvivorFighter).health>0:
			child.set_physics_process(started)
	$StageLabel.text = "10加入战斗 · 协同测试\n本轮清空仅提示阶段完成\n最终波次、计时与结局待下一阶段"
