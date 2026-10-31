# verify-suite: {"name": "natural day session pause persistence story rollover and timeout retry", "path": "res://tests/test_day_clock_session.gd", "marker": "DAY_CLOCK_SESSION_TESTS checks=", "fixed_fps": 60, "timeout": 60}
extends SceneTree
var checks: int = 0
var failures: int = 0
var session: FinalBattleSession
var directory: String

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error(message)

func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame
		if is_instance_valid(current_scene):
			session = current_scene as FinalBattleSession
			if session.room.has_node("Enemies"):
				for child: Node in session.room.get_node("Enemies").get_children():
					child.set_physics_process(false)

func amount() -> float:
	return DayClock.remaining(session.data)

func run() -> void:
	directory = "user://tests/day_clock_%d"%Time.get_ticks_usec()
	session = (load("res://world/final_battle_session.tscn") as PackedScene).instantiate() as FinalBattleSession
	session.save_directory = directory
	root.add_child(session)
	current_scene = session
	check(session.start_slot(1,true),"new game adopts natural clock")
	session._clock_tick(20)
	check(session.intro_active and amount()==1800,"opening fall and get-up pause clock")
	session.intro_active = false
	session.data["events"][StartRoomSession.BIRTH] = true
	session.player.life.scripted_control_locked = false
	session.player.position = session._checkpoint(StartRoomSession.CHECKPOINT).config.spawn_position
	session.player.reset_kinematics()
	await ticks(12)
	check(amount()<1800 and amount()>1799,"actual first-day physics frames consume natural time")
	var hud_now: FormalHud = session.ui.get("_hud") as FormalHud
	check(not hud_now.drawn.has("horizon") and int(hud_now.time_state()["day"])==1 and not session.get_node("DayUI").visible,"one HUD tracks the first day with the time axis hidden (UI-011)")
	var before: float = amount()
	paused = true
	await ticks(6)
	session._clock_tick(30)
	check(amount()==before,"menu pause freezes real frames and direct timer invocation")
	paused = false
	session.set_physics_process(false)
	session.intro_active = true
	session._clock_tick(10)
	check(amount()==before,"Boss/story intro pauses clock")
	session.intro_active = false
	var dialogue: DialogueConfig = load("res://data/dialogue/ten_victory.tres") as DialogueConfig
	session.dialogue_ui.start(dialogue,dialogue.first_lines)
	session._clock_tick(10)
	check(amount()==before,"ordinary optional NPC dialogue also pauses without intro flag")
	session.dialogue_ui.dismiss()
	session.dialogue_ui.show_departure()
	session._clock_tick(10)
	check(amount()==before,"permanent abandonment confirmation pauses clock")
	session.dialogue_ui.dismiss()
	session.data["day_remaining"] = 0.1
	session._clock_tick(0.1)
	session._process(0)
	check(session.data["day"]==2 and amount()==1800,"natural first day advances exactly once")
	check(session.store.load_slot(1)["day"]==2 and session.store.load_slot(1)["day_remaining"]==1800,"date crossing persists date and new-day clock atomically")
	check((session.ui.get("_hud") as FormalHud).banner_day==2 and (session.ui.get("_hud") as FormalHud).banner_left>0,"natural date change shows centered nonblocking announcement")
	check(not session.data["events"].has(FieldSession.RESCUE_FAILED) and not session.data["events"].has(FinalClock.WON),"date alone invents no NPC failure or victory")
	session.data["day_remaining"] = 123.5
	check(session.save_current() and session.start_slot(1,false),"second-day running clock can be saved and loaded")
	await ticks(4)
	check(session.data["day"]==2 and amount()<=123.5 and amount()>123,"normal load preserves current-day remaining instead of refilling")
	before = amount()
	session.player.life.take_hit(3)
	await ticks(90)
	check(amount()==before and session.player.life.state==PlayerLife.State.DEATH_MENU,"death animation and menu consume no natural time")
	check(absf(float(session.store.load_slot(1)["day_remaining"])-before)<0.000001,"death settlement persists actual remaining time within JSON float precision")
	session.ui.call("restart_challenge")
	await ticks(4)
	check(session.player.life.health==5 and amount()<=before and amount()>before-0.5,"ordinary death retry keeps clock and established full-health rule")
	session.set_physics_process(false)
	session.data["events"][FieldSession.FIELD_STORY] = true
	session.data["day_remaining"] = 88.0
	session._change_room(RavineSession.RAVINE_ID)
	await ticks(2)
	check(session.data["day"]==2 and amount()==88,"late Seven departure event does not refill naturally reached second day")
	session.data["checkpoint"] = StartRoomSession.CHECKPOINT
	session.data["day"] = 1
	session.data["day_remaining"] = 40.0
	# UI-002: one session frame publishes the rewound first day, as a real day-one save would.
	session._process(0)
	var real_directory: String = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	check(not session.activate_checkpoint(RavineSession.RAVINE_CHECKPOINT) and session.data["day"]==1 and amount()==40,"failed story cross-day write rolls back date and old remaining")
	session.store.directory = real_directory
	check(session.activate_checkpoint(RavineSession.RAVINE_CHECKPOINT) and session.data["day"]==2 and amount()==1800,"successful story cross-day initializes new day once")
	check((session.ui.get("_hud") as FormalHud).banner_day==2 and not session.dialogue_ui.notice.text.contains("第 2 日"),"main entry uses one date announcement rather than overlapping legacy notices")
	session.data["day_remaining"] = 70.0
	check(not session.activate_checkpoint(RavineSession.RAVINE_CHECKPOINT) and amount()==70,"repeated same checkpoint never restores spent time")
	session.data["day_remaining"] = 0.25
	session._clock_tick(0.25)
	check(session.data["day"]==3 and amount()==1800,"second natural day advances into existing third-day clock")
	session.data["day3_remaining"] = 151.0
	session._parasite_victory_pending = true
	var previous_day_time: float = float(session.data["day_remaining"])
	session.store.directory = real_directory.path_join("slot_1.json")
	check(not session.save_current() and amount()==151 and session.data["day_remaining"]==previous_day_time,"failed late Boss victory preserves both clock fields exactly")
	session.store.directory = real_directory
	check(session.save_current() and amount()==151,"late parasite victory grants confirmed reward without refilling third day")
	check(session.data["events"].get(ParasiteSession.DODGE_GROWTH,false),"time integration preserves Boss growth transaction")
	session._clock_tick(0.5)
	check(is_equal_approx(amount(),150.5) and session.store.load_slot(1)["day3_remaining"]==150.5,"third day counts once and periodically persists")
	session.player.life.health = 2
	session._set_balance(-7)
	var health: int = session.player.life.health
	var balance: int = session.player.possibility.balance
	session.data["day3_remaining"] = 0.01
	session._clock_tick(0.02)
	check(paused and session._timeout_active and session._exploration_timeout and session.final_ui.mode=="day_timeout","third-day exploration zero opens explicit retry feedback and freezes world")
	check(session.data["events"].get(DayClock.TIMEOUT,false) and not session.data["events"].get(FinalClock.STARTED,false),"exploration expiry does not fabricate final battle start")
	check(session.store.load_slot(1)["events"].get(DayClock.TIMEOUT,false) and session.store.load_slot(1)["day3_remaining"]==0,"exploration expiry and zero time persist")
	session.ui.call("resume_game")
	check(paused and session.final_ui.mode=="day_timeout","generic resume cannot bypass timeout")
	var pause_event: InputEventAction = InputEventAction.new()
	pause_event.action = "pause"
	pause_event.pressed = true
	Input.parse_input_event(pause_event)
	await ticks(2)
	check(paused and session.ui.get("_mode")=="","Escape cannot open a resumable menu over timeout")
	pause_event.pressed = false
	Input.parse_input_event(pause_event)
	check(session.start_slot(1,false),"expired slot remains loadable")
	await ticks(4)
	check(paused and session._exploration_timeout and amount()==0,"loading expired slot cannot silently restart the day")
	real_directory = session.store.directory
	session.store.directory = real_directory.path_join("slot_1.json")
	check(not session.retry_final_battle() and paused and amount()==0 and session.data["events"].get(DayClock.TIMEOUT,false),"failed explicit retry write retains timeout and zero remaining")
	session.store.directory = real_directory
	check(session.retry_final_battle() and not session.retry_final_battle(),"one confirmed exploration retry schedules only one reload")
	await ticks(4)
	check(not paused and not session._timeout_active and session.room is RavineRoom and amount()>1799 and amount()<=1800,"explicit retry returns actual current checkpoint with fresh third-day window")
	check(session.player.life.health==health and session.player.possibility.balance==balance,"exploration retry preserves current life and possibility")
	check(session.data["events"].get(ParasiteSession.DODGE_GROWTH,false) and not session.data["events"].has(DayClock.TIMEOUT),"retry keeps progression and removes only exploration expiry")
	var legacy: Dictionary = session.store.fresh()
	legacy["play_seconds"] = 9999999.0
	legacy["events"][StartRoomSession.BIRTH] = true
	check(session.store.save_slot(2,legacy) and session.start_slot(2,false),"independent legacy slot without timer fields loads")
	await ticks(4)
	check(session.data["day"]==1 and amount()>1799 and not session.data["events"].has(ParasiteSession.DODGE_GROWTH),"old save adopts full current day, ignores offline/historical time and stays slot isolated")
	check(session.start_slot(3,true),"third slot can start a fresh game")
	await ticks(4)
	check(session.intro_active and session.data["day"]==1 and amount()==1800,"new game starts with a full first day paused during opening")
	paused = false
	session.queue_free()
	await ticks(2)
	OS.delay_msec(250)
	for selected: int in [1,2,3]:
		for suffix: String in ["",".bak",".tmp"]:
			var path: String = directory.path_join("slot_%d.json"%selected)+suffix
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(directory)
	print("DAY_CLOCK_SESSION_TESTS checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
