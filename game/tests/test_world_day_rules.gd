# verify-suite: {"name": "NPC deadline migration and ordinary enemy day configuration", "path": "res://tests/test_world_day_rules.gd", "marker": "WORLD_DAY_RULES_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var store: SlotStore = SlotStore.new()
	for id: String in WorldDayRules.IDS:
		var data: Dictionary = store.fresh()
		check(not WorldDayRules.expired(data, id), id + " available on first day")
		data["day"] = 2
		data["day_remaining"] = 0.001
		check(not WorldDayRules.expired(data, id), id + " available through second-day boundary")
		DayClock.advance_to(data, 3)
		check(WorldDayRules.expired(data, id) == (id != WorldDayRules.IDS[3]), id + " third-day boundary")
		data["day3_remaining"] = 0.001
		if id == WorldDayRules.IDS[3]: check(not WorldDayRules.expired(data, id), "outskirts still available before zero")
		data["day3_remaining"] = 0.0
		WorldDayRules.sync(data)
		check(bool(data["events"].get(WorldDayRules.expired_key(id), false)), id + " deadline latches independently")
		check(not bool(data["events"].get(WorldDayRules.failed(id), false)), id + " expiry is not abandonment")
		check(store.valid(data), id + " unseen expiry is valid including locked outskirts")
		DayClock.retry(data)
		check(WorldDayRules.expired(data, id), id + " exploration retry never restores opportunity")
		data["events"][WorldDayRules.completed(id)] = true
		check(not store.valid(data), id + " contradictory completed and expired save rejected")
		data = store.fresh()
		if id == WorldDayRules.IDS[3]:
			data["events"][OutskirtsSession.SPIKES_OPEN] = true
			data["events"][ParasiteSession.DODGE_GROWTH] = true
			data["events"][ParasiteSession.PARASITE_DEFEATED] = true
		data["events"][WorldDayRules.completed(id)] = true
		data["day"] = 3
		data["day3_remaining"] = 0.0
		WorldDayRules.sync(data)
		check(not WorldDayRules.expired(data, id), id + " completed source survives deadline")
		data = store.fresh()
		data["events"].erase(WorldDayRules.ENABLED)
		var seen: String = FieldSession.HEAL_GUIDE if id == WorldDayRules.IDS[0] else "rescue:%s:seen" % id
		data["events"][seen] = true
		data["day"] = 3
		data["day3_remaining"] = 0.0
		WorldDayRules.migrate(data)
		check(bool(data["events"].get(WorldDayRules.grace_key(id), false)), id + " legacy known pending opportunity protected")
		WorldDayRules.sync(data)
		check(not WorldDayRules.expired(data, id), id + " protected legacy source remains available")
		var before: Dictionary = data.duplicate(true)
		WorldDayRules.migrate(data)
		check(data == before, id + " migration idempotent")
		data = store.fresh()
		data["events"].erase(WorldDayRules.ENABLED)
		data["day"] = 3
		data["day3_remaining"] = 0.0
		WorldDayRules.migrate(data)
		check(WorldDayRules.expired(data, id), id + " unseen legacy source observes window")
		data["events"][WorldDayRules.failed(id)] = true
		WorldDayRules.migrate(data)
		check(not bool(data["events"].get(WorldDayRules.grace_key(id), false)), id + " abandonment never receives grace")
	for day: int in range(1, 4):
		var enemy: ColorlessEntity = (load("res://enemies/colorless_entity.tscn") as PackedScene).instantiate() as ColorlessEntity
		root.add_child(enemy)
		enemy.set_physics_process(false)
		var original: ColorlessConfig = enemy.config
		WorldDayRules.apply_enemy(enemy, day)
		var hp: int = [13, 15, 17][day-1]
		var speed: float = [120.0, 132.0, 144.0][day-1]
		check(enemy.health == hp and enemy.config.max_health == hp, "spawn health day %d" % day)
		check(is_equal_approx(enemy.config.speed, speed), "spawn speed day %d" % day)
		check(is_equal_approx(enemy.config.recovery, 0.75 * [1.0, 0.9, 0.8][day-1]), "melee and pure ranged recovery day %d" % day)
		check(is_equal_approx(enemy.config.ranged_cooldown, 4.0 * [1.0, 0.9, 0.8][day-1]), "hybrid throw cooldown day %d" % day)
		check(enemy.config.damage == 1 and enemy.config.reward == 2 and is_equal_approx(enemy.config.windup, original.windup), "damage reward windup unchanged")
		check(original.max_health == 13 and original.speed == 120.0 and original.recovery == 0.75, "shared resource untouched")
		enemy.health -= 5
		WorldDayRules.apply_enemy(enemy, 3)
		check(enemy.health == hp-5 and is_equal_approx(enemy.config.speed, speed), "rebind and later day neither heal nor stack")
		enemy.free()
	var mono: MonochromeEntity = (load("res://enemies/monochrome_entity.tscn") as PackedScene).instantiate() as MonochromeEntity
	root.add_child(mono)
	WorldDayRules.apply_enemy(mono, 3)
	check(mono.health == 21 and mono.config.speed == 240, "advanced entity excluded")
	mono.free()
	var tian: TianWarrior = (load("res://enemies/tian_warrior.tscn") as PackedScene).instantiate() as TianWarrior
	root.add_child(tian)
	WorldDayRules.apply_enemy(tian, 3)
	check(tian.health == 31 and tian.config.speed == 300, "Tian uses independent baseline despite ColorlessEntity inheritance")
	tian.free()
	await process_frame
	print("WORLD_DAY_RULES_TESTS checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
