class_name FinalBattleUI
extends CanvasLayer
## UI-005: formal sheets for the final battle timeout (A-011, 未来已失), the
## third-day exploration timeout (G-03) and the V0.1 ending (夕阳将至). Every
## 返回标题 goes through the session's return_to_title() (SYS-008), which saves
## first and stays here with the error when the save fails.
signal retry_requested
signal quit_requested
## Kept for the session's existing connection; the sheets no longer emit it
## (the title offers slots and new games now).
signal slots_requested
## Text source the session also writes (ending save failures).
var message: Label
var curtain: ColorRect
var sheet: OutcomeSheet
var mode: String = ""

func _ready() -> void:
	layer = 18
	process_mode = Node.PROCESS_MODE_ALWAYS
	curtain = ColorRect.new()
	curtain.size = Vector2(1920,1080)
	curtain.color = Color(0.12,0.055,0.035,1)
	add_child(curtain)
	curtain.hide()
	message = Label.new()
	message.hide()
	add_child(message)
	sheet = OutcomeSheet.new()
	add_child(sheet)

func _input(event: InputEvent) -> void:
	if mode in ["timeout","day_timeout","finished"] and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	# The session writes ending progress and save failures into message.
	if mode == "ending" and sheet.body != message.text:
		sheet.set_body(message.text)

func play_time() -> String:
	var session: Node = get_parent()
	var data: Dictionary = session.get("data") if session != null and session.get("data") is Dictionary else {}
	return "游玩时长 " + SlotSelect.play_time(float(data.get("play_seconds", 0.0)))

func return_to_title() -> void:
	if get_parent().has_method("return_to_title"):
		get_parent().call("return_to_title")

func show_day_timeout() -> void:
	if mode=="day_timeout":
		return
	mode = "day_timeout"
	message.text = "确认重试后返回当前检查点，恢复本日30分钟。\n保留当前生命、可能性与已保存进度；敌人重置。"
	sheet.dim = 0.6
	sheet.open("第三日时间已耗尽", message.text, DuskStyle.LIFE, [
		["确认重试第三日（返回检查点）", func() -> void: retry_requested.emit()],
		["返回标题", return_to_title]])

func show_timeout(can_retry: bool = true, budget: float = 900) -> void:
	if mode=="timeout":
		return
	mode = "timeout"
	var entries: Array = []
	if can_retry:
		var seconds: int = ceili(budget)
		message.text = "%s\n最终战超时 · 本次可恢复 %02d:%02d\n确认后重置整场敌人和计时。不重复救场，不补满可能性。" % [play_time(), seconds/60, seconds%60]
		entries.append(["确认重试最终战（重新计时）", func() -> void: retry_requested.emit()])
	else:
		message.text = "%s\n第三日已结束，开战时已无可用计时预算。" % play_time()
	entries.append(["返回标题", return_to_title])
	sheet.dim = 0.6
	sheet.open("未来已失", message.text, DuskStyle.LIFE, entries)

func show_ending(progress: float = 1.0) -> void:
	if mode!="ending":
		mode = "ending"
		curtain.show()
		message.text = "幸存者的欢呼声中，10向你伸出手。\n夕阳落下，新的道路仍在前方。\n（V0.1临时演出占位）"
		sheet.dim = 0.0
		sheet.open("", message.text, DuskStyle.INK, [])
	curtain.modulate.a = clampf(progress,0,1)

func show_finished() -> void:
	mode = "finished"
	curtain.show()
	curtain.modulate.a = 1
	message.text = "《末日前31天》V0.1 灰盒结束\n%s" % play_time()
	sheet.dim = 0.0
	sheet.open("夕阳将至", message.text, DuskStyle.INK, [["返回标题", return_to_title]])

func reset_panel() -> void:
	mode = ""
	sheet.close()
	curtain.hide()
