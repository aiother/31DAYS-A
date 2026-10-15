extends Node2D
## Replace only this visual subtree when integrating Spine.
@onready var player: PlayerController = get_parent() as PlayerController
@onready var sprite: Sprite2D = $PlaceholderSprite
@onready var combat: PlayerCombat = get_parent().get_node("GameplayRoot/Combat") as PlayerCombat
var _hit_sound: AudioStreamPlayer
var _feedback: Tween
var _pulse: float = 0.0
var _hurt_flash: float = 0.0
var _reward_flash: float = 0.0
var _last_balance: int = 3
@onready var life: PlayerLife = get_parent().get_node("GameplayRoot/Life") as PlayerLife
@onready var actions: PlayerPossibility = get_parent().get_node("GameplayRoot/Possibility") as PlayerPossibility

func _ready() -> void:
	player.landed.connect(_on_landed)
	player.facing_changed.connect(_on_facing_changed)
	_hit_sound = AudioStreamPlayer.new()
	_hit_sound.stream = _make_hit_sound()
	_hit_sound.volume_db = -16.0
	add_child(_hit_sound)
	combat.hit_confirmed.connect(_on_hit_confirmed)
	life.damaged.connect(_on_damaged)
	life.died.connect(_on_died)
	life.respawned.connect(_on_respawned)
	_last_balance = actions.balance
	actions.balance_changed.connect(_on_balance_changed)

func _on_balance_changed(current: int, _maximum: int) -> void:
	if current > _last_balance:
		_reward_flash = 0.35
	_last_balance = current

func _on_damaged(_amount: int, _impulse: Vector2) -> void:
	_hurt_flash = 0.2

func _on_died() -> void:
	if _feedback != null and _feedback.is_valid():
		_feedback.kill()
	sprite.scale = Vector2.ONE
	_feedback = create_tween()
	_feedback.tween_property(sprite, "rotation", -PI * 0.5, 0.18)
	_feedback.parallel().tween_property(sprite, "position:y", -18.0, 0.18)

func _on_respawned() -> void:
	if _feedback != null and _feedback.is_valid():
		_feedback.kill()
	sprite.scale = Vector2.ONE
	sprite.rotation = 0.0
	sprite.position = Vector2(0, -48)
	_hurt_flash = 0.0

func _make_hit_sound() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var samples: int = 1764
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(samples * 2)
	for i: int in range(samples):
		var t: float = float(i) / float(stream.mix_rate)
		var envelope: float = (1.0 - float(i) / float(samples)) * minf(float(i) / 32.0, 1.0)
		var value: int = int(sin(TAU * (700.0 * t - 2200.0 * t * t)) * envelope * 16000.0)
		bytes.encode_s16(i * 2, value)
	stream.data = bytes
	return stream

func _on_hit_confirmed(_target: CombatHurtbox, _damage: int, _impulse: Vector2) -> void:
	_hit_sound.play()

func _process(delta: float) -> void:
	_hurt_flash = maxf(0.0, _hurt_flash - delta)
	_reward_flash = maxf(0.0, _reward_flash - delta)
	sprite.modulate = Color(1, 0.4, 0.35) if _hurt_flash > 0.0 else Color.WHITE
	sprite.modulate.a = 0.45 if life.is_alive() and life.protection_remaining > 0.0 and int(Time.get_ticks_msec() / 90) % 2 == 0 else 1.0
	if player.possibility.state == PlayerPossibility.State.HEALING:
		sprite.modulate = Color(0.5, 1.0, 0.65)
	elif player.possibility.busy():
		sprite.modulate = Color(1.0, 0.7, 0.35) if player.possibility.poor_dodge else Color(0.5, 0.85, 1.0)
		if player.possibility.invincible_remaining > 0.0:
			sprite.modulate.a = 0.45
	_pulse = maxf(0.0, _pulse - delta * 2.8)
	queue_redraw()

func _on_facing_changed(direction: float) -> void:
	sprite.flip_h = direction < 0.0

func _on_landed(_impact_speed: float, hard: bool) -> void:
	if not life.is_alive():
		return
	if _feedback != null and _feedback.is_valid():
		_feedback.kill()
	sprite.scale = Vector2(1.25, 0.72) if hard else Vector2(1.12, 0.87)
	_pulse = 1.0 if hard else 0.5
	_feedback = create_tween()
	_feedback.tween_property(sprite, "scale", Vector2.ONE, player.movement.hard_landing_duration if hard else 0.12)

func _draw() -> void:
	if _reward_flash > 0.0:
		draw_arc(Vector2(0, -48), 55.0 + (0.35 - _reward_flash) * 100.0, 0, TAU, 32, Color(0.5, 1.0, 0.65, _reward_flash / 0.35), 3.0)
	if combat != null and combat.is_attacking():
		var shape: RectangleShape2D = combat.hit_shape.shape as RectangleShape2D
		var rect: Rect2 = Rect2(combat.hitbox.position - shape.size * 0.5, shape.size)
		var color: Color = Color(0.55, 0.94, 0.96) if combat.combo_step == 1 else Color(1.0, 0.72, 0.3)
		color.a = 0.5 if combat.phase == PlayerCombat.Phase.ACTIVE else 0.15
		if combat.phase == PlayerCombat.Phase.ACTIVE:
			draw_rect(rect, color)
		else:
			draw_rect(rect, color, false, 3.0)
	if _pulse > 0.0:
		draw_line(Vector2(-65.0 * (1.1 - _pulse), -2.0), Vector2(65.0 * (1.1 - _pulse), -2.0), Color(0.5, 0.85, 0.9, _pulse), 4.0)
