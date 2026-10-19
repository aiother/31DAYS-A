extends SceneTree
## Graybox HUD rows and save error feedback must never overlap on screen.
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String
var ui: CanvasLayer
var hud: Label
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

func set_rows(five: String) -> void:
	var actions: PlayerPossibility = session.player.possibility
	actions.cancel()
	if five == "healing":
		actions.state = PlayerPossibility.State.HEALING
		actions.remaining = actions.config.heal_duration * 0.5
	elif five == "dodge":
		actions.state = PlayerPossibility.State.DODGE_ACTIVE
		actions.chain = 2

func layout(case: String) -> bool:
	await ticks(3)
	var window: Vector2 = Vector2(root.size)
	var hud_box: Rect2 = text_rect(hud)
	var error_box: Rect2 = text_rect(error)
	var overlap: bool = error.is_visible_in_tree() and not error.text.is_empty() and hud_box.intersects(error_box)
	print("MEASURE %s window=%dx%d scale=%.4f hud_lines=%d hud_text=%s hud_control=%s error_visible=%s error_lines=%d error_text=%s error_control=%s overlap=%s" % [case, window.x, window.y, root.get_final_transform().get_scale().x, hud.get_visible_line_count(), hud_box, screen_rect(hud), error.is_visible_in_tree(), error.get_visible_line_count(), error_box, screen_rect(error), overlap])
	var screen: Rect2 = Rect2(Vector2.ZERO, window)
	check(screen.encloses(hud_box), case + " HUD text stays inside window")
	check(screen_rect(hud).encloses(hud_box), case + " HUD control is not clipping its rendered lines")
	if error.is_visible_in_tree() and not error.text.is_empty():
		check(screen.encloses(error_box), case + " error text stays inside window")
		check(screen_rect(error).encloses(error_box), case + " error control is not clipping its rendered lines")
	check(not overlap, case + " HUD and error text do not overlap")
	return not overlap

func viewport(size: Vector2i) -> void:
	root.size = size
	await ticks(3)
	check(root.size == size and is_equal_approx(root.get_final_transform().get_scale().x, size.x / 1920.0), "root stretch transform follows %dx%d window" % [size.x, size.y])

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
	error = ui.get("_error_label") as Label
	session.data["medkits"] = 2
	session.player.combat.pearl_count = 2
	# Real update flow: LifeUI._process composes the rows each frame from player state.
	set_rows("healing")
	ui.call("save_failed", SHORT_ERROR)
	await viewport(Vector2i(1920, 1080))
	await ticks(2)
	check(hud.is_visible_in_tree() and hud.get_line_count() == 5 and hud.text.contains("恢复中") and hud.text.contains("珍珠 2 / 4") and hud.text.contains("药包 2 / 3"), "healing state shows five HUD rows with pearl and medkit")
	check(error.is_visible_in_tree() and error.text == SHORT_ERROR, "existing save_failed shows the error prompt")
	check(hud.get_global_transform_with_canvas().origin == Vector2(64, 258), "HUD keeps its top-left origin")
	check(hud.get_theme_font_size("font_size") == 24 and error.get_theme_font_size("font_size") == 22, "HUD and error keep their font sizes")
	check(error.modulate == Color(1, 0.5, 0.35) and hud.modulate == Color.WHITE, "HUD and error keep their colors")
	await layout("healing five rows 1920x1080")
	set_rows("dodge")
	await ticks(2)
	check(hud.get_line_count() == 5 and hud.text.contains("滑步 · 连续 2 / 3"), "dodge state shows five HUD rows")
	await layout("dodge five rows 1920x1080")
	set_rows("idle")
	await ticks(2)
	check(hud.get_line_count() == 4 and not hud.text.contains("恢复中"), "idle state drops to four HUD rows")
	await layout("idle four rows 1920x1080")
	set_rows("healing")
	await ticks(2)
	check(hud.get_line_count() == 5, "healing switches back to five rows")
	await layout("four to five rows 1920x1080")
	ui.call("save_failed", "")
	await ticks(2)
	check(error.text.is_empty() and not error.is_visible_in_tree() and hud.get_global_transform_with_canvas().origin == Vector2(64, 258), "clearing the error hides it and keeps HUD in place")
	await layout("cleared error 1920x1080")
	ui.call("save_failed", SHORT_ERROR)
	await ticks(2)
	check(error.is_visible_in_tree() and error.text == SHORT_ERROR, "error prompt reappears after clearing")
	await layout("reappeared error 1920x1080")
	ui.call("save_failed", LONG_ERROR)
	await layout("long Chinese error five rows 1920x1080")
	check(error.get_line_count() >= 2 and screen_rect(error).end.x <= 1920 * 0.75, "long Chinese error wraps into a readable column")
	session.player.life.health = 1
	await ticks(2)
	check(hud.modulate == Color(1, 0.5, 0.4), "low health color still applies to HUD")
	session.player.life.health = session.player.life.config.max_health
	await viewport(Vector2i(1280, 720))
	await layout("long Chinese error five rows 1280x720")
	ui.call("save_failed", SHORT_ERROR)
	set_rows("idle")
	await layout("idle four rows 1280x720")
	set_rows("healing")
	await layout("healing five rows 1280x720")
	var node: Node = hud
	var passive: bool = true
	while node != ui:
		if node is Control and (node as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE: passive = false
		node = node.get_parent()
	node = error
	while node != ui:
		if node is Control and (node as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE: passive = false
		node = node.get_parent()
	check(passive, "HUD and error never intercept mouse input")
	await viewport(Vector2i(1920, 1080))
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
