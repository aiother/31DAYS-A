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
	data["play_seconds"] = 999999.0
	DayClock.normalize(data)
	check(DayClock.remaining(data)==1800 and data["day3_remaining"]==1800,"old save adopts current day without subtracting historical play time")
	check(DayClock.CONFIG.day_seconds==1800 and DayClock.CONFIG.save_interval==0.5,"day duration and periodic save are Resource driven")
	var result: Dictionary = DayClock.tick(data,1799.5)
	check(data["day"]==1 and data["day_remaining"]==0.5 and result["days"].is_empty(),"first day consumes exact elapsed game time")
	result = DayClock.tick(data,0.5)
	check(data["day"]==2 and data["day_remaining"]==1800 and result["days"]==[2],"exact first-day zero advances once and initializes second day")
	DayClock.tick(data,100)
	check(not DayClock.advance_to(data,2) and DayClock.remaining(data)==1700,"same-date story event cannot refill the current day")
	check(not DayClock.advance_to(data,1) and data["day"]==2 and DayClock.remaining(data)==1700,"late old event never rolls date back")
	check(DayClock.advance_to(data,3) and DayClock.remaining(data)==1800,"actual story cross-day initializes third day")
	data["day3_remaining"] = 87.5
	check(not DayClock.advance_to(data,3) and DayClock.remaining(data)==87.5,"late Boss victory after natural third day cannot refill time")
	result = DayClock.tick(data,20)
	check(DayClock.remaining(data)==87.5 and result["third_delta"]==20,"third-day time has exactly one consumer")
	FinalClock.tick(data,float(result["third_delta"]))
	check(DayClock.remaining(data)==67.5,"existing final clock consumes the forwarded third-day elapsed time once")
	data = store.fresh()
	result = DayClock.tick(data,3605)
	check(result["days"]==[2,3] and data["day"]==3 and result["third_delta"]==5,"large fixed delta carries remainder through both dates")
	FinalClock.tick(data,float(result["third_delta"]))
	check(data["day3_remaining"]==1795,"cross-day remainder neither lost nor double counted")
	var before: Dictionary = data.duplicate(true)
	for delta: float in [-1,NAN,INF]:
		result = DayClock.tick(data,delta)
		check(data==before and result["third_delta"]==0,"invalid or negative elapsed time cannot create or consume time "+str(delta))
	data["day3_remaining"] = 0.0
	check(DayClock.expired(data),"unstarted third day zero requires exploration timeout")
	data["events"][DayClock.TIMEOUT] = true
	check(store.valid(data),"exploration timeout is valid without inventing final-battle start")
	DayClock.retry(data)
	check(data["day3_remaining"]==1800 and not data["events"].has(DayClock.TIMEOUT) and data["day"]==3,"explicit exploration retry only resets current day")
	check(not data["events"].has(FinalClock.STARTED) and not data["events"].has(FinalClock.WON),"exploration retry cannot grant final progress")
	data["events"][RescueBattlefieldSession.RESCUE_DONE_EVENT] = true
	data["day3_remaining"] = 43.0
	FinalClock.start(data)
	check(data["final_budget"]==43,"natural time feeds existing smaller-of-fifteen-minutes budget")
	check(FinalClock.tick(data,43) and not DayClock.expired(data),"started battle uses final timeout, not exploration timeout")
	data["events"][FinalClock.TIMEOUT] = true
	FinalClock.retry(data)
	check(data["day3_remaining"]==43 and data["final_remaining"]==43,"final retry retains original budget rather than granting thirty minutes")
	for key: String in ["day_remaining","day3_remaining"]:
		for value: Variant in [-1,1801,INF,NAN,true,"1800",null]:
			var bad: Dictionary = store.fresh()
			bad[key] = value
			check(not store.valid(bad),"invalid natural clock rejected: "+key+str(value))
	for day: int in [1,2,3]:
		var invalid: Dictionary = store.fresh()
		invalid["day"] = day
		invalid["day3_remaining"] = 1.0 if day==3 else 0.0
		invalid["events"][DayClock.TIMEOUT] = true
		check(not store.valid(invalid),"exploration expiry requires third day with zero time: "+str(day))
	data["day3_remaining"] = 0.0
	data["events"][DayClock.TIMEOUT] = true
	check(not store.valid(data),"exploration timeout cannot coexist with a started final battle")
	data = store.fresh()
	data["day_remaining"] = 0.0
	result = DayClock.tick(data,0)
	check(data["day"]==2 and result["days"]==[2],"saved exact-zero day advances even at zero next delta")
	check(store.valid(data),"advanced natural state remains production-save valid")
	print("DAY_CLOCK_TESTS checks=%d failures=%d"%[checks,failures])
	quit(1 if failures else 0)
