# verify-suite: {"name":"settings buses persistence isolated startup and frozen binding query","path":"res://tests/test_settings.gd","marker":"SETTINGS_TESTS checks=","fixed_fps":null,"timeout":120}
extends SceneTree
# Regression: compile the real UI dependency graph before autoload startup.
# A compile-time GameSettings reference here used to break acceptance suites.
const GRAY_SCENE: PackedScene = preload("res://debug/enemy_lab.tscn")
const FINAL_SCENE: PackedScene = preload("res://world/final_battle_session.tscn")
var checks: int = 0
var failures: int = 0
var settings: Node
var directory: String = ""
const DEFAULTS: Dictionary = {"master_volume":100.0,"sfx_volume":100.0,"music_volume":100.0,
	"window_size":Vector2i(1280,720),"fullscreen":false,"max_fps":60}

func _initialize() -> void:
	if OS.get_cmdline_user_args().has("--settings-probe"):
		# This is the first process-frame signal, before scene _process callbacks.
		process_frame.connect(startup_probe,CONNECT_ONE_SHOT)
	else:
		run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error(message)

func frames(count: int = 2) -> void:
	for i: int in range(count): await process_frame

func values() -> Dictionary:
	return settings.call("get_values")

func serialized(value: Dictionary) -> Dictionary:
	var result: Dictionary = value.duplicate(true)
	var size: Vector2i = result["window_size"]
	result["window_size"] = [size.x,size.y]
	return result

# JSON numbers are floats on read; normalize both sides before comparing
# dictionaries/arrays, whose equality also considers nested numeric types.
func json_value(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))

func startup_probe() -> void:
	var service: Node = root.get_node_or_null("GameSettings")
	if service == null:
		print("SETTINGS_CHILD missing autoload")
		quit(1)
		return
	var snapshot: Dictionary = service.call("get_values")
	var report: Dictionary = {"values":serialized(snapshot), "file":service.get("file_path"),
		"max_fps":Engine.max_fps,"physics":Engine.physics_ticks_per_second,
		"window":[root.size.x,root.size.y],"mode":root.mode,"volumes":[]}
	for bus: String in ["Master","效果音","背景音"]:
		(report["volumes"] as Array).append(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(bus)))
	print("SETTINGS_CHILD " + JSON.stringify(report))
	quit()

func saved() -> Dictionary:
	var path: String = str(settings.get("file_path"))
	if not FileAccess.file_exists(path): return {}
	var result: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return result if result is Dictionary else {}

func write_fixture(text: String) -> void:
	DirAccess.make_dir_recursive_absolute(directory)
	var file: FileAccess = FileAccess.open(str(settings.get("file_path")),FileAccess.WRITE)
	file.store_string(text)
	file.close()

func child(expected: Dictionary, description: String) -> void:
	var output: Array = []
	var code: int = OS.execute(OS.get_executable_path(),PackedStringArray(["--headless","--path",ProjectSettings.globalize_path("res://"),
		"--script","res://tests/test_settings.gd","--","--settings-probe","--settings-file="+str(settings.get("file_path"))]),output,true)
	var text: String = "\n".join(output)
	var report: Dictionary = {}
	for line: String in text.split("\n"):
		if line.begins_with("SETTINGS_CHILD "):
			var parsed: Variant = JSON.parse_string(line.trim_prefix("SETTINGS_CHILD "))
			if parsed is Dictionary: report = parsed
	check(code == 0 and not text.contains("ERROR:") and not text.contains("WARNING:"), description + " starts without errors in a new engine process")
	check(report.get("file") == settings.get("file_path") and report.get("values") == json_value(serialized(expected)), description + " is loaded before the first process frame")
	check(report.get("max_fps") == expected["max_fps"] and report.get("physics") == 60, description + " applies render cap without changing physics")
	var expected_volumes: Array = [float(expected["master_volume"])/100.0,float(expected["sfx_volume"])/100.0,float(expected["music_volume"])/100.0]
	var actual_volumes: Array = report.get("volumes",[])
	var volume_ok: bool = actual_volumes.size() == 3
	for i: int in range(actual_volumes.size()):
		volume_ok = volume_ok and i < 3 and is_equal_approx(float(actual_volumes[i]),float(expected_volumes[i]))
	check(volume_ok, description + " applies all bus volumes at startup")
	# Child probes are headless: preferences load normally, but the dummy
	# display server does not implement native fullscreen/window modes.
	if not bool(expected["fullscreen"]):
		var size: Vector2i = expected["window_size"]
		check(report.get("window") == json_value([size.x,size.y]), description + " applies the window size at startup")

func change(key: String, value: Variant) -> void:
	check(settings.call("set_value",key,value) == OK and values()[key] == value, "%s changes immediately to %s" % [key,value])
	var disk: Dictionary = saved()
	check(disk.get(key) == json_value(serialized(values())[key]), "%s is immediately written to the settings file" % key)
	match key:
		"master_volume", "sfx_volume", "music_volume":
			var bus: String = {"master_volume":"Master","sfx_volume":"效果音","music_volume":"背景音"}[key]
			check(is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(bus)),float(value)/100.0), bus + " applies its actual volume")
		"max_fps":
			check(Engine.max_fps == value and Engine.physics_ticks_per_second == 60, "render cap %d leaves physical rate at 60" % int(value))
		"window_size":
			check(root.size == value, "actual window size follows the selected preset")
		"fullscreen":
			if DisplayServer.get_name() != "headless":
				check(root.mode == (Window.MODE_FULLSCREEN if bool(value) else Window.MODE_WINDOWED), "actual native window mode follows fullscreen preference")

func run() -> void:
	check(FINAL_SCENE.can_instantiate(),"real final-session dependency graph compiles before autoload startup")
	settings = root.get_node_or_null("GameSettings")
	check(settings != null,"settings autoload exists before the test's first frame")
	if settings == null:
		finish()
		return
	directory = str(settings.get("file_path")).get_base_dir()
	check(directory.begins_with(OS.get_cache_dir().path_join("31days_settings_")) and str(settings.get("file_path")) != ProjectSettings.globalize_path("user://settings.cfg"), "custom test startup is isolated from player settings")
	check(values() == DEFAULTS and not FileAccess.file_exists(str(settings.get("file_path"))), "missing settings use defaults without creating a real-user file")
	for bus: String in ["Master","效果音","背景音"]:
		var index: int = AudioServer.get_bus_index(bus)
		check(index >= 0 and is_equal_approx(AudioServer.get_bus_volume_linear(index),1.0), bus + " exists at its default volume")
		if bus != "Master": check(AudioServer.get_bus_send(index) == &"Master", bus + " is routed through Master")
	await routing()
	var detached: Dictionary = values()
	detached["master_volume"] = 1.0
	check(values() == DEFAULTS,"settings query returns detached data")
	child(DEFAULTS,"missing settings")
	DirAccess.make_dir_recursive_absolute(directory)
	var sentinel: String = directory.path_join("slot_1.json")
	var marker: PackedByteArray = "player slot sentinel\n".to_utf8_buffer()
	var slot: FileAccess = FileAccess.open(sentinel,FileAccess.WRITE)
	slot.store_buffer(marker)
	slot.close()
	for entry: Array in [["master_volume",37.0],["sfx_volume",0.0],["music_volume",65.0],["window_size",Vector2i(1920,1080)],["fullscreen",true],["max_fps",120]]:
		change(entry[0],entry[1])
	child(values(),"saved custom settings")
	for rate: int in [30,60,120,0]: change("max_fps",rate)
	change("fullscreen",false)
	change("window_size",Vector2i(1280,720))
	child(values(),"unlimited windowed settings")
	check(FileAccess.get_file_as_bytes(sentinel) == marker,"settings updates leave slot bytes untouched")
	check(settings.call("set_value","max_fps",59) == ERR_INVALID_PARAMETER and settings.call("set_value","master_volume",NAN) == ERR_INVALID_PARAMETER and settings.call("set_value","unknown",0) == ERR_INVALID_PARAMETER,"invalid API values are rejected without changing valid preferences")
	check(settings.call("restore_defaults") == OK and values() == DEFAULTS and saved().get("max_fps") == 60,"restore defaults applies and persists every default")
	child(DEFAULTS,"restored defaults")
	write_fixture("this is not a settings JSON file")
	child(DEFAULTS,"damaged settings")
	write_fixture('{"version":1,"master_volume":-1,"sfx_volume":101,"music_volume":"bad","window_size":[800,600],"fullscreen":1,"max_fps":59}')
	child(DEFAULTS,"out-of-range settings")
	write_fixture('{"version":2,"master_volume":25}')
	child(DEFAULTS,"unsupported settings version")
	settings.call("reload_settings")
	check(values() == DEFAULTS,"reload also falls back safely to defaults")
	await bindings_cases()
	await gray_settings()
	settings.call("restore_defaults")
	check(FileAccess.get_file_as_bytes(sentinel) == marker,"loading bad settings and restoring defaults never edits slots")
	finish()

func routing() -> void:
	for entry: Array in [["res://player/player.tscn","_hit_sound"],["res://enemies/colorless_entity.tscn","_warning"],["res://enemies/monochrome_entity.tscn","_warning"],["res://enemies/tian_warrior.tscn","warning"]]:
		var actor: Node = (load(entry[0]) as PackedScene).instantiate()
		root.add_child(actor)
		actor.set_physics_process(false)
		var sound: AudioStreamPlayer = actor.get_node("VisualRoot").get(entry[1]) as AudioStreamPlayer
		check(sound != null and sound.bus == &"效果音", str(entry[0]) + " routes the real placeholder player through effects")
		actor.queue_free()
	await frames()

func bindings_cases() -> void:
	var expected: Array = [
		["move_left","向左移动","A / ←","左摇杆左 / 十字键左"],["move_right","向右移动","D / →","左摇杆右 / 十字键右"],
		["aim_up","向上瞄准","W / ↑","左摇杆上 / 十字键上"],["aim_down","向下瞄准","S / ↓","左摇杆下 / 十字键下"],
		["jump","跳跃","Space","A"],["attack","攻击","J / 鼠标左键","X"],["dodge","闪避","K","B"],
		["recover","恢复（长按）","L","Y"],["run","跑步（按住）","Shift","LB"],["interact","互动","E","RB"],
		["use_item","使用药包","Q","Back"],["pause","暂停","Esc","Start"],
		["ui_accept","菜单确认","Enter / 小键盘Enter / Space","A"],["toggle_fullscreen","全屏切换","F11","—"],["debug_reset","调试重置","R","—"]]
	var before: String = mapping_signature()
	var rows: Array = settings.call("bindings")
	check(rows.size() == expected.size(),"binding list contains all frozen actions and no extras")
	for i: int in range(mini(rows.size(),expected.size())):
		check(rows[i] == {"action":expected[i][0],"name":expected[i][1],"keyboard":expected[i][2],"controller":expected[i][3]},"binding row %d matches T1 name order and keyboard/controller text" % i)
	rows[0]["keyboard"] = "changed by caller"
	check((settings.call("bindings") as Array)[0]["keyboard"] == "A / ←" and mapping_signature() == before,"binding query is detached and never modifies InputMap")
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = KEY_Z
	InputMap.action_add_event("attack",event)
	check((settings.call("bindings") as Array)[5]["keyboard"] == "J / 鼠标左键 / Z","binding text is actually read from InputMap")
	InputMap.action_erase_event("attack",event)
	check(mapping_signature() == before,"temporary test input-map change is restored")

func mapping_signature() -> String:
	var result: Array = []
	for action: StringName in InputMap.get_actions():
		var entries: Array[String] = []
		for event: InputEvent in InputMap.action_get_events(action): entries.append(var_to_str(event))
		result.append([action,entries])
	return var_to_str(result)

func gray_settings() -> void:
	var world: Node = GRAY_SCENE.instantiate()
	root.add_child(world)
	var ui: Node = world.get_node("LifeUI")
	ui.call("show_settings")
	var menu: Control = ui.get("_pause") as Control
	# UI-006: the formal settings page rows replaced the graybox controls.
	var page: SettingsPage = menu.get("settings_page") as SettingsPage
	var volume: SettingRow = page.rows.get("master_volume") if page != null else null
	var resolution: SettingRow = page.rows.get("window_size") if page != null else null
	var fullscreen: SettingRow = page.rows.get("fullscreen") if page != null else null
	check(paused and menu.visible and volume != null and resolution != null and fullscreen != null,"current pause settings keep their three controls and pause behavior")
	volume.commit(23.0)
	check(values()["master_volume"] == 23 and saved().get("master_volume") == 23,"gray volume control uses the persisted interface")
	resolution.commit(Vector2i(1920,1080))
	check(values()["window_size"] == Vector2i(1920,1080) and root.size == Vector2i(1920,1080),"gray resolution control applies and stores the large preset")
	fullscreen.commit(true)
	check(values()["fullscreen"] and saved().get("fullscreen") == true,"gray fullscreen control applies and stores its preference")
	ui.call("show_settings")
	check(paused,"reopening gray settings remains paused")
	ui.call("resume_game")
	check(not paused,"gray settings can still return to gameplay")
	if DisplayServer.get_name() != "headless":
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = KEY_F11
		event.pressed = true
		Input.parse_input_event(event)
		await frames(2)
		event.pressed = false
		Input.parse_input_event(event)
		await frames(2)
		check(not values()["fullscreen"] and saved().get("fullscreen") == false and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED,"existing real F11 handler changes native mode once and persists it")
	world.queue_free()
	await frames()

func finish() -> void:
	paused = false
	if not directory.is_empty():
		for file: String in DirAccess.get_files_at(directory): DirAccess.remove_absolute(directory.path_join(file))
		DirAccess.remove_absolute(directory)
	OS.delay_msec(500)
	print("SETTINGS_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
