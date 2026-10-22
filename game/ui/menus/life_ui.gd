extends CanvasLayer
## T7 graybox menus; checkpoint sessions expose disk slots and safe exit.
@onready var player: PlayerController = get_parent().get_node("Player") as PlayerController
var _root: Control
## Control hint kept by the user at UI-002 (small paper tag under the emblem).
const HINT: String = "K / B 滑步 · 长按 L / Y 恢复"
const MEDKIT_HINT: String = " · Q / Back 药包"
const HINT_TOP: float = 322.0
var _health: Label
var _hud: FormalHud
var _pause: PauseMenu
var _save_toast: SaveToast
## Quitting is replaceable so tests can confirm save-and-quit without ending the run.
var _quit_handler: Callable
var _black: ColorRect
var _edges: Array[ColorRect] = []
var _panel: PanelContainer
var _menu: VBoxContainer
var _mode: String = ""
var _error_label: Label
var _enemy_intro: PanelContainer
var _enemy_intro_remaining: float = 0.0
var _intro_leaving: bool = false
var _intro_tween: Tween
## UI-004 formal title and slot screens; they draw over every other page.
var _title: TitleScreen
var _slots: SlotSelect
## Where settings were opened from outside the pause menu: "title" or "death".
var _settings_over: String = ""
## UI-005 formal death sheet (A-014).
var _death: OutcomeSheet

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_quit_handler = get_tree().quit
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# UI-002: the formal HUD draws life, possibility, pearls and time. _health is
	# now only the control hint under the emblem; story scenes still hide the
	# HUD through it, so the HUD follows its visibility.
	_hud = FormalHud.new()
	_root.add_child(_hud)
	# The error prompt stacks below the hint instead of a fixed y.
	var status: VBoxContainer = VBoxContainer.new()
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.position = Vector2(40, HINT_TOP)
	status.custom_minimum_size.x = 900
	status.add_theme_constant_override("separation", 16)
	_root.add_child(status)
	_health = Label.new()
	_health.theme = UiTheme.get_theme()
	_health.add_theme_font_size_override("font_size", UiTheme.SIZE_SMALL)
	_health.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_health.text = HINT
	status.add_child(_health)
	_health.visibility_changed.connect(func() -> void: _hud.visible = _health.visible)
	_hud.setup(player, get_parent(), _health)
	# UI-003 save feedback: shown when a new checkpoint reaches the disk, in the
	# top-right corner (user, 2026-10-21).
	_save_toast = SaveToast.new()
	_save_toast.session = get_parent()
	_root.add_child(_save_toast)
	if get_parent().has_signal("checkpoint_saved"):
		get_parent().connect("checkpoint_saved", func(_id: String) -> void: _save_toast.show_saved())
	_error_label = Label.new()
	_error_label.add_theme_font_size_override("font_size", 22)
	_error_label.modulate = Color(1, 0.5, 0.35)
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.hide()
	status.add_child(_error_label)
	_enemy_intro = PanelContainer.new()
	_enemy_intro.position = Vector2(1390, 100)
	_enemy_intro.size = Vector2(460, 220)
	_root.add_child(_enemy_intro)
	var intro_text: Label = Label.new()
	intro_text.text = "无色实体\n\n这里不安全。\n观察攻击前摇，寻找反击或闪避机会。"
	intro_text.add_theme_font_size_override("font_size", 22)
	_enemy_intro.add_child(intro_text)
	_enemy_intro.hide()
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
	# UI-005: the death sheet sits under the pause menu, so settings opened
	# from it cover it.
	_death = OutcomeSheet.new()
	_death.dim = 0.0
	_death.question_closed.connect(func() -> void:
		if _mode == "confirm_quit" and _death.visible: _mode = "death")
	_root.add_child(_death)
	_pause = PauseMenu.new()
	var actions: Dictionary = {"continue": resume_game, "settings": show_settings, "quit": _quit_game,
		"quit_label": "保存并退出" if get_parent().has_method("save_current") else "退出游戏"}
	# UI-005: the title exists, so the kept slot entry becomes 返回标题.
	if get_parent().has_method("return_to_title"):
		actions["title"] = _confirm_title
	_pause.setup(get_parent(), _hud, actions)
	_root.add_child(_pause)
	_pause.returned.connect(_on_pause_returned)
	_title = TitleScreen.new()
	_root.add_child(_title)
	_slots = SlotSelect.new()
	_slots.on_back = _slots_back
	_slots.on_pick = _pick_slot
	_slots.dialog_closed.connect(func() -> void:
		if _mode == "confirm_new": _mode = "slots")
	_root.add_child(_slots)
	player.life.death_menu_ready.connect(show_death)

func _process(_delta: float) -> void:
	if not get_tree().paused:
		_enemy_intro_remaining = maxf(0.0, _enemy_intro_remaining - _delta)
		if _enemy_intro_remaining == 0.0 and _enemy_intro.visible and not _intro_leaving:
			_intro_leaving = true
			_intro_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP)
			_intro_tween.tween_property(_enemy_intro, "position:x", 1920.0, 0.2)
			_intro_tween.tween_callback(_enemy_intro.hide)
	var life: PlayerLife = player.life
	_health.text = HINT + (MEDKIT_HINT if get_parent().has_method("medkit_count") else "")
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
			# Settings opened from the title closes back to the title.
			if _pause.visible and _mode == "settings":
				_pause.back()
			get_viewport().set_input_as_handled()
			return
		if player.life.state == PlayerLife.State.DEATH_MENU:
			show_death()
		elif _mode == "pause":
			resume_game()
		elif _pause.visible and _mode in ["settings", "confirm_quit", "confirm_title"]:
			_pause.back()
		else:
			show_pause()
		get_viewport().set_input_as_handled()

func _clear_menu(title: String, mode: String) -> void:
	for child: Node in _menu.get_children():
		_menu.remove_child(child)
		child.queue_free()
	_hide_screens()
	_pause.close()
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

## UI-003: formal pause menu (current task now sits under the clock).
func show_pause() -> void:
	_panel.hide()
	_hide_screens()
	_settings_over = ""
	_pause_below_screens()
	_mode = "pause"
	get_tree().paused = true
	_pause.open()

func resume_game() -> void:
	# Without a session there is no game to return to (e.g. 继续游戏 on the
	# pause sheet behind settings opened from the title).
	if get_parent().has_method("has_session") and not get_parent().call("has_session"):
		show_title()
		return
	_hide_screens()
	if get_parent().has_method("blocks_resume") and get_parent().call("blocks_resume"):
		_panel.hide()
		_pause.close()
		_mode = ""
		get_tree().paused = true
		return
	if player.life.state == PlayerLife.State.DEATH_MENU:
		show_death()
		return
	_panel.hide()
	_pause.close()
	_mode = ""
	get_tree().paused = false

## UI-005 death sheet (A-014): from the checkpoint, 返回标题, settings and
## quit, over the existing whiten-then-dark edge animation.
func show_death() -> void:
	_panel.hide()
	_hide_screens()
	_pause.close()
	_pause_below_screens()
	_settings_over = ""
	_mode = "death"
	get_tree().paused = true
	var checkpoint_mode: bool = get_parent().has_method("start_slot")
	var entries: Array = [["从检查点继续" if checkpoint_mode else "重新挑战（灰盒出生点）", restart_challenge]]
	if get_parent().has_method("return_to_title"):
		entries.append(["返回标题", _title_from_death])
	entries.append(["设置", _death_settings])
	entries.append(["退出游戏", _quit_game])
	var note: String = "满生命复活 · 可能性减半向下取整 · 负数清零" if checkpoint_mode else "此开发场景不使用检查点存档"
	_death.open("你倒下了", note, DuskStyle.LIFE, entries)
	_death.set_error(_error_label.text)
	_error_label.hide()

func _title_from_death() -> void:
	get_parent().call("return_to_title")

## Settings over the death sheet; 返回 / Esc / Back come back to it.
func _death_settings() -> void:
	_settings_over = "death"
	_mode = "settings"
	_pause.visible = true
	_pause.show_settings(true)

func restart_challenge() -> void:
	_death.close()
	_error_label.visible = not _error_label.text.is_empty()
	_panel.hide()
	_mode = ""
	get_tree().paused = false
	get_parent().call("restart_challenge")

## Settings is a secondary page of the formal pause menu, covering its clock.
func show_settings() -> void:
	# Public entry from anywhere (review R1): outside the pause menu, open it
	# visible and paused first, which also closes any graybox panel.
	if not _pause.visible:
		show_pause()
	_mode = "settings"
	_pause.show_settings()

func _quit_game() -> void:
	if get_parent().has_method("save_current"):
		confirm_quit()
		return
	get_tree().paused = false
	_quit_handler.call()

## Errors land on the open title or slot screen's prompt line, clear of the
## bookmarks; otherwise on the label under the control hint.
func save_failed(message: String) -> void:
	_error_label.text = message
	var screen: MenuScreen = _open_screen()
	var final_ui: Variant = get_parent().get("final_ui")
	if screen != null:
		screen.set_prompt(message)
		_error_label.hide()
	elif _death != null and _death.visible:
		# UI-005: the death and outcome sheets carry their own error line.
		_death.set_error(message)
		_error_label.hide()
	elif final_ui is FinalBattleUI and (final_ui as FinalBattleUI).sheet.visible:
		(final_ui as FinalBattleUI).sheet.set_error(message)
		_error_label.hide()
	else:
		_error_label.visible = not message.is_empty()

func _open_screen() -> MenuScreen:
	if _slots != null and _slots.visible:
		return _slots
	if _title != null and _title.visible:
		return _title
	return null

func _hide_screens() -> void:
	if _title == null:
		return
	var was_open: bool = _open_screen() != null or _death.visible
	_death.close()
	_title.close_dialog(false)
	_slots.close_dialog(false)
	_title.hide()
	_slots.hide()
	if was_open:
		_error_label.visible = not _error_label.text.is_empty()

## UI-004 main menu (EXP-003 A · 黄昏远景). With a session still open it goes
## through SYS-008's return_to_title(), which saves and reloads first.
func show_title() -> void:
	var lab: CheckpointLab = get_parent() as CheckpointLab
	if lab == null:
		return
	if lab.has_session():
		lab.return_to_title()
		return
	_panel.hide()
	_pause.close()
	_pause_below_screens()
	_hide_screens()
	_settings_over = ""
	_mode = "title"
	get_tree().paused = true
	_title.open(lab.has_any_save(), {"new": show_slots.bind("new"), "continue": show_slots.bind("continue"),
		"settings": _title_settings, "quit": _quit_now})
	_error_label.hide()
	if not _error_label.text.is_empty():
		_title.set_prompt(_error_label.text)

## UI-004 slot selection (EXP-003 1 · 书签 with sky strips). The name and
## no-argument call are kept for the pause entry and the ending panels.
func show_slots(selected_mode: String = "continue") -> void:
	var lab: CheckpointLab = get_parent() as CheckpointLab
	if lab == null:
		return
	if lab.has_session() and not lab.save_current():
		return
	_panel.hide()
	_pause.close()
	_hide_screens()
	_mode = "slots"
	get_tree().paused = true
	_slots.open(selected_mode, lab.slot_summaries(), "返回当前游戏" if lab.has_session() else "返回主界面")
	_error_label.hide()

func _slots_back() -> void:
	var lab: CheckpointLab = get_parent() as CheckpointLab
	if lab != null and lab.has_session():
		resume_game()
	else:
		show_title()

## index is 0-based. Continue loads through start_slot (A-013 answers
## 游戏已通关 there); new game confirms first, warning before an overwrite.
func _pick_slot(index: int) -> void:
	var state: String = _slots.state(index)
	var name: String = _slots.slot_name(index)
	if _slots.mode == "continue":
		match state:
			"progress", "completed":
				_select_slot(index + 1, false)
			"empty":
				_slots.set_prompt("%s是空的，请从主界面选择新游戏" % name)
			_:
				_slots.set_prompt("%s无法读取，可在新游戏中覆盖" % name)
		return
	_confirm_new_slot(index + 1, state != "empty")

func _select_slot(selected: int, new_game: bool) -> void:
	save_failed("")
	(get_parent() as CheckpointLab).start_slot(selected, new_game)

func _confirm_new_slot(selected: int, occupied: bool) -> void:
	if not _slots.visible or _slots.mode != "new":
		show_slots("new")
	_mode = "confirm_new"
	var name: String = _slots.slot_name(selected - 1)
	_slots.ask("在%s开始新游戏？%s" % [name, "\n将覆盖此槽现有进度" if occupied else ""], "覆盖并开始" if occupied else "开始",
		_select_slot.bind(selected, true), _slots.cards[selected - 1])

## UI-006: the same settings page as the pause menu, centred over the
## dimmed title; 返回 / Esc / Back come back to the title on 设置.
func _title_settings() -> void:
	_settings_over = "title"
	_title.close_dialog(false)
	_root.move_child(_pause, -1)
	_pause.visible = true
	_mode = "settings"
	get_tree().paused = true
	_pause.show_settings(true)

func _on_pause_returned() -> void:
	var origin: String = _settings_over
	_settings_over = ""
	if origin.is_empty():
		_mode = "pause"
		return
	_pause.close()
	_pause_below_screens()
	_mode = origin
	var entry: Button = _title.button("设置") if origin == "title" else _death.button("设置")
	if entry != null:
		entry.grab_focus()

## UI-005: the pause menu's 返回标题 asks first, then goes through SYS-008's
## return_to_title(); a failed save stays with the error on the page.
func _confirm_title() -> void:
	_mode = "confirm_title"
	_pause.show_title_confirm(_title_from_pause, _error_label.text)

func _title_from_pause() -> void:
	if not get_parent().call("return_to_title"):
		_pause.set_error(_error_label.text)

## The pause menu normally sits under the title and slot screens.
func _pause_below_screens() -> void:
	if _pause.get_index() > _title.get_index():
		_root.move_child(_pause, _title.get_index())

## The title already asked; nothing is open to save.
func _quit_now() -> void:
	get_tree().paused = false
	_quit_handler.call()

func confirm_quit() -> void:
	if _death.visible:
		_mode = "confirm_quit"
		_death.ask("保存并退出游戏？\n下次从最近的检查点继续", "保存并退出", _save_and_quit)
		return
	if _pause.visible:
		_mode = "confirm_quit"
		_pause.show_confirm(_save_and_quit, _error_label.text)
		return
	_clear_menu("保存并退出游戏？", "confirm_quit")
	_button("保存并退出", _save_and_quit, true)
	_button("返回", _return_from_quit)

func _return_from_quit() -> void:
	if get_parent().has_method("has_session") and not get_parent().call("has_session"):
		show_title()
	elif player.life.state == PlayerLife.State.DEATH_MENU:
		show_death()
	else:
		show_pause()

func _save_and_quit() -> void:
	if not (get_parent() as CheckpointLab).save_current():
		# The pause sheet covers the error prompt, so the page repeats it.
		_pause.set_error(_error_label.text)
		return
	get_tree().paused = false
	_quit_handler.call()

func show_room_boundary(_target: String) -> void:
	_clear_menu("前方道路", "room_boundary")
	var label: Label = Label.new()
	label.text = "本次灰盒体验到此\n前方区域将在下一阶段开放"
	label.add_theme_font_size_override("font_size", 22)
	_menu.add_child(label)
	_button("继续探索当前区域", resume_game, true)
	_button("保存并退出", confirm_quit)

func show_enemy_intro(duration: float, text: String = "无色实体\n\n这里不安全。\n观察攻击前摇，寻找反击或闪避机会。") -> void:
	(_enemy_intro.get_child(0) as Label).text = text
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	_intro_leaving = false
	_enemy_intro_remaining = duration
	_enemy_intro.position.x = 1920
	_enemy_intro.show()
	_intro_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_intro_tween.tween_property(_enemy_intro, "position:x", 1920.0 - _enemy_intro.size.x, 0.2)

func hide_enemy_intro() -> void:
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	_intro_leaving = false
	_enemy_intro_remaining = 0.0
	_enemy_intro.hide()
