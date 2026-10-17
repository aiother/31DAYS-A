class_name FinalBattlefieldRoom
extends RescueBattlefieldRoom
signal battle_started
signal wave_changed(index: int)
const PLATFORM: PackedScene = preload("res://world/scenes/platform.tscn")
@export var battle: FinalBattleConfig
enum WaveState { ACTIVE, WARNING, COMPLETE }
var wave_index: int = 0
var wave_state: WaveState = WaveState.ACTIVE
var wave_remaining: float = 0
var battle_announced: bool = false
var victory: bool = false
var final_support_spawned: bool = false

func _physics_process(delta: float) -> void:
	if victory:
		return
	if phase==Phase.COOP and wave_state==WaveState.WARNING:
		if not is_instance_valid(target) or not target.life.is_alive():
			return
		wave_remaining = maxf(0,wave_remaining-delta)
		if wave_remaining==0:
			_begin_wave()
		return
	super._physics_process(delta)
	if phase==Phase.COOP and started and not stopped and not battle_announced:
		battle_announced = true
		battle_started.emit()

func _on_tian_defeated(reward: int) -> void:
	if phase==Phase.OPENING:
		super._on_tian_defeated(reward)
	elif phase==Phase.COOP and wave_state==WaveState.ACTIVE and arrivals==0 and not stopped:
		_spawn_ally()
		arrival_remaining = reinforcement_gap

func replace_wave() -> void:
	for child: Node in $Enemies.get_children():
		$Enemies.remove_child(child)
		child.queue_free()
	var total: int = battle.tian_counts[wave_index]+battle.mono_counts[wave_index]
	for i: int in range(total):
		var enemy: ColorlessEntity = (WARRIOR if i<battle.tian_counts[wave_index] else MONO).instantiate() as ColorlessEntity
		enemy.position = Vector2(960+i*minf(160,800.0/maxi(1,total-1)),896)
		enemy.target = target
		enemy.coordinator = $AttackCoordinator
		if enemy is TianWarrior:
			(enemy as TianWarrior).flank_side = -1 if i%2==0 else 1
			enemy.defeated.connect(_on_tian_defeated)
		$Enemies.add_child(enemy)
		enemy.set_physics_process(false)
		hostile_spawned.emit(enemy)

func start_coop(use_current_wave: bool = false) -> void:
	wave_index = 0
	wave_state = WaveState.ACTIVE
	super.start_coop(use_current_wave)
	arrivals = 0
	arrival_remaining = -1
	_update_wave_label()

func advance_wave() -> bool:
	if wave_index+1>=battle.tian_counts.size():
		wave_state = WaveState.COMPLETE
		return false
	wave_index += 1
	wave_state = WaveState.WARNING
	wave_remaining = battle.wave_warning
	completed = false
	$StageLabel.text = "本波清空 · 下一波敌人即将进入"
	wave_changed.emit(wave_index)
	return true

func _begin_wave() -> void:
	replace_wave()
	wave_state = WaveState.ACTIVE
	stopped = false
	completed = false
	started = true
	arrivals = 0
	arrival_remaining = -1
	if wave_index==battle.tian_counts.size()-1 and not final_support_spawned:
		final_support_spawned = true
		for i: int in range(battle.last_wave_allies):
			var ally: SurvivorFighter = ALLY.instantiate() as SurvivorFighter
			ally.opponents = $Enemies
			ally.position = Vector2(360+i*90,896)
			$Allies.add_child(ally)
		for point: Vector2 in battle.platform_positions:
			var platform: Node2D = PLATFORM.instantiate() as Node2D
			platform.position = point
			$FinalPlatforms.add_child(platform)
	for child: Node in $Enemies.get_children():
		child.set_physics_process(true)
	for child: Node in $Allies.get_children():
		if (child as SurvivorFighter).health>0:
			child.set_physics_process(true)
	_update_wave_label()

func _update_wave_label() -> void:
	$StageLabel.text = "最终战 · 第%d / %d波\n每波击败首名天人后两批幸存者加入" % [wave_index+1,battle.tian_counts.size()]

func set_victory() -> void:
	victory = true
	completed = false
	phase = Phase.COOP
	stop_attempt()
	for child: Node in $Enemies.get_children():
		$Enemies.remove_child(child)
		child.queue_free()
	_spawn_ten()
	ten.position = Vector2(960,896)
	$LeftBoundary.collision_layer = 0
	$LeftBoundary/GateVisual.hide()
	$ReturnLabel.text = "返回道路已开放"
	$StageLabel.text = "最终战胜利\n靠近10按 E / RB 对话"
