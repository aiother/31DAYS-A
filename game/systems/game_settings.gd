class_name SettingsService
extends Node
## Persisted preferences only. Gameplay clocks, input mappings and save slots
## never belong to this service. GameSettings is the project autoload.
signal changed(values: Dictionary)

const DEFAULTS: Dictionary = {"master_volume":100.0, "sfx_volume":100.0, "music_volume":100.0,
	"window_size":Vector2i(1280,720), "fullscreen":false, "max_fps":60}
const WINDOW_SIZES: Array[Vector2i] = [Vector2i(1280,720), Vector2i(1920,1080)]
const FRAME_LIMITS: Array[int] = [30,60,120,0]
const ACTION_NAMES: Dictionary = {"move_left":"向左移动", "move_right":"向右移动",
	"aim_up":"向上瞄准", "aim_down":"向下瞄准", "jump":"跳跃", "attack":"攻击",
	"dodge":"闪避", "recover":"恢复（长按）", "run":"跑步（按住）", "interact":"互动",
	"use_item":"使用药包", "pause":"暂停", "ui_accept":"菜单确认", "toggle_fullscreen":"全屏切换", "debug_reset":"调试重置"}
const PAD_NAMES: Dictionary = {JOY_BUTTON_A:"A", JOY_BUTTON_B:"B", JOY_BUTTON_X:"X", JOY_BUTTON_Y:"Y",
	JOY_BUTTON_LEFT_SHOULDER:"LB", JOY_BUTTON_RIGHT_SHOULDER:"RB", JOY_BUTTON_BACK:"Back", JOY_BUTTON_START:"Start",
	JOY_BUTTON_DPAD_LEFT:"十字键左", JOY_BUTTON_DPAD_RIGHT:"十字键右", JOY_BUTTON_DPAD_UP:"十字键上", JOY_BUTTON_DPAD_DOWN:"十字键下"}

var file_path: String = ""
var last_save_error: Error = OK
var _values: Dictionary = DEFAULTS.duplicate(true)
var _temporary_directory: String = ""

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The existing movement_lab F11 handler runs first; observe, do not toggle twice.
	process_priority = 1000
	file_path = _select_file()
	reload_settings()

func _select_file() -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--settings-file="):
			var explicit: String = argument.trim_prefix("--settings-file=")
			if not explicit.is_empty():
				return explicit
	# Custom SceneTree tests/acceptance scripts and the G2 headless main-scene
	# smoke run must never even read the player's real settings file.
	if get_tree().get_script() != null or (DisplayServer.get_name() == "headless" and OS.get_cmdline_args().has("--quit-after")):
		_temporary_directory = OS.get_cache_dir().path_join("31days_settings_%d_%d" % [OS.get_process_id(),Time.get_ticks_usec()])
		return _temporary_directory.path_join("settings.cfg")
	return "user://settings.cfg"

func get_values() -> Dictionary:
	return _values.duplicate(true)

func _number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value))

func _coerce(key: String, value: Variant) -> Variant:
	match key:
		"master_volume", "sfx_volume", "music_volume":
			if _number(value) and float(value) >= 0.0 and float(value) <= 100.0:
				return float(value)
		"fullscreen":
			if typeof(value) == TYPE_BOOL:
				return value
		"max_fps":
			if _number(value) and float(value) == floorf(float(value)) and int(value) in FRAME_LIMITS:
				return int(value)
		"window_size":
			if value is Vector2i and value in WINDOW_SIZES:
				return value
			if value is Array and value.size() == 2 and _number(value[0]) and _number(value[1]):
				for size: Vector2i in WINDOW_SIZES:
					if float(value[0]) == size.x and float(value[1]) == size.y:
						return size
	return null

func reload_settings() -> void:
	_values = DEFAULTS.duplicate(true)
	if FileAccess.file_exists(file_path):
		var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
		if file != null:
			var parser: JSON = JSON.new()
			var parse_error: Error = parser.parse(file.get_as_text())
			file.close()
			# JSON.parse reports an Error value without logging engine errors.
			# A damaged preferences file must not turn a normal startup into ERROR.
			if parse_error == OK and parser.data is Dictionary:
				var data: Dictionary = parser.data
				if data.get("version",0) == 1:
					for key: String in DEFAULTS:
						var value: Variant = _coerce(key,data.get(key))
						if value != null:
							_values[key] = value
	_apply()

func set_value(key: String, value: Variant) -> Error:
	if not DEFAULTS.has(key):
		return ERR_INVALID_PARAMETER
	var valid: Variant = _coerce(key,value)
	if valid == null:
		return ERR_INVALID_PARAMETER
	_values[key] = valid
	_apply()
	last_save_error = _save()
	changed.emit(get_values())
	return last_save_error

func restore_defaults() -> Error:
	_values = DEFAULTS.duplicate(true)
	_apply()
	last_save_error = _save()
	changed.emit(get_values())
	return last_save_error

func _apply() -> void:
	for entry: Array in [["Master","master_volume"],["效果音","sfx_volume"],["背景音","music_volume"]]:
		var index: int = AudioServer.get_bus_index(entry[0])
		if index >= 0:
			AudioServer.set_bus_volume_linear(index,float(_values[entry[1]]) / 100.0)
	Engine.max_fps = int(_values["max_fps"])
	# Render rate is a preference; physics_ticks_per_second is never assigned.
	var window: Window = get_tree().root
	window.mode = Window.MODE_FULLSCREEN if bool(_values["fullscreen"]) else Window.MODE_WINDOWED
	if not bool(_values["fullscreen"]):
		window.size = _values["window_size"]

func _save() -> Error:
	var directory: String = file_path.get_base_dir()
	var error: Error = DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		return error
	var file: FileAccess = FileAccess.open(file_path,FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var data: Dictionary = get_values()
	var size: Vector2i = data["window_size"]
	data["window_size"] = [size.x,size.y]
	data["version"] = 1
	file.store_string(JSON.stringify(data,"\t") + "\n")
	file.flush()
	error = file.get_error()
	file.close()
	return error

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_fullscreen"):
		var fullscreen: bool = DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN,DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
		if fullscreen != bool(_values["fullscreen"]):
			set_value("fullscreen",fullscreen)

func bindings() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for action: String in ACTION_NAMES:
		var keyboard: PackedStringArray = []
		var controller: PackedStringArray = []
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
				var label: String = {KEY_LEFT:"←",KEY_RIGHT:"→",KEY_UP:"↑",KEY_DOWN:"↓",KEY_ESCAPE:"Esc",KEY_KP_ENTER:"小键盘Enter"}.get(code,OS.get_keycode_string(code))
				if not keyboard.has(label): keyboard.append(label)
			elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				keyboard.append("鼠标左键")
			elif event is InputEventJoypadButton:
				controller.append(PAD_NAMES.get(event.button_index,event.as_text()))
			elif event is InputEventJoypadMotion:
				if event.axis == JOY_AXIS_LEFT_X: controller.append("左摇杆左" if event.axis_value < 0 else "左摇杆右")
				elif event.axis == JOY_AXIS_LEFT_Y: controller.append("左摇杆上" if event.axis_value < 0 else "左摇杆下")
		result.append({"action":action,"name":ACTION_NAMES[action],"keyboard":" / ".join(keyboard),"controller":" / ".join(controller) if not controller.is_empty() else "—"})
	return result

func _exit_tree() -> void:
	# Only the directory generated by this process is cleaned. Explicit paths,
	# and the normal user://settings.cfg, always remain intact.
	if not _temporary_directory.is_empty():
		if FileAccess.file_exists(file_path): DirAccess.remove_absolute(file_path)
		if DirAccess.dir_exists_absolute(_temporary_directory): DirAccess.remove_absolute(_temporary_directory)
