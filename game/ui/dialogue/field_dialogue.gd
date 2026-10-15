class_name FieldDialogue
extends CanvasLayer
signal finished
signal departure_confirmed
signal departure_cancelled
var active: bool = false
var confirming: bool = false
var line_index: int = 0
var _lines: PackedStringArray
var _config: DialogueConfig
var _count: float = 0.0
var _grace: float = 0.0
var panel: PanelContainer
var text: Label
var speaker: Label
var hint: Label
var choices: HBoxContainer
var quest: Label
var notice: Label

func _ready() -> void:
	layer = 15
	panel = PanelContainer.new()
	panel.position = Vector2(520, 190)
	panel.custom_minimum_size = Vector2(1080, 230)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)
	text = Label.new()
	text.custom_minimum_size = Vector2(1000, 96)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 28)
	column.add_child(text)
	hint = Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 20)
	hint.text = "E / RB 继续 · 长按加速文字"
	column.add_child(hint)
	choices = HBoxContainer.new()
	choices.add_theme_constant_override("separation", 24)
	column.add_child(choices)
	for caption: String in ["留下", "确认离开并放弃救助"]:
		var button: Button = Button.new()
		button.text = caption
		button.custom_minimum_size = Vector2(260, 52)
		button.add_theme_font_size_override("font_size", 22)
		choices.add_child(button)
	(choices.get_child(0) as Button).pressed.connect(func() -> void: departure_cancelled.emit())
	(choices.get_child(1) as Button).pressed.connect(func() -> void: departure_confirmed.emit())
	speaker = Label.new()
	speaker.position = Vector2(64, 912)
	speaker.add_theme_font_size_override("font_size", 30)
	add_child(speaker)
	quest = Label.new()
	quest.position = Vector2(64, 490)
	quest.add_theme_font_size_override("font_size", 23)
	add_child(quest)
	notice = Label.new()
	notice.position = Vector2(560, 540)
	notice.add_theme_font_size_override("font_size", 30)
	add_child(notice)
	dismiss()

func show_notice(message: String) -> void:
	notice.text = message
	notice.modulate.a = 1
	create_tween().tween_property(notice, "modulate:a", 0.0, 3.0)

func start(config: DialogueConfig, lines: PackedStringArray) -> void:
	_config = config
	_lines = lines
	line_index = 0
	active = true
	confirming = false
	choices.hide()
	hint.show()
	panel.show()
	speaker.text = config.speaker
	speaker.show()
	_show_line()

func _show_line() -> void:
	text.text = _lines[line_index]
	_count = 0
	text.visible_characters = 0
	_grace = 0.12

func _process(delta: float) -> void:
	if not active or confirming:
		return
	_grace = maxf(0, _grace - delta)
	_count += delta * _config.characters_per_second * (_config.hold_speed_multiplier if Input.is_action_pressed("interact") else 1.0)
	text.visible_characters = mini(text.get_total_character_count(), int(_count))
	if _grace == 0 and Input.is_action_just_pressed("interact"):
		advance()

func advance() -> void:
	if not active or confirming or get_tree().paused:
		return
	if text.visible_characters < text.get_total_character_count():
		_count = text.get_total_character_count()
		text.visible_characters = text.get_total_character_count()
	elif line_index + 1 < _lines.size():
		line_index += 1
		_show_line()
	else:
		finished.emit()

func show_departure() -> void:
	active = true
	confirming = true
	panel.show()
	speaker.text = "7"
	speaker.show()
	text.text = "这里还需要你，离开后无法弥补。\n返回荒地将永久失去这次救助机会。"
	text.visible_characters = -1
	hint.hide()
	choices.show()
	(choices.get_child(0) as Button).grab_focus()

func dismiss() -> void:
	active = false
	confirming = false
	panel.hide()
	speaker.hide()
