extends "res://tests/acceptance/acceptance_harness.gd"
## UI-002 adapter: isolated slots for the formal HUD and time display G4.
## Slot 1 reaches the next-day warning and rollover quickly; slots 2 and 3 are
## the third day at the trench passage with a long and a short final budget.
const LONG_BUDGET: float = 1500.0
const SHORT_BUDGET: float = 552.0
const DAY_ONE_LEFT: float = 200.0
## Clear of the emblem, hint, final countdown, banner and horizon (ENV-006 N2):
## full instructions on the slot menu, only the live fields once a slot plays.
const PANEL_POSITION: Vector2 = Vector2(40, 560)
const PLAY_PANEL_POSITION: Vector2 = Vector2(1240, 735)

func fixture(day: int, remaining: float) -> Dictionary:
	var snapshot: Dictionary = SlotStore.new().fresh()
	snapshot["events"][StartRoomSession.BIRTH] = true
	snapshot["day"] = day
	snapshot["day_remaining"] = remaining
	snapshot["day3_remaining"] = remaining if day == 3 else DayClock.CONFIG.day_seconds
	snapshot["balance"] = 6
	# A bare SlotStore defaults to the debug lab checkpoint; the main entry starts here.
	snapshot["checkpoint"] = StartRoomSession.CHECKPOINT
	if day == 3:
		snapshot["checkpoint"] = TrenchPassageSession.PASSAGE_CHECKPOINT
		for flag: String in [RescueBattlefieldSession.RESCUE_DONE_EVENT, TrenchPassageRoom.CLEARED, TrenchPassageRoom.CHALLENGE, TrenchPassageRoom.FORWARD]:
			snapshot["events"][flag] = true
	return snapshot

func configuration() -> Dictionary:
	return {"id":"UI-002", "marker":"UI002_ACCEPTANCE_TESTS", "scene":preload("res://world/final_battle_session.tscn"),
		"snapshots":{1:fixture(1, DAY_ONE_LEFT), 2:fixture(3, LONG_BUDGET), 3:fixture(3, SHORT_BUDGET)}, "enter":false,
		"instructions":"UI-002 独立临时存档（关闭窗口自动清理）\n槽1 第1日剩3:20：约20秒后右下换日提示，约3分20秒后换日纸签\n槽2 第3日剩25:00：向右进入中心战场，最终战“时间加速”走到15:00\n槽3 第3日剩9:12：同上，朱红“余时不足”\n任意槽：余额不足时长按恢复看闪红；连续闪避透支看失真"}

func _process(delta: float) -> void:
	super._process(delta)
	if not is_instance_valid(panel) or finishing or not is_instance_valid(session):
		return
	var note: Label = panel.get_node("ReadOnlyStatus") as Label
	note.position = PLAY_PANEL_POSITION if session.has_session() else PANEL_POSITION
	if session.has_session():
		var fields: Dictionary = status_fields()
		note.text = " · ".join(fields.keys().map(func(key: String) -> String: return "%s %s" % [key, str(fields[key])]))
		# The base panel just laid out the long instructions; shrink back to one line.
		note.size = Vector2.ZERO

func status_fields() -> Dictionary:
	var time: Dictionary = session.call("ui_time_state")
	return {"第几日":time.get("day", 0), "日内剩余":"%d 秒" % ceili(float(time.get("day_remaining", 0.0))),
		"最终战":("%d 秒" % ceili(float(time["final_remaining"]))) if bool(time.get("final_active", false)) else "未开始",
		"可能性":session.player.possibility.balance, "生命":session.player.life.health}

func hud() -> FormalHud:
	return session.ui.get("_hud") as FormalHud

func load_slot(selected: int) -> void:
	check(session.start_slot(selected, false), "acceptance slot %d loads" % selected)
	await frames(8)
	session = get_tree().current_scene as CheckpointLab

## The battlefield entry the user walks into, taken directly so the headless
## check does not depend on platforming.
func enter_battlefield() -> void:
	session._change_room(FinalBattleSession.BATTLEFIELD_ID)
	session.player.position = Vector2(450, 896)
	session.player.reset_kinematics()
	await frames(6)

func self_test() -> void:
	check((panel == null) or ((panel.get_node("ReadOnlyStatus") as Label).position == PANEL_POSITION), "slot menu instructions sit clear of the HUD")
	await load_slot(1)
	check((panel == null) or ((panel.get_node("ReadOnlyStatus") as Label).position == PLAY_PANEL_POSITION and not (panel.get_node("ReadOnlyStatus") as Label).text.contains("槽2")), "in play the panel keeps only live fields on the right")
	check(not hud().drawn.has("horizon") and int(hud().time_state()["day"]) == 1 and not hud().drawn.has("banner"), "slot 1 is on the first day without a load banner, time axis hidden (UI-011)")
	session.data["day_remaining"] = 170.0
	await frames(3)
	check(hud().drawn.has("warning"), "slot 1 reaches the next-day warning")
	await capture("day1-warning")
	await load_slot(2)
	await enter_battlefield()
	check(hud().drawn.has("final") and hud().drawn["final"]["label"] == "时间加速……", "slot 2 final battle starts with the spin-down")
	await capture("final-long")
	await load_slot(3)
	await enter_battlefield()
	check(hud().drawn.has("final") and hud().drawn["final"]["label"] == "最终战倒计时 · 余时不足" and hud().drawn["final"]["color"] == DuskStyle.LIFE, "slot 3 final battle warns in vermilion")
	await capture("final-short")
