class_name SettingsPage
extends Control
## UI-006 formal settings page (BL-047, A-017): three volumes, window size,
## fullscreen, frame cap, the read-only key list and restore defaults (with
## confirmation). Every change goes through the GameSettings service (SYS-007),
## which applies and saves it; the page never touches files or buses. The pause
## menu hosts the same page whether it was opened in play or from the title.
signal back_requested
const ROW_SIZE: Vector2 = Vector2(440, 56)
const LEFT_X: float = 40.0
const FIRST_ROW_Y: float = 120.0
const ROW_GAP: float = 64.0
const KEYS_RECT: Rect2 = Rect2(520, 150, 440, 520)
const KEY_ROW: float = 58.0
const KEYS_NOTE: String = "自定义按键将在后续版本提供"

var settings: Node
var font: Font
## key -> SettingRow for the six preferences.
var rows: Dictionary = {}
var restore: SettingRow
var keys: KeyList
var back_button: InkButton
var confirm: Control
## What the last frame put on screen; read by tests.
var drawn: Dictionary = {}

## Read-only key list from SettingsService.bindings(); scrolls when focused
## (up / down, wheel) and only draws rows that fit inside its rect.
class KeyList extends Control:
	const ROW: float = 58.0
	var bindings: Array[Dictionary] = []
	var offset: int = 0
	var font: Font
	var drawn: Dictionary = {}

	func _init() -> void:
		focus_mode = Control.FOCUS_ALL
		mouse_filter = Control.MOUSE_FILTER_STOP
		clip_contents = true
		font = UiTheme.font()
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)

	func visible_rows() -> int:
		return int(size.y / ROW)

	func max_offset() -> int:
		return maxi(0, bindings.size() - visible_rows())

	func scroll(direction: int) -> bool:
		var next: int = clampi(offset + direction, 0, max_offset())
		if next == offset:
			return false
		offset = next
		queue_redraw()
		return true

	func _gui_input(event: InputEvent) -> void:
		var handled: bool = false
		if event.is_action_pressed("ui_up", true):
			handled = scroll(-1)
		elif event.is_action_pressed("ui_down", true):
			handled = scroll(1)
		elif event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				handled = scroll(-1) or true
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				handled = scroll(1) or true
			elif event.button_index == MOUSE_BUTTON_LEFT:
				grab_focus()
				handled = true
		# At either end up / down fall through and move the focus on.
		if handled:
			accept_event()

	func _draw() -> void:
		var shown: Array[Dictionary] = []
		for i: int in range(offset, mini(bindings.size(), offset + visible_rows())):
			var row: Dictionary = bindings[i]
			var top: float = (i - offset) * ROW
			if (i - offset) % 2 == 0:
				draw_rect(Rect2(0, top, size.x - 14, ROW), Color(DuskStyle.INK, 0.05))
			draw_string(font, Vector2(10, top + 25), str(row["name"]), HORIZONTAL_ALIGNMENT_LEFT, 130, UiTheme.SIZE_SMALL, DuskStyle.INK)
			draw_string(font, Vector2(150, top + 24), "键盘  " + str(row["keyboard"]), HORIZONTAL_ALIGNMENT_LEFT, size.x - 170, 16, DuskStyle.INK)
			draw_string(font, Vector2(150, top + 48), "手柄  " + str(row["controller"]), HORIZONTAL_ALIGNMENT_LEFT, size.x - 170, 16, Color(DuskStyle.INK, 0.7))
			shown.append({"action": row["action"], "name": row["name"], "keyboard": row["keyboard"], "controller": row["controller"], "rect": Rect2(0, top, size.x, ROW)})
		# Scroll bar: where the visible rows sit in the whole list.
		var track: Rect2 = Rect2(size.x - 6, 0, 4, size.y)
		draw_rect(track, Color(DuskStyle.INK, 0.12))
		if bindings.size() > 0:
			var span: float = float(visible_rows()) / bindings.size()
			draw_rect(Rect2(track.position.x, size.y * offset / bindings.size(), 4, size.y * minf(1.0, span)), Color(DuskStyle.INK, 0.7 if has_focus() else 0.4))
		if has_focus():
			InkDraw.rough_rect(self, Rect2(Vector2.ONE, size - Vector2(2, 2)), Color(DuskStyle.LIFE, 0.8), 1.6, 640, 0.5)
		drawn = {"rows": shown, "offset": offset, "focused": has_focus()}

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = UiTheme.font()
	theme = UiTheme.get_theme()

func setup(service: Node) -> void:
	settings = service
	var values: Dictionary = settings.call("get_values")
	var specs: Array = [
		["master_volume", "slider", "总音量", []],
		["sfx_volume", "slider", "效果音", []],
		["music_volume", "slider", "背景音", []],
		["window_size", "choice", "窗口尺寸", [[Vector2i(1280, 720), "1280 × 720"], [Vector2i(1920, 1080), "1920 × 1080"]]],
		["fullscreen", "toggle", "全屏", []],
		["max_fps", "choice", "帧率上限", [[30, "30"], [60, "60"], [120, "120"], [0, "不限制"]]],
	]
	var order: Array[Control] = []
	for i: int in range(specs.size()):
		var spec: Array = specs[i]
		var row: SettingRow = SettingRow.new().setup(spec[1], spec[2], values[spec[0]], 620 + i, spec[3])
		row.position = Vector2(LEFT_X, FIRST_ROW_Y + i * ROW_GAP)
		row.size = ROW_SIZE
		row.changed.connect(_on_changed.bind(spec[0]))
		add_child(row)
		rows[spec[0]] = row
		order.append(row)
	keys = KeyList.new()
	keys.position = KEYS_RECT.position
	keys.size = KEYS_RECT.size
	keys.bindings = settings.call("bindings")
	add_child(keys)
	order.append(keys)
	restore = SettingRow.new().setup("action", "恢复默认", null, 630)
	restore.position = Vector2(LEFT_X, FIRST_ROW_Y + specs.size() * ROW_GAP + 30)
	restore.size = ROW_SIZE
	restore.activated.connect(ask_restore)
	add_child(restore)
	order.append(restore)
	back_button = InkButton.new().setup("返回", 26, 631)
	back_button.position = Vector2(60, 690)
	back_button.size = Vector2(360, 56)
	back_button.pressed.connect(func() -> void: back_requested.emit())
	add_child(back_button)
	order.append(back_button)
	# Up / down walk the column; the key list joins the walk between the frame
	# cap and restore defaults, and scrolls before it lets the focus go.
	for i: int in range(order.size()):
		var item: Control = order[i]
		item.focus_neighbor_top = item.get_path_to(order[maxi(0, i - 1)])
		item.focus_neighbor_bottom = item.get_path_to(order[mini(order.size() - 1, i + 1)])
		item.focus_neighbor_left = item.get_path()
		item.focus_neighbor_right = item.get_path()
		item.focus_previous = item.focus_neighbor_top
		item.focus_next = item.focus_neighbor_bottom
	settings.connect("changed", func(_values: Dictionary) -> void: refresh())
	visible = false

## Shows the service's current values (F11, restore defaults, reopening).
func refresh() -> void:
	var values: Dictionary = settings.call("get_values")
	for key: String in rows:
		(rows[key] as SettingRow).show_value(values[key])

func open() -> void:
	close_confirm(false)
	refresh()
	keys.offset = 0
	visible = true
	back_button.grab_focus()

func close() -> void:
	close_confirm(false)
	visible = false

func _on_changed(value: Variant, key: String) -> void:
	settings.call("set_value", key, value)

func focusables() -> Array[Control]:
	var result: Array[Control] = []
	for key: String in rows:
		result.append(rows[key])
	result.append_array([keys, restore, back_button])
	return result

## Restore defaults asks first; focus starts on 返回.
func ask_restore() -> void:
	close_confirm(false)
	for item: Control in focusables():
		item.focus_mode = Control.FOCUS_NONE
	confirm = Control.new()
	confirm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirm.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm.draw.connect(_draw_confirm.bind(confirm))
	add_child(confirm)
	var sheet: Rect2 = confirm_rect()
	var accept: InkButton = InkButton.new().setup("恢复默认", 26, 650)
	var cancel: InkButton = InkButton.new().setup("返回", 26, 651)
	for item: InkButton in [accept, cancel]:
		item.custom_minimum_size = Vector2(240, 56)
		item.size = item.custom_minimum_size
		confirm.add_child(item)
	accept.position = sheet.position + Vector2(50, sheet.size.y - 90)
	cancel.position = sheet.position + Vector2(sheet.size.x - 290, sheet.size.y - 90)
	accept.focus_neighbor_right = accept.get_path_to(cancel)
	cancel.focus_neighbor_left = cancel.get_path_to(accept)
	accept.pressed.connect(func() -> void:
		close_confirm()
		settings.call("restore_defaults")
		refresh())
	cancel.pressed.connect(func() -> void: close_confirm())
	confirm.set_meta("accept", accept)
	confirm.set_meta("cancel", cancel)
	cancel.grab_focus()

func close_confirm(restore_focus: bool = true) -> void:
	if confirm == null:
		return
	confirm.queue_free()
	confirm = null
	drawn.erase("confirm")
	for item: Control in focusables():
		item.focus_mode = Control.FOCUS_ALL
	if restore_focus:
		restore.grab_focus()

func confirm_button(which: String) -> Button:
	return confirm.get_meta(which) as Button if confirm != null else null

func confirm_rect() -> Rect2:
	return Rect2((size - Vector2(620, 240)) * 0.5, Vector2(620, 240))

func _draw_confirm(sheet_node: Control) -> void:
	if sheet_node != confirm:
		return
	var sheet: Rect2 = confirm_rect()
	confirm.draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.03, 0.04, 0.35))
	InkDraw.paper(confirm, sheet, Color(DuskStyle.PAPER_DAY, 0.97), 655, DuskStyle.WOBBLE, 4)
	InkDraw.rough_rect(confirm, sheet, Color(DuskStyle.INK, 0.85), DuskStyle.INK_WIDTH, 656, DuskStyle.WOBBLE)
	var text: String = "恢复全部默认设置？"
	confirm.draw_string(font, sheet.position + Vector2(0, 80), text, HORIZONTAL_ALIGNMENT_CENTER, sheet.size.x, UiTheme.SIZE_HEADING, DuskStyle.INK)
	drawn["confirm"] = {"text": text, "rect": sheet}

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()
		for item: Control in focusables():
			item.queue_redraw()
		if confirm != null:
			confirm.queue_redraw()

func _draw() -> void:
	draw_string(font, Vector2(KEYS_RECT.position.x + 10, KEYS_RECT.position.y - 22), "按键列表", HORIZONTAL_ALIGNMENT_LEFT, -1, UiTheme.SIZE_BODY, DuskStyle.INK)
	draw_string(font, Vector2(KEYS_RECT.position.x + 10, KEYS_RECT.end.y + 34), KEYS_NOTE, HORIZONTAL_ALIGNMENT_LEFT, KEYS_RECT.size.x, UiTheme.SIZE_SMALL, Color(DuskStyle.INK, 0.6))
	var record: Dictionary = {"rows": {}, "keys_rect": Rect2(keys.position, keys.size), "note": KEYS_NOTE}
	for key: String in rows:
		record["rows"][key] = (rows[key] as SettingRow).drawn
	record["restore"] = restore.drawn
	record["back_rect"] = back_button.get_rect()
	record["keys"] = keys.drawn
	var kept: Variant = drawn.get("confirm")
	drawn = record
	if kept != null and confirm != null:
		drawn["confirm"] = kept

func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause") or event.is_action_pressed("use_item"):
		if confirm != null:
			close_confirm()
		else:
			back_requested.emit()
		get_viewport().set_input_as_handled()
