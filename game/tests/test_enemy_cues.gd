# verify-suite: {"name":"FX-002 enemy wind-up cues, Boss defeat and reinforcement arrival","path":"res://tests/test_enemy_cues.gd","marker":"ENEMY_CUES_TESTS checks=","fixed_fps":60,"timeout":240}
extends SceneTree
## FX-002. Real enemy AI or real action entries, real Boss state machines and
## the real final-battlefield wave code. Looks are read from what
## CombatEffects actually drew (FX-001 review R2), never from the cue's kind.
var checks: int = 0
var failures: int = 0
var lab: Node
var body: PlayerController
var director: CombatEffectDirector
var fx: CombatEffects
var audio: AudioEventService
var records: Array[Dictionary] = []
var spawned: Array[Node] = []

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func frames(n: int = 1) -> void:
	for i: int in range(n):
		await physics_frame
		await process_frame
		records.append_array(fx.drawn)

func seen(kind: String) -> Array[Dictionary]:
	return records.filter(func(r: Dictionary) -> bool: return r["kind"] == kind and int(r["prims"]) > 0 and float(r["alpha"]) > 0.0)

func drew_hue(rows: Array[Dictionary], hue: Color) -> bool:
	for r: Dictionary in rows:
		for c: Color in r["colors"]:
			if c.a > 0.0 and is_equal_approx(c.r, hue.r) and is_equal_approx(c.g, hue.g) and is_equal_approx(c.b, hue.b): return true
	return false

func last_windup_sound() -> Dictionary:
	var rows: Array = audio.history.filter(func(row: Dictionary) -> bool: return String(row["event"]).begins_with("enemy.windup"))
	return rows.back() if not rows.is_empty() else {}

func clean() -> void:
	for node: Node in spawned:
		if is_instance_valid(node): node.queue_free()
	spawned.clear()
	await frames(4)
	records.clear()

func add(path: String, offset: Vector2, chase: bool = true) -> Node2D:
	var actor: Node2D = (load(path) as PackedScene).instantiate() as Node2D
	lab.get_node("Enemies").add_child(actor)
	actor.global_position = body.global_position + offset
	if chase and actor is ColorlessEntity:
		(actor as ColorlessEntity).target = body
		(actor as ColorlessEntity).alert_to_target()
	spawned.append(actor)
	return actor

## Frames where the cue and the actual wind-up disagree (checked after the
## director's own physics step, which runs after the actors').
func watch(actor: Node, frames_to_run: int, stop_when: Callable = Callable()) -> Dictionary:
	var result: Dictionary = {"mismatch": 0, "windup_frames": 0, "kinds": {}}
	for i: int in range(frames_to_run):
		await frames(1)
		if not is_instance_valid(actor): break
		var winding: bool = CombatEffectDirector._winding(actor)
		var cue: Dictionary = director.cue_for(actor)
		if winding:
			result["windup_frames"] += 1
			if not cue.is_empty(): result["kinds"][cue["kind"]] = true
		if winding != not cue.is_empty(): result["mismatch"] += 1
		if stop_when.is_valid() and stop_when.call(): break
	return result

func run() -> void:
	lab = (load("res://debug/enemy_lab.tscn") as PackedScene).instantiate()
	root.add_child(lab)
	current_scene = lab
	for child: Node in lab.get_node("Enemies").get_children():
		child.queue_free()
	body = lab.get_node("Player") as PlayerController
	director = body.get_node("EffectDirector") as CombatEffectDirector
	fx = director.effects
	audio = root.get_node("AudioEvents") as AudioEventService
	await frames(6)
	body.life.protection_remaining = 100000.0
	await ordinary_cases()
	await strong_cases()
	await boss_cases()
	await arrival_cases()
	await clean()
	for node: Node in lab.find_children("*", "AudioStreamPlayer", true, false):
		(node as AudioStreamPlayer).stop()
	lab.queue_free()
	for i: int in range(6): await process_frame
	OS.delay_msec(250)
	print("ENEMY_CUES_TESTS checks=%d failures=%d" % [checks, failures])
	quit(1 if failures > 0 else 0)

func ordinary_cases() -> void:
	# A real colourless enemy chases and winds up: the cue starts with its
	# warning sound and ends with the wind-up.
	var enemy: ColorlessEntity = add("res://enemies/colorless_entity.tscn", Vector2(160, 0)) as ColorlessEntity
	var started: Array[int] = []
	enemy.attack_started.connect(func(_r: bool) -> void: started.append(Engine.get_physics_frames()))
	var result: Dictionary = await watch(enemy, 400, func() -> bool: return started.size() >= 2 and enemy.state != ColorlessEntity.State.WINDUP)
	var sound: Dictionary = last_windup_sound()
	check(result["windup_frames"] > 0 and result["mismatch"] == 0, "the ordinary cue shows exactly while a real wind-up lasts (%d frames, %d mismatches)" % [result["windup_frames"], result["mismatch"]])
	check(result["kinds"].keys() == ["windup"], "a colourless enemy uses the ordinary cue")
	var rows: Array[Dictionary] = seen("windup")
	check(not rows.is_empty() and drew_hue(rows, DuskStyle.PEARL) and drew_hue(rows, DuskStyle.SUN) and not drew_hue(rows, DuskStyle.LIFE), "the ordinary cue is drawn in pearl and warm light, never vermilion")
	check(not started.is_empty() and sound.get("event") == "enemy.windup" and int(sound.get("physics_frame", -1)) == started.back(), "its warning sound is sent in the wind-up frame")
	# Hit during the wind-up: the stun ends the wind-up and the cue with it.
	await clean()
	enemy = add("res://enemies/colorless_entity.tscn", Vector2(70, 0)) as ColorlessEntity
	for i: int in range(300):
		await frames(1)
		if enemy.state == ColorlessEntity.State.WINDUP: break
	var cue_before: bool = not director.cue_for(enemy).is_empty()
	enemy.hurtbox.receive_attack(1, Vector2(100, 0), body, 900001)
	await frames(1)
	check(cue_before and enemy.state == ColorlessEntity.State.STUN and director.cue_for(enemy).is_empty(), "an interrupted wind-up loses its cue")
	# Defeated during the wind-up: no cue left behind.
	await clean()
	enemy = add("res://enemies/colorless_entity.tscn", Vector2(70, 0)) as ColorlessEntity
	for i: int in range(300):
		await frames(1)
		if enemy.state == ColorlessEntity.State.WINDUP: break
	enemy.hurtbox.receive_attack(1000, Vector2.ZERO, body, 900002)
	await frames(2)
	check(director.cue_for(enemy).is_empty() and not fx.entries.any(func(e: Dictionary) -> bool: return e["kind"] == "windup"), "a defeated enemy leaves no cue")
	# Removed outright during the wind-up (a Room change): the cue goes with it.
	await clean()
	enemy = add("res://enemies/colorless_entity.tscn", Vector2(70, 0)) as ColorlessEntity
	for i: int in range(300):
		await frames(1)
		if enemy.state == ColorlessEntity.State.WINDUP: break
	var had: bool = fx.entries.any(func(e: Dictionary) -> bool: return e["kind"] == "windup")
	enemy.free()
	await frames(3)
	check(had and not fx.entries.any(func(e: Dictionary) -> bool: return e["kind"] == "windup"), "an enemy removed during its wind-up takes its cue with it")
	await clean()

func strong_cases() -> void:
	# Monochrome: real AI alternates light and strong attacks.
	var mono: MonochromeEntity = add("res://enemies/monochrome_entity.tscn", Vector2(80, 0)) as MonochromeEntity
	var kinds: Dictionary = {}
	var by_kind: Dictionary = {"windup": [], "windup_heavy": []}
	var agree: Array[bool] = [true]
	mono.attack_started.connect(func(_r: bool) -> void:
		var cue: Dictionary = director.cue_for(mono)
		var sound: Dictionary = last_windup_sound()
		var expected: String = "windup_heavy" if mono.strong_attack else "windup"
		kinds[expected] = true
		if cue.get("kind") != expected or int(cue.get("frame", -2)) != int(sound.get("physics_frame", -1)): agree[0] = false
		if sound.get("event") != ("enemy.windup.monochrome_heavy" if mono.strong_attack else "enemy.windup.monochrome"): agree[0] = false)
	for i: int in range(900):
		records.clear()
		await frames(1)
		var cue: Dictionary = director.cue_for(mono)
		if not cue.is_empty():
			by_kind[cue["kind"]].append_array(seen(cue["kind"]))
		if kinds.size() == 2 and not by_kind["windup"].is_empty() and not by_kind["windup_heavy"].is_empty(): break
	check(kinds.size() == 2 and agree[0], "monochrome: strong blows get the heavy cue, light ones the ordinary cue, each with its own sound in the same frame")
	var heavy_rows: Array[Dictionary] = []
	heavy_rows.assign(by_kind["windup_heavy"])
	var light_rows: Array[Dictionary] = []
	light_rows.assign(by_kind["windup"])
	check(drew_hue(heavy_rows, DuskStyle.LIFE) and not drew_hue(heavy_rows, DuskStyle.PEARL), "the heavy cue is drawn wholly in vermilion")
	check(drew_hue(light_rows, DuskStyle.PEARL) and not drew_hue(light_rows, DuskStyle.LIFE), "the ordinary cue is pearl and warm light, never vermilion")
	var heavy_reach: float = 0.0
	for r: Dictionary in heavy_rows: heavy_reach = maxf(heavy_reach, int(r["prims"]))
	var light_reach: float = 0.0
	for r: Dictionary in light_rows: light_reach = maxf(light_reach, int(r["prims"]))
	check(heavy_reach > light_reach, "the heavy cue draws more than the ordinary one (%d vs %d primitives)" % [heavy_reach, light_reach])
	await clean()
	# Tian: real action entries for each attack kind.
	for kind: int in [TianWarrior.Attack.COMBO, TianWarrior.Attack.HEAVY, TianWarrior.Attack.RANGED]:
		var tian: TianWarrior = add("res://enemies/tian_warrior.tscn", Vector2(110, 0), false) as TianWarrior
		tian.target = body
		# Hold its own AI so the attack is exactly the one entered here.
		tian.set_physics_process(false)
		await frames(2)
		tian._start_attack(kind)
		tian.set_physics_process(true)
		var cue: Dictionary = director.cue_for(tian)
		var sound: Dictionary = last_windup_sound()
		var heavy: bool = kind == TianWarrior.Attack.HEAVY
		check(cue.get("kind") == ("windup_heavy" if heavy else "windup") and int(cue.get("frame", -2)) == int(sound.get("physics_frame", -1)) and sound.get("event") == ("enemy.windup.tian_heavy" if heavy else "enemy.windup.tian"), "Tian attack kind %d gets the %s cue with its sound" % [kind, "heavy" if heavy else "ordinary"])
		var result: Dictionary = await watch(tian, 200, func() -> bool: return tian.state != ColorlessEntity.State.WINDUP)
		check(result["mismatch"] == 0 and director.cue_for(tian).is_empty(), "the Tian cue ends with its wind-up")
		await clean()

func boss_cases() -> void:
	for path: String in ["res://enemies/parasite_boss.tscn", "res://enemies/overlook_boss.tscn"]:
		# A Boss expects a Room-like parent with an Enemies child (projectiles).
		var arena: Node2D = Node2D.new()
		arena.add_child(Node2D.new())
		arena.get_child(0).name = "Enemies"
		lab.add_child(arena)
		spawned.append(arena)
		var boss: Node2D = (load(path) as PackedScene).instantiate() as Node2D
		arena.add_child(boss)
		boss.global_position = body.global_position + Vector2(420, 0)
		boss.set("target", body)
		await frames(2)
		# Started inside a physics step, as the sessions do.
		physics_frame.connect(func() -> void: boss.call("start_combat"), CONNECT_ONE_SHOT)
		var wound: Array[int] = [-1]
		var result: Dictionary = await watch(boss, 600, func() -> bool:
			if CombatEffectDirector._winding(boss) and wound[0] < 0: wound[0] = Engine.get_physics_frames()
			return wound[0] >= 0 and not CombatEffectDirector._winding(boss))
		var sound: Dictionary = last_windup_sound()
		check(wound[0] >= 0 and result["mismatch"] == 0 and result["kinds"].keys() == ["windup_heavy"], path.get_file() + " winds up with the heavy cue only while winding up")
		check(int(sound.get("physics_frame", -1)) == wound[0] and sound.get("event") == "enemy.windup", path.get_file() + " cue appears in the frame of its warning sound")
		var rows: Array[Dictionary] = seen("windup_heavy")
		check(not rows.is_empty() and is_equal_approx(float(rows[0]["size"]), CombatEffectDirector.BOSS_SIZE), path.get_file() + " cue is drawn at Boss size")
		# Defeat: the Boss burst, not the ordinary one.
		records.clear()
		boss.get_node("GameplayRoot/Hurtbox").call("receive_attack", 100000, Vector2.ZERO, body, 900100)
		await frames(3)
		check(not seen("boss_death").is_empty() and seen("enemy_death").is_empty(), path.get_file() + " defeat draws the Boss burst")
		var big: Array[Dictionary] = seen("boss_death")
		check(not big.is_empty() and float(big[0]["life"]) > CombatEffects.LIFE["enemy_death"] and drew_hue(big, DuskStyle.LIFE), path.get_file() + " Boss burst is longer than an ordinary defeat and carries vermilion")
		await clean()
	for i: int in range(80): await frames(1)
	check(not fx.entries.any(func(e: Dictionary) -> bool: return e["kind"] == "boss_death"), "the Boss burst ends")

func arrival_cases() -> void:
	# The real final-battlefield wave code adds enemies (and, on the last wave,
	# allies) to a running Room; the units it was loaded with do not count.
	var room: FinalBattlefieldRoom = (load("res://world/rooms/final_battlefield.tscn") as PackedScene).instantiate() as FinalBattlefieldRoom
	room.target = body
	records.clear()
	lab.add_child(room)
	spawned.append(room)
	await frames(3)
	check(room.get_node("Enemies").get_child_count() + room.get_node("Allies").get_child_count() > 0 and seen("arrival_enemy").is_empty() and seen("arrival_ally").is_empty(), "units placed while the Room loads get no arrival effect")
	room.wave_index = room.battle.tian_counts.size() - 2
	room.replace_wave()
	await frames(2)
	var enemies: int = room.get_node("Enemies").get_child_count()
	check(enemies > 0 and seen("arrival_enemy").size() >= enemies and drew_hue(seen("arrival_enemy"), DuskStyle.LIFE), "a new wave's enemies arrive with the vermilion arrival effect (%d)" % enemies)
	records.clear()
	# The last wave also brings the allies (FinalBattlefieldRoom._begin_wave).
	room.wave_index = room.battle.tian_counts.size() - 1
	room._begin_wave()
	await frames(2)
	check(room.final_support_spawned and not seen("arrival_ally").is_empty() and drew_hue(seen("arrival_ally"), DuskStyle.POSSIBILITY_GLOW) and not drew_hue(seen("arrival_ally"), DuskStyle.LIFE), "last-wave allies arrive with the teal arrival effect")
	await clean()
