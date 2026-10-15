extends CanvasLayer
## T7 graybox menus; checkpoint sessions expose disk slots and safe exit.
@onready var player: PlayerController = get_parent().get_node("Player") as PlayerController
var _root: Control
var _health: Label
var _black: ColorRect
var _edges: Array[ColorRect] = []
var _panel: PanelContainer
var _menu: VBoxContainer
var _mode: String = ""
var _error_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_health = Label.new()
	_health.position = Vector2(64, 258)
	_health.add_theme_font_size_override("font_size", 24)
	_root.add_child(_health)
	_error_label = Label.new()
	_error_label.position = Vector2(64, 410)
	_error_label.add_theme_font_size_override("font_size", 22)
	_error_label.modulate = Color(1, 0.5, 0.35)
	_root.add_child(_error_label)
	for i: int in range(4):
		var edge: ColorRect = ColorRect.new()
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		edge.color = Color(1, 1, 1, 0)
		_root.add_child(edge)
		_edges.append(edge)
	_black = ColorRect.new()
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.color = Color(0, 0, 0, 0)
	_root.add_child(_black)
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = PanelContainer.new()
	_root.add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(600, 430)
	_panel.offset_left = -300
	_panel.offset_top = -215
	_panel.offset_right = 300
	_panel.offset_bottom = 215
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.1, 0.13, 0.98)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	_panel.add_theme_stylebox_override("panel", style)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 16)
	_panel.add_child(_menu)
	_panel.hide()
	player.life.death_menu_ready.connect(show_death)

func _process(_delta: float) -> void:
	var life: PlayerLife = player.life
	var protection: String = ""
	if life.protection_remaining > 0.0 and life.is_alive():
		protection = " · 保护 %.1f 秒" % life.protection_remaining
	_health.text = "生命 %d / %d%s" % [life.health, life.config.max_health, protection]
	var actions: PlayerPossibility = player.possibility
	_health.text += "\n可能性 %d / %d · K/B 滑步 · 长按 L/Y 恢复" % [actions.balance, actions.config.maximum]
	if actions.state == PlayerPossibility.State.HEALING:
		_health.text += "\n恢复中 %.1f / %.1f 秒" % [actions.config.heal_duration - actions.remaining, actions.config.heal_duration]
	elif actions.busy():
		_health.text += "\n%s滑步 · 连续 %d / 3" % ["透支" if actions.poor_dodge else "", actions.chain]
	_health.modulate = Color(1, 0.5, 0.4) if life.health <= 1 else Color.WHITE
	var edge_alpha: float = 0.0
	var black_alpha: float = 0.0
	if life.state == PlayerLife.State.DOWNED:
		edge_alpha = (1.0 - life.phase_remaining / life.config.downed_duration) * 0.7
	elif life.state == PlayerLife.State.FADING:
		edge_alpha = 0.7
		black_alpha = 1.0 - life.phase_remaining / life.config.death_fade_duration
	elif life.state == PlayerLife.State.DEATH_MENU:
		black_alpha = 1.0
	_black.color.a = black_alpha
	var size: Vector2 = _root.size
	var rects: Array[Rect2] = [Rect2(0, 0, size.x, 40), Rect2(0, size.y - 40, size.x, 40), Rect2(0, 40, 40, size.y - 80), Rect2(size.x - 40, 40, 40, size.y - 80)]
	for i: int in range(4):
		_edges[i].position = rects[i].position
		_edges[i].size = rects[i].size
		_edges[i].color.a = edge_alpha

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_parent().has_method("has_session") and not get_parent().call("has_session"):
			get_viewport().set_input_as_handled()
			return
		if player.life.state == PlayerLife.State.DEATH_MENU:
			show_death()
		elif _mode == "pause":
			resume_game()
		else:
			show_pause()
		get_viewport().set_input_as_handled()

func _clear_menu(title: String, mode: String) -> void:
	for child: Node in _menu.get_children():
		_menu.remove_child(child)
		child.queue_free()
	_mode = mode
	_panel.show()
	get_tree().paused = true
	var label: Label = Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	_menu.add_child(label)

func _button(text: String, callback: Callable, focus: bool = false) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 54
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(callback)
	_menu.add_child(button)
	if focus:
		button.grab_focus()
	return button

func show_pause() -> void:
	_clear_menu("已暂停", "pause")
	_button("继续游戏", resume_game, true)
	_button("设置", show_settings)
	if get_parent().has_method("start_slot"):
		_button("存档槽", show_slots)
	_button("退出游戏", _quit_game)

func resume_game() -> void:
	if player.life.state == PlayerLife.State.DEATH_MENU:
		show_death()
		return
	_panel.hide()
	_mode = ""
	get_tree().paused = false

func show_death() -> void:
	_clear_menu("你倒下了", "death")
	var checkpoint_mode: bool = get_parent().has_method("start_slot")
	_button("从检查点继续" if checkpoint_mode else "重新挑战（灰盒出生点）", restart_challenge, true)
	_button("退出游戏", _quit_game)
	var note: Label = Label.new()
	note.text = "满生命复活 · 可能性减半向下取整 · 负数清零" if checkpoint_mode else "此开发场景不使用检查点存档"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 20)
	_menu.add_child(note)

func restart_challenge() -> void:
	_panel.hide()
	_mode = ""
	get_tree().paused = false
	get_parent().call("restart_challenge")

func show_settings() -> void:
	_clear_menu("设置", "settings")
	var volume_label: Label = Label.new()
	volume_label.text = "音量"
	volume_label.add_theme_font_size_override("font_size", 22)
	_menu.add_child(volume_label)
	var volume: HSlider = HSlider.new()
	volume.min_value = 0
	volume.max_value = 100
	volume.value = AudioServer.get_bus_volume_linear(0) * 100.0
	volume.custom_minimum_size.y = 36
	volume.value_changed.connect(func(value: float) -> void: AudioServer.set_bus_volume_linear(0, value / 100.0))
	_menu.add_child(volume)
	var resolution: OptionButton = OptionButton.new()
	resolution.add_item("窗口尺寸 1280 × 720")
	resolution.add_item("窗口尺寸 1920 × 1080")
	resolution.select(1 if DisplayServer.window_get_size().x >= 1920 else 0)
	resolution.item_selected.connect(func(index: int) -> void: DisplayServer.window_set_size(Vector2i(1280, 720) if index == 0 else Vector2i(1920, 1080)))
	_menu.add_child(resolution)
	var fullscreen: CheckButton = CheckButton.new()
	fullscreen.text = "全屏"
	fullscreen.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen.toggled.connect(func(enabled: bool) -> void: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED))
	_menu.add_child(fullscreen)
	_button("返回", show_pause, true)

func _quit_game() -> void:
	if get_parent().has_method("save_current"):
		confirm_quit()
		return
	get_tree().paused = false
	get_tree().quit()

func save_failed(message: String) -> void:
	_error_label.text = message

func show_slots() -> void:
	var lab: CheckpointLab = get_parent() as CheckpointLab
	if lab == null:
		return
	if lab.has_session() and not lab.save_current():
		return
	_clear_menu("末日前31天 · 灰盒存档", "slots")
	for selected: int in range(1, SlotStore.SLOT_COUNT + 1):
		var snapshot: Dictionary = lab.store.load_slot(selected)
		var error: String = lab.store.last_error
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		_menu.add_child(row)
		var label: Label = Label.new()
		label.text = "槽 %d · %s" % [selected, "空" if snapshot.is_empty() and error.is_empty() else ("不可读取" if snapshot.is_empty() else "HP %d · 可能性 %d" % [snapshot["health"], snapshot["balance"]])]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 20)
		row.add_child(label)
		if not snapshot.is_empty():
			var resume: Button = Button.new()
			resume.text = "继续"
			resume.add_theme_font_size_override("font_size", 22)
			resume.custom_minimum_size = Vector2(80, 54)
			resume.pressed.connect(_select_slot.bind(selected, false))
			row.add_child(resume)
		var start: Button = Button.new()
		start.text = "新游戏"
		start.add_theme_font_size_override("font_size", 22)
		start.custom_minimum_size = Vector2(100, 54)
		start.pressed.connect(_confirm_new_slot.bind(selected, not snapshot.is_empty() or not error.is_empty()))
		row.add_child(start)
		if selected == 1:
			start.grab_focus()
	if lab.has_session():
		_button("返回当前游戏", resume_game)
	_button("退出游戏", confirm_quit)

func _select_slot(selected: int, new_game: bool) -> void:
	_error_label.text = ""
	(get_parent() as CheckpointLab).start_slot(selected, new_game)

func _confirm_new_slot(selected: int, occupied: bool) -> void:
	_clear_menu("在槽 %d 开始新游戏？%s" % [selected, "\n将覆盖此槽现有进度" if occupied else ""], "confirm_new")
	_button("确认开始", _select_slot.bind(selected, true), true)
	_button("返回", show_slots)

func confirm_quit() -> void:
	_clear_menu("保存并退出游戏？", "confirm_quit")
	_button("保存并退出", _save_and_quit, true)
	_button("返回", _return_from_quit)

func _return_from_quit() -> void:
	if get_parent().has_method("has_session") and not get_parent().call("has_session"):
		show_slots()
	elif player.life.state == PlayerLife.State.DEATH_MENU:
		show_death()
	else:
		show_pause()

func _save_and_quit() -> void:
	if not (get_parent() as CheckpointLab).save_current():
		return
	get_tree().paused = false
	get_tree().quit()
