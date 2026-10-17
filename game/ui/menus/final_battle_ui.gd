class_name FinalBattleUI
extends CanvasLayer
signal retry_requested
signal quit_requested
signal slots_requested
var clock_label: Label
var panel: PanelContainer
var column: VBoxContainer
var message: Label
var curtain: ColorRect
var mode: String = ""

func _ready() -> void:
	layer = 18
	process_mode = Node.PROCESS_MODE_ALWAYS
	clock_label = Label.new()
	clock_label.position = Vector2(1360,280)
	clock_label.add_theme_font_size_override("font_size",24)
	add_child(clock_label)
	curtain = ColorRect.new()
	curtain.size = Vector2(1920,1080)
	curtain.color = Color(0.12,0.055,0.035,1)
	add_child(curtain)
	curtain.hide()
	panel = PanelContainer.new()
	panel.position = Vector2(500,310)
	panel.custom_minimum_size = Vector2(920,400)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.025,0.025,0.03,0.97)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel",style)
	add_child(panel)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation",24)
	panel.add_child(column)
	message = Label.new()
	message.custom_minimum_size = Vector2(832,160)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size",30)
	column.add_child(message)
	panel.hide()

func _button(text: String, action: Callable) -> void:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(800,56)
	button.add_theme_font_size_override("font_size",24)
	button.pressed.connect(action)
	column.add_child(button)

func _clear(next_mode: String) -> void:
	mode = next_mode
	for child: Node in column.get_children():
		if child!=message:
			column.remove_child(child)
			child.queue_free()
	panel.show()

func show_timeout(can_retry: bool = true, budget: float = 900) -> void:
	if mode=="timeout":
		return
	_clear("timeout")
	clock_label.hide()
	message.text = "最终战超时\n可确认重新开始本次最终战的计时预算。\n敌人重置，不重复救场或补满可能性。"
	if can_retry:
		var seconds: int = ceili(budget)
		message.text = "最终战超时 · 本次可恢复 %02d:%02d\n确认后重置整场敌人和计时。\n不重复救场，不补满可能性。" % [seconds/60,seconds%60]
		_button("确认重试最终战（重新计时）",func() -> void: retry_requested.emit())
	else:
		message.text = "第三日已结束，开战时已无可用计时预算。\n可选择其他存档或新游戏。"
		_button("存档槽 / 新游戏",func() -> void: slots_requested.emit())
	_button("保存并退出",func() -> void: quit_requested.emit())

func show_ending(progress: float = 1.0) -> void:
	clock_label.hide()
	if mode!="ending":
		_clear("ending")
		curtain.show()
	message.text = "幸存者的欢呼声中，10向你伸出手。\n夕阳落下，新的道路仍在前方。\n（V0.1临时演出占位）"
	curtain.modulate.a = clampf(progress,0,1)

func show_finished() -> void:
	clock_label.hide()
	_clear("finished")
	curtain.show()
	curtain.modulate.a = 1
	message.text = "《末日前31天》V0.1 灰盒结束\n最终战胜利 · 正式美术、台词与播片待制作"
	_button("存档槽 / 新游戏",func() -> void: slots_requested.emit())
	_button("保存并退出",func() -> void: quit_requested.emit())

func reset_panel() -> void:
	mode = ""
	panel.hide()
	curtain.hide()
