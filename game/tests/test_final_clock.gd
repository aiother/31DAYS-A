extends SceneTree
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: "+message)
	else:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var store: SlotStore = SlotStore.new()
	var data: Dictionary = store.fresh()
	check(store.valid(data),"legacy save without clock fields remains valid")
	FinalClock.normalize(data)
	check(data["day3_remaining"]==1800 and data["final_remaining"]==900,"legacy clocks initialize from adoption without guessing played time")
	check(not FinalClock.tick(data,100) and data["day3_remaining"]==1800,"first and second day do not consume third-day clock")
	data["day"] = 3
	FinalClock.tick(data,1400)
	check(data["day3_remaining"]==400 and data["final_remaining"]==900,"third-day remaining counts before final battle")
	data["events"][RescueBattlefieldSession.RESCUE_DONE_EVENT] = true
	FinalClock.start(data)
	check(data["final_remaining"]==400 and data["final_budget"]==400 and data["events"].get(FinalClock.STARTED,false),"start uses smaller of fifteen minutes and remaining day")
	FinalClock.tick(data,50)
	FinalClock.start(data)
	check(data["final_remaining"]==350 and data["final_budget"]==400,"starting again never refills running budget")
	check(FinalClock.tick(data,350) and data["final_remaining"]==0 and data["day3_remaining"]==0,"exact zero returns timeout")
	data["events"][FinalClock.TIMEOUT] = true
	FinalClock.retry(data)
	check(data["final_remaining"]==400 and data["day3_remaining"]==400 and not data["events"].has(FinalClock.TIMEOUT),"explicit retry restores original budget and required day window")
	data["events"][FinalClock.WON] = true
	FinalClock.tick(data,100)
	check(data["final_remaining"]==400 and data["day3_remaining"]==400,"victory stops both clocks")
	check(store.valid(data),"won clock state can be saved")
	for key: String in ["day3_remaining","final_remaining","final_budget"]:
		for value: Variant in [-1,INF,NAN,true,"900",1801]:
			var bad: Dictionary = data.duplicate(true)
			bad[key] = value
			check(not store.valid(bad),"invalid clock value rejected: "+key+str(value))
	var invalid: Dictionary = data.duplicate(true)
	invalid["events"][FinalClock.TIMEOUT] = true
	check(not store.valid(invalid),"victory and timeout cannot coexist")
	invalid = data.duplicate(true)
	invalid["events"].erase(RescueBattlefieldSession.RESCUE_DONE_EVENT)
	check(not store.valid(invalid),"started clock requires completed rescue")
	invalid = store.fresh()
	invalid["events"][FinalClock.TALK] = true
	check(not store.valid(invalid),"victory dialogue requires victory")
	invalid = store.fresh()
	invalid["events"][FinalClock.END] = true
	check(not store.valid(invalid),"ending requires completed victory dialogue")
	print("FINAL_CLOCK_TESTS checks=%d failures=%d" % [checks,failures])
	quit(1 if failures else 0)
