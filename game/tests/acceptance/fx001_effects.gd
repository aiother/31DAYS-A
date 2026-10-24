extends "res://tests/acceptance/ui009_battle.gd"
## FX-001 adapter: the formal combat feedback in real fights. Slot 1 is the
## second Room of the first day (colourless enemies to the right), slot 2 the
## trench passage before rescuing 10 (Tian warriors and a monochrome in the
## central battlefield), slot 3 the parasite Boss checkpoint.
func configuration() -> Dictionary:
	return {"id":"FX-001", "marker":"FX001_ACCEPTANCE_TESTS", "scene":preload("res://world/final_battle_session.tscn"),
		"snapshots":{1:entry(), 2:passage(false), 3:parasite()}, "enter":false,
		"instructions":"FX-001 正式战斗反馈特效 · 独立临时存档（关闭窗口自动清理）\n槽1 第1日第二间：向右遇到无色实体\n槽2 中心战场前（未救10）：进入战场打天人与单色\n槽3 寄生同伴者检查点：Boss 战\n看：普通攻击命中时刀被卡住约0.1秒（玩家与目标同停、目标抖动、刀光停在命中处后扫完），没打中不卡；\n普通命中不震屏，受击轻震；闪避（可能性不足时为朱红）、恢复、获得可能性、击倒、复活都有光痕特效；\n满可能性后闪避不应再出现获得光圈；暂停时特效与顿帧一起停住"}

func entry() -> Dictionary:
	var snapshot: Dictionary = fixture(1, DayClock.CONFIG.day_seconds)
	snapshot["checkpoint"] = TwoRoomSession.ENTRY_CHECKPOINT
	snapshot["balance"] = 10
	for key: String in [StartRoomSession.GUIDE]:
		snapshot["events"][key] = true
	return snapshot

func status_fields() -> Dictionary:
	var fields: Dictionary = super.status_fields()
	var director: CombatEffectDirector = session.player.get_node_or_null("EffectDirector") as CombatEffectDirector
	if director != null:
		fields["顿帧次数"] = director.stops
		fields["最近震屏"] = ("%.0f 像素" % float(director.last_shake["power"])) if not director.last_shake.is_empty() else "无"
	return fields

func self_test() -> void:
	for slot: int in [1, 3]:
		check(session.start_slot(slot, false), "acceptance slot %d loads" % slot)
		await frames(8)
		session = get_tree().current_scene as CheckpointLab
		var director: CombatEffectDirector = session.player.get_node_or_null("EffectDirector") as CombatEffectDirector
		check(director != null and director.effects != null and director.config.hit_stop_seconds == 0.10, "slot %d player carries the formal effects" % slot)
		await capture("slot%d" % slot)
