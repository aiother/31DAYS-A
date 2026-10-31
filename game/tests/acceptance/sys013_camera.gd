extends "res://tests/acceptance/acceptance_harness.gd"
## SYS-013: isolated save adapter; default Boss, --checkpoint supports wave entry.
func configuration() -> Dictionary:
	var snapshot: Dictionary = SlotStore.new().fresh()
	snapshot["checkpoint"] = BossSession.BOSS_CHECKPOINT
	for flag: String in [StartRoomSession.BIRTH, StartRoomSession.GUIDE, BossSession.BOSS_INTRO, ParasiteSession.PARASITE_INTRO]: snapshot["events"][flag] = true
	return {"id":"SYS-013", "marker":"SYS013_ACCEPTANCE_TESTS", "scene":preload("res://world/final_battle_session.tscn"), "snapshots":{1:snapshot}, "enter":true,
		"instructions":"SYS-013 镜头验收（独立临时槽）\n默认直达渴望俯视；波次入口用 --checkpoint=HD_20002_2_N001\n检查拉远倍率、进出过渡、读招、震动与暂停；关闭窗口清理临时存档。"}

func status_fields() -> Dictionary:
	var result: Dictionary = super.status_fields()
	result["zoom"] = (session.player.get_node("Camera2D") as Camera2D).zoom.x
	result["room"] = (session as FinalBattleSession).room.config.room_id
	return result

func settle() -> void:
	# Rendering delta, not fixed-fps simulation, drives the gameplay camera.
	await get_tree().create_timer(1.6).timeout

func self_test() -> void:
	var host: FinalBattleSession = session as FinalBattleSession
	var camera: GameplayCamera = host.player.get_node("Camera2D") as GameplayCamera
	host.room.process_mode = Node.PROCESS_MODE_DISABLED
	host.player.set_physics_process(false)
	check(host.room is BossRoom, "default adapter enters overlook Boss")
	await settle()
	check(absf(camera.zoom.x - camera.battle_zoom) < 0.005, "real Boss fight requests battle zoom")
	await capture("boss-battle")
	(host.room.get_node("Boss") as OverlookBoss).mark_defeated()
	await settle()
	check(absf(camera.zoom.x - camera.normal_zoom) < 0.005, "Boss defeat restores normal framing")
	await capture("boss-finished")
	host._change_room(CampWavesSession.WAVES_ID)
	host.room.process_mode = Node.PROCESS_MODE_DISABLED
	var camp: CampWavesRoom = host.room as CampWavesRoom
	check(camp.start_waves(), "real camp wave warning starts")
	await settle()
	check(absf(camera.zoom.x - camera.battle_zoom) < 0.005, "wave warning requests battle zoom")
	await capture("wave-warning")
	camp.phase = CampWavesRoom.Phase.COMPLETE
	await settle()
	check(absf(camera.zoom.x - camera.normal_zoom) < 0.005, "completed waves restore normal framing")
