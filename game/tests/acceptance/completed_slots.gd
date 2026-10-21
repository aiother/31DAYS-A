extends "res://tests/acceptance/acceptance_harness.gd"
## SYS-004 adapter: fixtures, checkpoint and the original click acceptance.
func configuration() -> Dictionary:
	var snapshot: Dictionary = SlotStore.new().fresh()
	snapshot["checkpoint"] = TrenchPassageSession.PASSAGE_CHECKPOINT
	snapshot["day"] = 3
	for flag: String in [StartRoomSession.BIRTH,RescueBattlefieldSession.RESCUE_DONE_EVENT,TrenchPassageRoom.CLEARED,TrenchPassageRoom.CHALLENGE,TrenchPassageRoom.FORWARD]: snapshot["events"][flag] = true
	FinalClock.start(snapshot)
	for flag: String in [FinalClock.WON,FinalClock.TALK,FinalClock.END]: snapshot["events"][flag] = true
	var backup: Dictionary = snapshot.duplicate(true)
	backup["balance"] = 2
	return {"id":"SYS-004","marker":"COMPLETED_SLOTS_TESTS","scene":preload("res://world/final_battle_session.tscn"),"snapshots":{1:[backup,snapshot]},"enter":false,"instructions":"SYS-004 独立临时槽1（已通关）\n继续：游戏已通关且停留选槽。\n新游戏并确认：正常开始；关闭窗口清理临时存档。"}

func slot_button(title: String) -> Button:
	for child: Node in (session.ui.get("_menu") as VBoxContainer).get_children():
		if child is HBoxContainer:
			for item: Node in child.get_children():
				if item is Button and item.text == title: return item as Button
			break
	return null

func menu_button(title: String) -> Button:
	for child: Node in (session.ui.get("_menu") as VBoxContainer).get_children():
		if child is Button and child.text == title: return child as Button
	return null

func disk_bytes() -> Dictionary:
	var result: Dictionary = {}
	for suffix: String in ["",".bak",".tmp"]:
		var path: String = session.store.path_for(1)+suffix
		result[suffix] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	return result

func self_test() -> void:
	var before: Dictionary = disk_bytes()
	check(before[""] != null and before[".bak"] != null, "real primary and backup fixtures exist")
	await click(slot_button("继续"))
	check(session.ui.get("_mode") == "slots" and not session.has_session(), "acceptance continue stays in the real slot menu")
	check((session.ui.get("_error_label") as Label).text == "游戏已通关" and disk_bytes() == before, "acceptance prompt and byte preservation")
	await capture("blocked")
	await click(slot_button("新游戏"))
	await click(menu_button("确认开始"))
	check(session.has_session() and not bool(session.data["events"].get(FinalClock.END,false)), "acceptance new game starts")
	await capture("new-game")
