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
## Largest drawn reach (CombatEffects record "span") of an ordinary defeat and an
## ordinary-sized heavy cue, to compare the Boss versions against (review R3).
var ordinary_death_span: float = 0.0
var heavy_cue_span: float = 0.0
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

## Overlook: every dive dash lies on the line from the Boss to its marked
## landing spot and the two brackets sit either side of that spot. Parasite:
## every tendril point reaches from the real muzzle toward the player.
func boss_aim_ok(boss: Node2D, arena: Node2D, r: Dictionary) -> bool:
	var c: Vector2 = r["at"]
	if boss is OverlookBoss:
		var o: OverlookBoss = boss as OverlookBoss
		var spot: Vector2 = arena.to_global(Vector2(o.impact_x, o.config.floor_y))
		var lane: int = 0
		var left: float = INF
		var right: float = -INF
		for point: Vector2 in r["points"]:
			if point.y > spot.y - 30.0 and point.y <= spot.y + 1.0:
				left = minf(left, point.x)
				right = maxf(right, point.x)
			elif point.distance_to(c) > 34.0 * CombatEffectDirector.BOSS_SIZE * 1.15:
				lane += 1
				if Geometry2D.get_closest_point_to_segment(point, c, spot).distance_to(point) > 6.0: return false
		# Early in the wind-up the dive line has not left the eye yet.
		return (lane > 0 or float(r.get("progress", 0.0)) < 0.5) and is_finite(left) and absf((left + right) * 0.5 - spot.x) < 4.0
	var leech: ParasiteBoss = boss as ParasiteBoss
	var muzzle: Vector2 = arena.to_global(leech.position + Vector2(-80 if body.position.x < leech.position.x else 80, -64))
	var toward: Vector2 = body.global_position + Vector2(0, -44) - muzzle
	var reached: int = 0
	for point: Vector2 in r["points"]:
		if point.distance_to(muzzle) > 60.0 and point.y > muzzle.y - 40.0:
			reached += 1
			if absf((point - muzzle).angle_to(toward)) > 0.4: return false
	return reached > 0

## Width of what the cue draws on the Boss's own body (around its centre, or
## the parasite's mouth).
func body_width(boss: Node2D, r: Dictionary) -> float:
	var c: Vector2 = r["at"]
	var near: float = 100.0 if boss is OverlookBoss else 47.0
	var from: Vector2 = c if boss is OverlookBoss else (director.cue_for(boss).get("aim_from", c) as Vector2)
	var left: float = INF
	var right: float = -INF
	for point: Vector2 in r["points"]:
		if point.distance_to(from) <= near:
			left = minf(left, point.x)
			right = maxf(right, point.x)
	return right - left if is_finite(left) else 0.0

func widest(rows: Array[Dictionary]) -> float:
	var out: float = 0.0
	for r: Dictionary in rows: out = maxf(out, float(r["span"]))
	return out

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
	check(not rows.is_empty() and drew_hue(rows, DuskStyle.PEARL) and not drew_hue(rows, DuskStyle.LIFE) and not drew_hue(rows, DuskStyle.SUN), "the colourless cue is its own ash and pearl, never vermilion nor the player's warm hit light")
	check(not drew_hue(rows, DuskStyle.DUSK_TOP) and not drew_hue(rows, DuskStyle.GROWTH), "the colourless cue does not borrow the single-colour violet or the Tian gold")
	var ahead: bool = false
	for r: Dictionary in rows:
		for point: Vector2 in r["points"]:
			if (point - (r["at"] as Vector2)).dot(r["dir"] as Vector2) > 45.0: ahead = true
	check(ahead, "its claw marks reach out ahead in the direction of the blow")
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
	for i: int in range(60): await frames(1)
	ordinary_death_span = widest(seen("enemy_death"))
	check(ordinary_death_span > 0.0, "an ordinary defeat draws its burst (%.0f px)" % ordinary_death_span)
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
	check(drew_hue(light_rows, DuskStyle.DUSK_TOP) and not drew_hue(light_rows, DuskStyle.GROWTH), "the single-colour ordinary cue is its own violet")
	var heavy_reach: float = 0.0
	for r: Dictionary in heavy_rows: heavy_reach = maxf(heavy_reach, int(r["prims"]))
	var light_reach: float = 0.0
	for r: Dictionary in light_rows: light_reach = maxf(light_reach, int(r["prims"]))
	heavy_cue_span = widest(heavy_rows)
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
		var tian_rows: Array[Dictionary] = seen("windup_heavy" if heavy else "windup")
		if heavy:
			check(drew_hue(tian_rows, DuskStyle.LIFE) and not drew_hue(tian_rows, DuskStyle.PEARL) and not drew_hue(tian_rows, DuskStyle.GROWTH), "the Tian heavy cue is vermilion only")
		else:
			check(drew_hue(tian_rows, DuskStyle.GROWTH) and not drew_hue(tian_rows, DuskStyle.LIFE) and not drew_hue(tian_rows, DuskStyle.DUSK_TOP), "the Tian cue (kind %d) is its own gold" % kind)
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
		# Each frame of the wind-up: does the drawn cue point where the blow
		# will really go? (G4 2026-10-25: the Boss cue pointed the wrong way.)
		var aim: Dictionary = {"frames": 0, "wrong": 0, "body": 0.0, "moved": -1, "after": 0, "after_wrong": 0}
		var result: Dictionary = await watch(boss, 600, func() -> bool:
			if CombatEffectDirector._winding(boss) and wound[0] < 0: wound[0] = Engine.get_physics_frames()
			if CombatEffectDirector._winding(boss):
				for r: Dictionary in fx.drawn:
					if r["kind"] == "windup_heavy":
						# Skip the frame right after the move: what was drawn then
						# was laid out before the director's next physics step.
						if int(aim["moved"]) >= 0 and Engine.get_physics_frames() - int(aim["moved"]) < 2:
							continue
						aim["frames"] += 1
						var ok: bool = boss_aim_ok(boss, arena, r)
						if not ok: aim["wrong"] += 1
						if int(aim["moved"]) >= 0:
							aim["after"] += 1
							if not ok: aim["after_wrong"] += 1
						aim["body"] = maxf(float(aim["body"]), body_width(boss, r))
				# Halfway through the wind-up the player switches to the Boss's
				# other side (review round 3): the cue has to follow every frame.
				if int(aim["moved"]) < 0 and int(aim["frames"]) >= 8:
					aim["moved"] = Engine.get_physics_frames()
					body.global_position.x = boss.global_position.x - signf(body.global_position.x - boss.global_position.x) * 360.0
					body.velocity = Vector2.ZERO
			return wound[0] >= 0 and not CombatEffectDirector._winding(boss))
		var sound: Dictionary = last_windup_sound()
		check(wound[0] >= 0 and result["mismatch"] == 0 and result["kinds"].keys() == ["windup_heavy"], path.get_file() + " winds up with the heavy cue only while winding up")
		check(int(sound.get("physics_frame", -1)) == wound[0] and sound.get("event") == "enemy.windup", path.get_file() + " cue appears in the frame of its warning sound")
		var rows: Array[Dictionary] = seen("windup_heavy")
		check(not rows.is_empty() and int(aim["frames"]) > 10 and int(aim["wrong"]) == 0, path.get_file() + " cue points where the blow really goes (%d frames, %d wrong)" % [aim["frames"], aim["wrong"]])
		check(int(aim["after"]) >= 6 and int(aim["after_wrong"]) == 0, path.get_file() + " cue keeps pointing the right way after the player switches sides mid-wind-up (%d frames after, %d wrong)" % [aim["after"], aim["after_wrong"]])
		check(float(aim["body"]) >= (120.0 if boss is OverlookBoss else 80.0), path.get_file() + " cue on the Boss itself is drawn at Boss size (%.0f px wide)" % aim["body"])
		# Defeat: the Boss burst, not the ordinary one.
		records.clear()
		boss.get_node("GameplayRoot/Hurtbox").call("receive_attack", 100000, Vector2.ZERO, body, 900100)
		await frames(3)
		check(not seen("boss_death").is_empty() and seen("enemy_death").is_empty(), path.get_file() + " defeat draws the Boss burst")
		var big: Array[Dictionary] = seen("boss_death")
		check(not big.is_empty() and float(big[0]["life"]) > CombatEffects.LIFE["enemy_death"] and drew_hue(big, DuskStyle.LIFE), path.get_file() + " Boss burst is longer than an ordinary defeat and carries vermilion")
		for i: int in range(80): await frames(1)
		big = seen("boss_death")
		check(widest(big) >= 2.0 * ordinary_death_span and ordinary_death_span > 0.0, path.get_file() + " Boss burst reaches much further than an ordinary defeat (%.0f px against %.0f px)" % [widest(big), ordinary_death_span])
		if boss is ParasiteBoss:
			check(drew_hue(big, DuskStyle.OVERDRAFT) and drew_hue(big, DuskStyle.POSSIBILITY_GLOW), "the parasite bursts into dark tendrils and releases the possibility it leeched")
		else:
			check(drew_hue(big, DuskStyle.INK) and not drew_hue(big, DuskStyle.OVERDRAFT) and not drew_hue(big, DuskStyle.POSSIBILITY_GLOW), "Overlook shatters into ink shards, not the parasite's burst")
		check(not drew_hue(big, DuskStyle.SUN), path.get_file() + " Boss burst is not the warm ordinary-defeat glow")
		await clean()
	for i: int in range(80): await frames(1)
	check(not fx.entries.any(func(e: Dictionary) -> bool: return e["kind"] == "boss_death"), "the Boss burst ends")

func arrival_cases() -> void:
	# The real final-battlefield wave code. Units placed while the Room loads
	# get no arrival effect; a new wave's units appear after theirs has ended
	# (T2 §11), the effect playing inside the existing 1 s warning.
	var room: FinalBattlefieldRoom = (load("res://world/rooms/final_battlefield.tscn") as PackedScene).instantiate() as FinalBattlefieldRoom
	room.target = body
	records.clear()
	lab.add_child(room)
	spawned.append(room)
	await frames(3)
	check(room.get_node("Enemies").get_child_count() + room.get_node("Allies").get_child_count() > 0 and seen("arrival_enemy").is_empty() and seen("arrival_ally").is_empty(), "units placed while the Room loads get no arrival effect")
	check(room.battle.wave_warning >= CombatEffectDirector.ARRIVAL_LEAD and CombatEffectDirector.ARRIVAL_LEAD >= CombatEffects.LIFE["arrival_enemy"] + 0.05, "the arrival effect fits inside the wave warning")
	room.phase = RescueBattlefieldRoom.Phase.COOP
	room.started = true
	var last: int = room.battle.tian_counts.size() - 1
	for index: int in [last - 1, last]:
		records.clear()
		for child: Node in room.get_node("Enemies").get_children(): child.set_physics_process(false)
		var allies_before: Array[Node] = room.get_node("Allies").get_children()
		room.wave_index = index - 1
		var expected: Array[Dictionary] = room.upcoming_arrivals(index)
		check(room.advance_wave() and room.wave_index == index, "wave %d is announced by the real warning" % index)
		var effects_seen: Dictionary = {}
		var appear: int = -1
		var alive_on_appear: int = -1
		var first: int = -1
		var after: int = 0
		for i: int in range(150):
			await frames(1)
			for e: Dictionary in fx.entries:
				if String(e["kind"]).begins_with("arrival"):
					if not effects_seen.has(e["serial"]):
						effects_seen[e["serial"]] = {"kind": e["kind"], "at": e["at"]}
						if first < 0: first = i
						if appear >= 0: after += 1
			if appear < 0 and room.wave_state == FinalBattlefieldRoom.WaveState.ACTIVE:
				appear = i
				alive_on_appear = fx.entries.filter(func(e: Dictionary) -> bool: return String(e["kind"]).begins_with("arrival")).size()
				for child: Node in room.get_node("Enemies").get_children(): child.set_physics_process(false)
				for child: Node in room.get_node("Allies").get_children(): child.set_physics_process(false)
			if appear >= 0 and i > appear + 10: break
		var units: Array[Node2D] = []
		for child: Node in room.get_node("Enemies").get_children(): units.append(child as Node2D)
		for child: Node in room.get_node("Allies").get_children():
			if not child in allies_before: units.append(child as Node2D)
		var placed: int = 0
		for unit: Node2D in units:
			var kind: String = "arrival_ally" if unit is SurvivorFighter else "arrival_enemy"
			for row: Dictionary in effects_seen.values():
				if row["kind"] == kind and (row["at"] as Vector2).distance_to(unit.global_position + CombatEffects.CHEST) < 12.0:
					placed += 1
					break
		if index == last - 1:
			var rift: Array[Dictionary] = seen("arrival_enemy")
			var most: float = 0.0
			for r: Dictionary in rift:
				var box: Rect2 = r["box"]
				if box.size.x > 0.0: most = maxf(most, box.size.y / box.size.x)
			check(most >= 2.0 and drew_hue(rift, DuskStyle.INK) and not drew_hue(rift, DuskStyle.PEARL), "an enemy steps out of a tall ink rift, without a cue's pearl glint (height %.1f times the width)" % most)
		check(appear >= 0 and units.size() == expected.size() and effects_seen.size() == units.size() and placed == units.size() and drew_hue(seen("arrival_enemy"), DuskStyle.LIFE), "wave %d: one arrival effect where each of its %d units appears (%d placed)" % [index, units.size(), placed])
		check(appear >= 0 and first >= 0 and appear - first >= ceili(CombatEffects.LIFE["arrival_enemy"] * 60.0) and alive_on_appear == 0 and after == 0, "wave %d: the units appear after their arrival effect has ended (effect at frame %d, units at %d, %d still alive, %d more after)" % [index, first, appear, alive_on_appear, after])
	check(drew_hue(seen("arrival_ally"), DuskStyle.POSSIBILITY_GLOW) and not drew_hue(seen("arrival_ally"), DuskStyle.LIFE), "last-wave allies arrive with the teal arrival effect")
	check(room.final_support_spawned, "the last wave brought its allies")
	# An arrival must not look like a cue (G4 2026-10-25): an enemy's is a tall
	# ink rift, an ally's a tall shaft of teal light; neither has a cue's glint.
	var tall: Callable = func(rows: Array[Dictionary]) -> bool:
		var most: float = 0.0
		for r: Dictionary in rows:
			var box: Rect2 = r["box"]
			if box.size.x > 0.0: most = maxf(most, box.size.y / box.size.x)
		return most >= 2.0
	check(tall.call(seen("arrival_ally")) and not drew_hue(seen("arrival_ally"), DuskStyle.PEARL), "an ally arrives in a tall shaft of teal light, without a cue's pearl glint")
	# A reinforcement with no warning before it (a survivor joining mid-wave)
	# still gets its effect as it appears.
	records.clear()
	room._spawn_ally()
	await frames(2)
	check(not seen("arrival_ally").is_empty(), "a mid-wave survivor reinforcement arrives with the teal effect")
	await clean()
