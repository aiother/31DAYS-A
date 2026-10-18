class_name WorldDayRules
extends RefCounted
## Boolean event keys keep version-1 saves readable by the existing store.
const ENABLED: String = "world:day_rules_v1"
const IDS: Array[String] = ["TY_10002_1", "HD_20001_2", "HD_20001_3", "NSZC_10001_1"]

static func completed(id: String) -> String:
	return "TY_10002_1_N002:completed" if id == IDS[0] else "rescue:%s:completed" % id

static func failed(id: String) -> String:
	return "TY_10002_1_N002:failed" if id == IDS[0] else "rescue:%s:failed" % id

static func expired_key(id: String) -> String:
	return "rescue:%s:expired" % id

static func grace_key(id: String) -> String:
	return "rescue:%s:legacy_grace" % id

static func migrate(data: Dictionary) -> void:
	var events: Dictionary = data["events"]
	if bool(events.get(ENABLED, false)): return
	for id: String in IDS:
		# Town had no dedicated seen event before this revision; its rescue guide
		# is the persisted evidence that the player knew about this opportunity.
		var seen: String = "TY_10001_1_N004" if id == IDS[0] else "rescue:%s:seen" % id
		if bool(events.get(seen, false)) and not bool(events.get(completed(id), false)) and not bool(events.get(failed(id), false)):
			events[grace_key(id)] = true
	events[ENABLED] = true

static func expired(data: Dictionary, id: String) -> bool:
	var events: Dictionary = data.get("events", {})
	if bool(events.get(completed(id), false)) or bool(events.get(failed(id), false)) or bool(events.get(grace_key(id), false)):
		return false
	if bool(events.get(expired_key(id), false)): return true
	if not bool(events.get(ENABLED, false)): return false
	return int(data.get("day", 1)) >= 3 and (id != IDS[3] or float(data.get("day3_remaining", 1800.0)) <= 0.0)

static func sync(data: Dictionary) -> void:
	if data.is_empty(): return
	for id: String in IDS:
		if expired(data, id): data["events"][expired_key(id)] = true

static func apply_enemy(enemy: ColorlessEntity, day: int) -> void:
	if enemy is MonochromeEntity or enemy is TianWarrior or enemy.has_meta("spawn_day"): return
	enemy.set_meta("spawn_day", day)
	if day <= 1: return
	var config: ColorlessConfig = enemy.config.duplicate() as ColorlessConfig
	var stage: int = clampi(day, 1, 3)
	config.max_health = 15 if stage == 2 else 17
	config.speed *= 1.1 if stage == 2 else 1.2
	var cooldown: float = 0.9 if stage == 2 else 0.8
	config.recovery *= cooldown
	config.ranged_cooldown *= cooldown
	enemy.config = config
	enemy.health = config.max_health
	enemy._update_status_label()
