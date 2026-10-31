class_name PlaceholderCinematics
extends RefCounted
## Content adapter. It never saves, changes rewards, starts waves, or completes a story.
func begin(host: Node, flow: RefCounted) -> void:
	if host == null: return
	var id: String = flow.state()["id"]
	if id == "seven.first":
		var bounds: Rect2 = host.room.config.bounds
		var camera: Camera2D = host.player.get_node("Camera2D") as Camera2D
		var half_width: float = camera.get_viewport_rect().size.x * 0.5 / camera.zoom.x
		var center: float = clampf(host.player.position.x + camera.position.x, bounds.position.x + half_width, bounds.end.x - half_width)
		var target: float = clampf(host.room.get_node("Seven").position.x, bounds.position.x + half_width, bounds.end.x - half_width)
		flow.set_value("camera_target", target - center)
	elif id == "ten.rescue":
		host.rescue_overlay.show_drop()
		host.room.ten.position.y = 160
	elif id == "ending":
		host.final_ui.show_ending(0)
func ready_to_tick(host: Node, flow: RefCounted) -> bool:
	if flow.state()["id"] != "opening": return true
	if not host.player.is_on_floor():
		flow.set_value("fall_speed", maxf(0.0, host.player.velocity.y))
		return false
	if not bool(flow.value("on_ground", false)):
		host.player.landed.emit(float(flow.value("fall_speed",0.0)), true)
	flow.set_value("on_ground", true)
	return true
func physics(host: Node, flow: RefCounted, delta: float) -> void:
	var state: Dictionary = flow.state()
	var left: float = state["remaining"]
	var elapsed: float = float(state["duration"]) - left
	var camera: Camera2D = host.player.get_node("Camera2D") as Camera2D
	match state["id"]:
		"boss.overlook":
			var actor: Variant = host.room.get_node("Boss")
			camera.offset = Vector2(0, -600 * clampf((3.5 - elapsed) / 1.5, 0, 1))
			if elapsed > float(state["duration"]) - 0.8:
				actor.position.y = move_toward(actor.position.y, actor.config.floor_y, 1200 * delta)
				camera.offset.x = sin(elapsed * 80) * 5
		"boss.parasite":
			var actor: Variant = host.room.get_node("Boss")
			camera.offset = Vector2(sin(elapsed*75)* (5 if elapsed>2 else 1),0)
			var progress: float = clampf((elapsed-2.0)/2.0,0,1)
			host.room.get_node("Corpse").position = actor.position+Vector2(-60-progress*200,-64-sin(progress*PI)*120)
			actor.get_node("VisualRoot").rotation = sin(elapsed*16)*0.025 if elapsed<2 else 0
			actor.get_node("VisualRoot").scale = Vector2(1,0.72) if elapsed<2 else Vector2.ONE
		"seven.first":
			if state["phase"] == "opening": camera.offset.x = move_toward(camera.offset.x, float(flow.value("camera_target",0.0)), 600 * delta)
		"seven.gaze":
			host.room.gaze_progress = 1.0 - left / maxf(0.001, float(state["duration"]))
			host.room.gaze_target = host.player.position + Vector2(0,-44)
		"ten.rescue":
			if state["phase"] == "drop": host.room.ten.position.y = lerpf(160,896,1-left/host.RESCUE_DIALOGUE.opening_duration)
		"ending":
			if left > 0.0: host.final_ui.show_ending(1-left/maxf(0.001,float(state["duration"])))
func frame(host: Node, flow: RefCounted, _delta: float) -> void:
	if flow.state()["id"] == "opening" and bool(flow.value("on_ground",false)):
		host.player.get_node("VisualRoot/PlaceholderSprite").rotation = -PI * 0.5 * (flow.remaining(&"opening") / maxf(0.001,host.room.config.get_up_duration))
func phase_started(host: Node, flow: RefCounted) -> void:
	if flow.state()["id"] != "ten.rescue": return
	match flow.state()["phase"]:
		"slash": host.rescue_overlay.show_slash()
		"aftermath":
			host.rescue_overlay.show_cleared(host.room.rescue_kill_count)
			host.room.get_node("StageLabel").text = "10的斩击已清除当前全部敌人"
		"reinforcements": host.rescue_overlay.show_reinforcements()
func save_failed(host: Node, flow: RefCounted) -> void:
	if flow.state()["id"] == "ten.rescue": host.rescue_overlay.show_save_retry()
func finish(host: Node, flow: RefCounted) -> void:
	if host == null: return
	match flow.state()["id"]:
		"boss.overlook", "boss.parasite", "seven.first", "seven.gaze":
			host.player.get_node("Camera2D").offset = Vector2.ZERO
			if flow.state()["id"] == "boss.parasite" and host.room.has_node("Boss/VisualRoot"):
				host.room.get_node("Boss/VisualRoot").scale = Vector2.ONE
				host.room.get_node("Boss/VisualRoot").rotation = 0
		"ten.rescue": host.rescue_overlay.hide()
