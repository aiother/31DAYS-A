extends Control
## EXP-005 playable preview: a simplified player and eight practice targets
## on a dark field, to compare three effect looks. Mock data only; nothing
## here touches the real combat, saves or input map.
const EffectsScript: GDScript = preload("res://prototypes/EXP-005/effects.gd")
const HELP: String = "EXP-005 战斗反馈特效原型（F1 隐藏说明）\n1 / 2 / 3 / 4  风格 A 墨迹飞溅 / B 光痕 / C 极简几何 / D 融合（默认，手柄 LB / RB 切换）\nH 顿帧开关 · [ / ] 顿帧缩短 / 加长 · V 普通命中也震动（默认关，受击仍轻震）\nA D / ← → 移动 · 空格 跳 · J 攻击（W 上 / 空中 S 下）· K 闪避 · 长按 L 恢复\nP 切换“可能性不足”（闪避变为透支闪避）· R 靶子投射物（攻击可弹反）\nT 受击 · Z 复活 · G 八个靶子同时受击（记录帧时间）\n手柄：A 跳 · X 攻击 · B 闪避 · 长按 Y 恢复 · Back 可能性不足 · 十字键 上 投射物 / 左 受击 / 右 复活 / 下 八靶受击\n　　　Start 顿帧开关 · 按下左 / 右摇杆 顿帧缩短 / 加长"
const GROUND: float = 860.0
const GRAVITY: float = 2600.0
const SPEED: float = 420.0
const TARGET_X: Array[float] = [760.0, 880.0, 1000.0, 1120.0, 1240.0, 1360.0, 1480.0, 1600.0]
## Mock HUD area (top-left emblem) and the help panel; effects never draw there.
const HUD_RECT: Rect2 = Rect2(16, 16, 300, 300)
## User feedback 2026-10-23: the hit-stop should be felt more, the shake was
## too strong. Hit-stop is longer and adjustable; shake is halved and kept off
## for ordinary hits (reserved for heavy blows), still light on being hurt.
## Final (user, 2026-10-23): 0.10 s for ordinary attacks.
const HITSTOP_DEFAULT: float = 0.10
const HITSTOP_RANGE: Vector2 = Vector2(0.04, 0.20)
const HIT_SHAKE: float = 3.0
const HURT_SHAKE: float = 5.0
## Struck targets shiver this far during the hit-stop.
const STOP_JITTER: float = 4.0

var world: Node2D
var player: Node2D
var effects: Node2D
var warnings: Node2D
var overlay: Control
var help: Label
var hud_layer: CanvasLayer

var velocity: Vector2 = Vector2.ZERO
var facing: float = 1.0
var on_floor: bool = true
var attack_left: float = 0.0
var attack_dir: Vector2 = Vector2.RIGHT
var attack_hit: bool = false
var dodge_left: float = 0.0
var dodge_dir: float = 1.0
var invuln_left: float = 0.0
var heal_hold: float = 0.0
var healing: float = -1.0
var poor: bool = false
var hitstop: bool = true
## Ordinary hits shake too (off by default; being hurt always shakes lightly).
var shake: bool = false
var hitstop_seconds: float = HITSTOP_DEFAULT
var stop_left: float = 0.0
## Targets struck in the current hit-stop; they shiver until it ends.
var struck: Array[Dictionary] = []
var shake_left: float = 0.0
var shake_power: float = 0.0
var hitstop_frames: int = 0
var targets: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var clock: float = 0.0
var pad_heal: bool = false
## Frame times recorded after G (eight targets hit at once), milliseconds.
var perf: Dictionary = {}
var _perf_frames: Array[float] = []
var _perf_last: int = 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	world = Node2D.new()
	world.draw.connect(_draw_world)
	add_child(world)
	player = Node2D.new()
	player.position = Vector2(560, GROUND)
	world.add_child(player)
	effects = EffectsScript.new()
	effects.z_index = 1
	world.add_child(effects)
	warnings = Node2D.new()
	warnings.z_index = 2
	warnings.draw.connect(_draw_warnings)
	world.add_child(warnings)
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(_draw_overlay)
	hud_layer.add_child(overlay)
	help = Label.new()
	help.position = Vector2(340, 24)
	help.add_theme_font_override("font", UiTheme.font())
	help.add_theme_font_size_override("font_size", 18)
	help.add_theme_color_override("font_color", DuskStyle.PAPER_DAY)
	help.text = HELP
	hud_layer.add_child(help)
	# The user's direction (2026-10-23) is the default look.
	effects.style = effects.FUSION
	for i: int in range(TARGET_X.size()):
		targets.append({"x": TARGET_X[i], "hp": 3, "dead": 0.0, "windup": 0.0, "cycle": 1.0 + i * 0.37})

# --- input -------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).physical_keycode:
			KEY_1: set_style(0)
			KEY_2: set_style(1)
			KEY_3: set_style(2)
			KEY_4: set_style(3)
			KEY_BRACKETLEFT: hitstop_seconds = clampf(hitstop_seconds - 0.02, HITSTOP_RANGE.x, HITSTOP_RANGE.y)
			KEY_BRACKETRIGHT: hitstop_seconds = clampf(hitstop_seconds + 0.02, HITSTOP_RANGE.x, HITSTOP_RANGE.y)
			KEY_H: hitstop = not hitstop
			KEY_V: shake = not shake
			KEY_P: poor = not poor
			KEY_F1: help.visible = not help.visible
			KEY_SPACE: jump()
			KEY_J: attack()
			KEY_K: dodge()
			KEY_R: throw()
			KEY_T: hurt()
			KEY_Z: revive()
			KEY_G: stress()
	elif event is InputEventJoypadButton:
		var button: InputEventJoypadButton = event as InputEventJoypadButton
		if button.button_index == JOY_BUTTON_Y:
			pad_heal = button.pressed
		if not button.pressed:
			return
		match button.button_index:
			JOY_BUTTON_A: jump()
			JOY_BUTTON_X: attack()
			JOY_BUTTON_B: dodge()
			JOY_BUTTON_LEFT_SHOULDER: set_style((effects.style + 3) % 4)
			# Review R3: every effect can be reached with a controller alone.
			JOY_BUTTON_BACK: poor = not poor
			JOY_BUTTON_DPAD_UP: throw()
			JOY_BUTTON_DPAD_LEFT: hurt()
			JOY_BUTTON_DPAD_RIGHT: revive()
			JOY_BUTTON_DPAD_DOWN: stress()
			JOY_BUTTON_START: hitstop = not hitstop
			JOY_BUTTON_LEFT_STICK: hitstop_seconds = clampf(hitstop_seconds - 0.02, HITSTOP_RANGE.x, HITSTOP_RANGE.y)
			JOY_BUTTON_RIGHT_STICK: hitstop_seconds = clampf(hitstop_seconds + 0.02, HITSTOP_RANGE.x, HITSTOP_RANGE.y)
			JOY_BUTTON_RIGHT_SHOULDER: set_style((effects.style + 1) % 4)

func set_style(value: int) -> void:
	effects.style = value
	effects.clear()

func axis() -> float:
	var x: float = 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): x += 1.0
	var stick: float = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	if absf(stick) > 0.4: x = signf(stick)
	return x

func aim() -> Vector2:
	var up: bool = Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.get_joy_axis(0, JOY_AXIS_LEFT_Y) < -0.5
	var down: bool = Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.get_joy_axis(0, JOY_AXIS_LEFT_Y) > 0.5
	if up: return Vector2.UP
	if down and not on_floor: return Vector2.DOWN
	return Vector2(facing, 0)

func heal_held() -> bool:
	return Input.is_physical_key_pressed(KEY_L) or pad_heal

# --- actions -----------------------------------------------------------------

func center() -> Vector2:
	return player.position + Vector2(0, -48)

func jump() -> void:
	if on_floor:
		velocity.y = -980.0
		on_floor = false

func attack() -> void:
	if attack_left > 0.0 or dodge_left > 0.0:
		return
	attack_dir = aim()
	attack_left = 0.26
	attack_hit = false
	effects.spawn("swing", center(), attack_dir)

func dodge() -> void:
	if dodge_left > 0.0:
		return
	dodge_dir = facing
	dodge_left = 0.2
	invuln_left = maxf(invuln_left, 0.32)
	_end_heal(false)
	effects.spawn("spend", center())
	effects.spawn("poor_dodge" if poor else "dodge", center(), Vector2(dodge_dir, 0))

func hurt() -> void:
	effects.spawn("hurt", center())
	invuln_left = 1.0
	_end_heal(false)
	_kick(HURT_SHAKE, true)

func revive() -> void:
	effects.spawn("revive", center())
	invuln_left = 1.2

func throw() -> void:
	var source: Dictionary = targets[0]
	var best: float = INF
	for target: Dictionary in targets:
		if float(target["dead"]) <= 0.0 and absf(float(target["x"]) - player.position.x) < best:
			best = absf(float(target["x"]) - player.position.x)
			source = target
	var from: Vector2 = Vector2(float(source["x"]), GROUND - 60.0)
	projectiles.append({"at": from, "vel": (center() - from).normalized() * 520.0, "reflected": false})

## Eight targets struck in the same frame, to see the cost of a crowd.
func stress() -> void:
	for target: Dictionary in targets:
		if float(target["dead"]) <= 0.0:
			_strike(target, Vector2(facing, 0))
	_perf_frames.clear()
	_perf_last = Time.get_ticks_usec()

func _strike(target: Dictionary, direction: Vector2) -> void:
	var at: Vector2 = Vector2(float(target["x"]), GROUND - 48.0)
	effects.spawn("hit", at, direction)
	effects.spawn("enemy_hurt", at)
	target["hp"] = int(target["hp"]) - 1
	if int(target["hp"]) <= 0:
		target["dead"] = 1.6
		target["windup"] = 0.0
		effects.spawn("enemy_death", at)
		effects.spawn("gain", at)
	if hitstop:
		# The blade bites: this swing's trail stops where it met the target,
		# with the player and the target, then sweeps on (user, 2026-10-23).
		stop_left = hitstop_seconds
		struck.append(target)
		effects.hold("swing", hitstop_seconds)
	_kick(HIT_SHAKE, false)

## Hurt always shakes (lightly); ordinary hits only when V turns it on.
func _kick(power: float, always: bool) -> void:
	if always or shake:
		shake_left = 0.2
		shake_power = power

func _end_heal(done: bool) -> void:
	if healing >= 0.0:
		effects.stop("heal_loop")
		if done:
			effects.spawn("heal_done", center())
	healing = -1.0

# --- simulation --------------------------------------------------------------

func _process(delta: float) -> void:
	clock += delta
	if _perf_last > 0:
		var now: int = Time.get_ticks_usec()
		_perf_frames.append((now - _perf_last) / 1000.0)
		_perf_last = now
		if _perf_frames.size() >= 30:
			var total: float = 0.0
			for value: float in _perf_frames: total += value
			perf = {"frames": _perf_frames.size(), "avg_ms": total / _perf_frames.size(), "peak_ms": _perf_frames.max()}
			_perf_last = 0
	if shake_left > 0.0:
		shake_left = maxf(0.0, shake_left - delta)
		var k: float = shake_power * shake_left / 0.2
		world.position = Vector2(sin(clock * 90.0), cos(clock * 77.0)) * k
	else:
		world.position = Vector2.ZERO
	if stop_left > 0.0:
		# Hit-stop: the world holds still for a few frames; effects go on.
		stop_left = maxf(0.0, stop_left - delta)
		hitstop_frames += 1
		if stop_left == 0.0:
			struck.clear()
	else:
		_simulate(delta)
	if invuln_left > 0.0 and not effects.active("invuln"):
		effects.spawn("invuln", center(), Vector2.RIGHT, player)
	elif invuln_left <= 0.0 and effects.active("invuln"):
		effects.stop("invuln")
	world.queue_redraw()
	warnings.queue_redraw()
	overlay.queue_redraw()

func _simulate(delta: float) -> void:
	invuln_left = maxf(0.0, invuln_left - delta)
	var x: float = axis()
	if x != 0.0: facing = x
	if dodge_left > 0.0:
		dodge_left = maxf(0.0, dodge_left - delta)
		velocity.x = dodge_dir * 1100.0
	else:
		velocity.x = x * SPEED if attack_left <= 0.0 else x * SPEED * 0.5
	if not on_floor:
		velocity.y += GRAVITY * delta
	player.position += velocity * delta
	player.position.x = clampf(player.position.x, 80.0, 1840.0)
	# Grounded only when at the ground and not moving up; anything that sends
	# the player upwards (jump, bounce) leaves the floor, so gravity applies.
	if player.position.y >= GROUND and velocity.y >= 0.0:
		player.position.y = GROUND
		velocity.y = 0.0
		on_floor = true
	else:
		on_floor = false
	# Attack: the active window checks the targets once.
	if attack_left > 0.0:
		attack_left = maxf(0.0, attack_left - delta)
		if not attack_hit and attack_left < 0.18:
			attack_hit = true
			var reach: Vector2 = center() + attack_dir * 70.0
			for target: Dictionary in targets:
				if float(target["dead"]) <= 0.0 and Vector2(float(target["x"]), GROUND - 48.0).distance_to(reach) < 80.0:
					_strike(target, attack_dir)
					if attack_dir == Vector2.DOWN:
						velocity.y = -760.0
						on_floor = false
						effects.spawn("bounce", center())
			for shot: Dictionary in projectiles:
				if not shot["reflected"] and (shot["at"] as Vector2).distance_to(reach) < 70.0:
					shot["reflected"] = true
					shot["vel"] = -(shot["vel"] as Vector2) * 1.3
					effects.spawn("reflect", shot["at"], (shot["vel"] as Vector2).normalized())
	# Healing: hold to start, keep holding to finish, let go to interrupt.
	if heal_held() and on_floor and attack_left <= 0.0 and dodge_left <= 0.0:
		heal_hold += delta
		if heal_hold >= 0.15 and healing < 0.0:
			healing = 0.0
			effects.spawn("spend", center())
			effects.spawn("heal_loop", center(), Vector2.RIGHT, player)
		elif healing >= 0.0:
			healing += delta
			if healing >= 1.6:
				_end_heal(true)
				heal_hold = -10.0
	else:
		if heal_hold > 0.0 or healing >= 0.0:
			_end_heal(false)
		heal_hold = 0.0
	for target: Dictionary in targets:
		if float(target["dead"]) > 0.0:
			target["dead"] = float(target["dead"]) - delta
			if float(target["dead"]) <= 0.0:
				target["hp"] = 3
			continue
		target["cycle"] = float(target["cycle"]) - delta
		if float(target["cycle"]) <= 0.0:
			target["windup"] = 0.6
			target["cycle"] = 3.0
		target["windup"] = maxf(0.0, float(target["windup"]) - delta)
	for shot: Dictionary in projectiles:
		shot["at"] = (shot["at"] as Vector2) + (shot["vel"] as Vector2) * delta
		if not shot["reflected"] and (shot["at"] as Vector2).distance_to(center()) < 30.0:
			shot["gone"] = true
			if invuln_left <= 0.0:
				hurt()
	projectiles = projectiles.filter(func(shot: Dictionary) -> bool:
		return not shot.get("gone", false) and Rect2(-100, -100, 2120, 1280).has_point(shot["at"]))

# --- drawing -----------------------------------------------------------------

func _draw_world() -> void:
	world.draw_rect(Rect2(-200, -200, 2320, 1480), Color(0.06, 0.08, 0.09))
	world.draw_rect(Rect2(-200, GROUND, 2320, 400), Color(0.16, 0.2, 0.22))
	world.draw_line(Vector2(-200, GROUND), Vector2(2120, GROUND), Color(0.32, 0.4, 0.42), 3.0)
	for target: Dictionary in targets:
		if float(target["dead"]) > 0.0:
			continue
		var shiver: float = 0.0
		if stop_left > 0.0 and struck.has(target):
			shiver = STOP_JITTER * (1.0 if int(clock * 60.0) % 2 == 0 else -1.0)
		var rect: Rect2 = Rect2(Vector2(float(target["x"]) - 26.0 + shiver, GROUND - 88.0), Vector2(52, 88))
		world.draw_rect(rect, Color(0.55, 0.6, 0.64))
		for i: int in range(int(target["hp"])):
			world.draw_rect(Rect2(rect.position + Vector2(6 + i * 14, -12), Vector2(10, 6)), DuskStyle.PAPER_DAY)
	var body: Rect2 = Rect2(player.position - Vector2(18, 96), Vector2(36, 96))
	var tint: Color = Color(0.5, 0.85, 0.95)
	if invuln_left > 0.0 and int(clock * 11.0) % 2 == 0:
		tint.a = 0.45
	world.draw_rect(body, tint)
	world.draw_circle(player.position + Vector2(facing * 10.0, -78), 4.0, Color(0.1, 0.12, 0.14))
	for shot: Dictionary in projectiles:
		world.draw_circle(shot["at"], 9.0, DuskStyle.GROWTH if shot["reflected"] else Color(0.85, 0.4, 0.95))

## Enemy windup warnings sit above every effect.
func _draw_warnings() -> void:
	for target: Dictionary in targets:
		if float(target["windup"]) > 0.0 and float(target["dead"]) <= 0.0:
			warnings.draw_rect(Rect2(Vector2(float(target["x"]) - 30.0, GROUND - 130.0), Vector2(60, 22)), Color(1, 0.35, 0.3, 0.85))

## The mock HUD and the status line (top layer).
func _draw_overlay() -> void:
	InkDraw.paper_disc(overlay, HUD_RECT.position + Vector2(140, 140), 120.0, Color(DuskStyle.PAPER_DAY, 0.9), 3, 1.5)
	InkDraw.rough_circle(overlay, HUD_RECT.position + Vector2(140, 140), 92.0, DuskStyle.POSSIBILITY, 10.0, 4, 1.0)
	var status: String = "风格 %s · 顿帧 %s · 普通命中震动 %s · %s" % [effects.STYLES[effects.style], ("开 %.2f 秒" % hitstop_seconds) if hitstop else "关", "开" if shake else "关", "可能性不足" if poor else "可能性充足"]
	if not perf.is_empty():
		status += " · 八靶同时受击后 30 帧：平均 %.1f ms，峰值 %.1f ms" % [perf["avg_ms"], perf["peak_ms"]]
	overlay.draw_string(UiTheme.font(), Vector2(340, 1050), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, DuskStyle.PAPER_DAY)
