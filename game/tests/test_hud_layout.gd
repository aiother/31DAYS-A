# verify-suite: {"name": "formal HUD regions, control hint and save error prompt stay apart across viewports", "path": "res://tests/test_hud_layout.gd", "marker": "HUD_LAYOUT_TESTS checks=", "fixed_fps": null, "timeout": 60}
extends SceneTree
## UI-002: formal HUD regions, the kept control hint and save error feedback
## must never overlap on screen.
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String
var ui: CanvasLayer
var hud: Label
var formal: FormalHud
var error: Label
const SHORT_ERROR: String = "存档写入失败，请稍后重试"
const LONG_ERROR: String = "存档写入失败：无法写入检查点存档文件，可能是磁盘空间不足或存档目录不可写。当前进度仍保留在本次游戏中，请释放磁盘空间后在检查点重试，或打开暂停菜单返回存档槽选择其他存档位置继续游戏。"

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error(message)

func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func quiet() -> void:
	if session.room.has_node("Enemies"):
		for enemy: Node in session.room.get_node("Enemies").get_children():
			enemy.set_physics_process(false)
	if session.room.environment_hazard != null: session.room.environment_hazard.set_physics_process(false)
	session.player.set_physics_process(false)

# Actual on-screen rectangle: control size through canvas layer and root stretch transforms.
func screen_rect(control: Control) -> Rect2:
	return control.get_viewport().get_final_transform() * control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, control.size)

# Rendered text block: laid-out lines from the top of the Label, also through the screen transform.
func text_rect(label: Label) -> Rect2:
	var lines: int = label.get_visible_line_count()
	var spacing: float = label.get_theme_constant("line_spacing")
	var height: float = lines * label.get_line_height() + maxf(0, lines - 1) * spacing
	return label.get_viewport().get_final_transform() * label.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, Vector2(label.size.x, height))

# Drawn HUD region (FormalHud canvas units) through the same screen transform.
func drawn_rect(local: Rect2) -> Rect2:
	return formal.get_viewport().get_final_transform() * formal.get_global_transform_with_canvas() * local

## Every region the formal HUD drew this frame, as screen rectangles.
func regions() -> Dictionary:
	var result: Dictionary = {}
	for key: String in ["emblem", "hint", "horizon", "warning", "banner", "final"]:
		if formal.drawn.has(key):
			result[key] = drawn_rect(formal.drawn[key]["rect"])
	return result

func set_state(case: String) -> void:
	var actions: PlayerPossibility = session.player.possibility
	actions.cancel()
	session.data["day_remaining"] = 1500.0
	formal.banner_left = 0.0
	if case == "healing":
		actions.state = PlayerPossibility.State.HEALING
		actions.remaining = actions.config.heal_duration * 0.5
	elif case == "warning":
		session.data["day_remaining"] = 170.0
	elif case == "banner":
		formal.banner_day = 2
		formal.banner_left = 2.0

func layout(case: String) -> bool:
	await ticks(3)
	var window: Vector2 = Vector2(root.size)
	var hud_box: Rect2 = text_rect(hud)
	var error_box: Rect2 = text_rect(error)
	var shown: bool = error.is_visible_in_tree() and not error.text.is_empty()
	var boxes: Dictionary = regions()
	var overlap: bool = shown and hud_box.intersects(error_box)
	for key: String in boxes:
		if shown and (boxes[key] as Rect2).intersects(error_box):
			overlap = true
			print("OVERLAP %s error %s" % [key, case])
	var keys: Array = boxes.keys()
	for i: int in range(keys.size()):
		for j: int in range(i + 1, keys.size()):
			if (boxes[keys[i]] as Rect2).intersects(boxes[keys[j]]):
				overlap = true
				print("OVERLAP %s %s %s" % [keys[i], keys[j], case])
	print("MEASURE %s window=%dx%d scale=%.4f hint_text=%s regions=%s error_visible=%s error_lines=%d error_text=%s overlap=%s" % [case, window.x, window.y, root.get_final_transform().get_scale().x, hud_box, boxes, error.is_visible_in_tree(), error.get_visible_line_count(), error_box, overlap])
	var screen: Rect2 = Rect2(Vector2.ZERO, window)
	check(screen.encloses(hud_box), case + " hint text stays inside window")
	check(screen_rect(hud).encloses(hud_box), case + " hint control is not clipping its rendered lines")
	for key: String in boxes:
		check(screen.grow(1.0).encloses(boxes[key]), case + " " + key + " region stays inside window")
	check(boxes.has("hint") and (boxes["hint"] as Rect2).encloses(hud_box), case + " hint paper tag covers the hint text")
	if shown:
		check(screen.encloses(error_box), case + " error text stays inside window")
		check(screen_rect(error).encloses(error_box), case + " error control is not clipping its rendered lines")
	check(not overlap, case + " HUD regions and error text do not overlap")
	return not overlap

func viewport(size: Vector2i) -> void:
	root.size = size
	await ticks(3)
	check(root.size == size and is_equal_approx(root.get_final_transform().get_scale().x, size.x / 1920.0), "root stretch transform follows %dx%d window" % [size.x, size.y])

func start_final() -> void:
	session.set_physics_process(false)
	session.data["day"] = 3
	session.data["day3_remaining"] = 1500.0
	for flag: String in [RescueBattlefieldSession.RESCUE_DONE_EVENT, TrenchPassageRoom.CLEARED, TrenchPassageRoom.CHALLENGE, TrenchPassageRoom.FORWARD]:
		session.data["events"][flag] = true
	session._change_room(FinalBattleSession.BATTLEFIELD_ID)
	session.player.position = Vector2(450, 896)
	session.player.reset_kinematics()
	session.player.set_physics_process(true)
	await ticks(2)
	quiet()

func run() -> void:
	directory = "user://tests/hud_layout_%d" % Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	check(session.start_slot(1, true), "isolated test slot starts")
	await ticks(3)
	session = current_scene as FinalBattleSession
	session.data["events"][StartRoomSession.BIRTH] = true
	session.intro_active = false
	session.player.life.scripted_control_locked = false
	paused = false
	quiet()
	ui = session.ui
	hud = ui.get("_health") as Label
	formal = ui.get("_hud") as FormalHud
	error = ui.get("_error_label") as Label
	session.data["medkits"] = 2
	session.player.combat.pearl_count = 2
	# Real update flow: FormalHud._draw records every region it put on screen.
	set_state("healing")
	ui.call("save_failed", SHORT_ERROR)
	await viewport(Vector2i(1920, 1080))
	await ticks(2)
	check(hud.is_visible_in_tree() and hud.get_line_count() == 1 and hud.text.contains("K / B 滑步") and hud.text.contains("Q / Back 药包"), "kept control hint is one small line")
	check(formal.drawn["emblem"]["healing"] > 0.0 and formal.drawn["emblem"]["pearls"] == 2 and formal.drawn["emblem"]["medkits"] == "× 2", "healing progress, pearls and medkits are drawn by the emblem")
	check(error.is_visible_in_tree() and error.text == SHORT_ERROR, "existing save_failed shows the error prompt")
	check(hud.get_global_transform_with_canvas().origin == Vector2(40, 322), "hint keeps its top-left origin under the emblem")
	check(hud.get_theme_font_size("font_size") == UiTheme.SIZE_SMALL and error.get_theme_font_size("font_size") == 22, "hint and error keep their font sizes")
	check(error.modulate == Color(1, 0.5, 0.35), "error keeps its color")
	await layout("healing 1920x1080")
	set_state("idle")
	await layout("idle 1920x1080")
	set_state("warning")
	await layout("next-day warning 1920x1080")
	check(formal.drawn.has("warning"), "warning region is measured")
	set_state("banner")
	await layout("day banner 1920x1080")
	check(formal.drawn.has("banner"), "banner region is measured")
	ui.call("save_failed", "")
	await ticks(2)
	check(error.text.is_empty() and not error.is_visible_in_tree() and hud.get_global_transform_with_canvas().origin == Vector2(40, 322), "clearing the error hides it and keeps the hint in place")
	await layout("cleared error 1920x1080")
	ui.call("save_failed", SHORT_ERROR)
	await ticks(2)
	check(error.is_visible_in_tree() and error.text == SHORT_ERROR, "error prompt reappears after clearing")
	await layout("reappeared error 1920x1080")
	ui.call("save_failed", LONG_ERROR)
	await layout("long Chinese error 1920x1080")
	check(error.get_line_count() >= 2 and screen_rect(error).end.x <= 1920 * 0.75, "long Chinese error wraps into a readable column")
	await viewport(Vector2i(1280, 720))
	await layout("long Chinese error 1280x720")
	ui.call("save_failed", SHORT_ERROR)
	set_state("idle")
	await layout("idle 1280x720")
	set_state("healing")
	await layout("healing 1280x720")
	set_state("warning")
	await layout("next-day warning 1280x720")
	await start_final()
	ui.call("save_failed", LONG_ERROR)
	await layout("final countdown long error 1280x720")
	check(formal.drawn.has("final"), "final countdown region is measured")
	await viewport(Vector2i(1920, 1080))
	await layout("final countdown long error 1920x1080")
	var node: Node = hud
	var passive: bool = formal.mouse_filter == Control.MOUSE_FILTER_IGNORE and formal.filter_rect.mouse_filter == Control.MOUSE_FILTER_IGNORE
	while node != ui:
		if node is Control and (node as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE: passive = false
		node = node.get_parent()
	node = error
	while node != ui:
		if node is Control and (node as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE: passive = false
		node = node.get_parent()
	check(passive, "HUD, filter and error never intercept mouse input")
	session.queue_free()
	await ticks(2)
	current_scene = null
	for selected: int in range(1, SlotStore.SLOT_COUNT + 1):
		for suffix: String in ["", ".tmp", ".bak"]:
			var path: String = directory.path_join("slot_%d.json" % selected) + suffix
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("HUD_LAYOUT_TESTS checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
