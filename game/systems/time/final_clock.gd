class_name FinalClock
extends RefCounted
const STARTED: String = "NSZC_10003_1_N004:started"
const WON: String = "NSZC_10003_1_N005:won"
const TIMEOUT: String = "NSZC_10003_1_N005:timeout"
const TALK: String = "NSZC_10003_1_N001"
const END: String = "NSZC_10003_1_N006"

static func normalize(data: Dictionary) -> void:
	data["day3_remaining"] = float(data.get("day3_remaining",1800.0))
	data["final_remaining"] = float(data.get("final_remaining",900.0))
	data["final_budget"] = float(data.get("final_budget",900.0))

static func start(data: Dictionary) -> void:
	normalize(data)
	if bool(data["events"].get(STARTED,false)):
		return
	var budget: float = minf(900,data["day3_remaining"])
	data["final_budget"] = budget
	data["final_remaining"] = budget
	data["events"][STARTED] = true

static func tick(data: Dictionary, delta: float) -> bool:
	normalize(data)
	if int(data.get("day",1))!=3 or bool(data["events"].get(WON,false)) or bool(data["events"].get(TIMEOUT,false)):
		return false
	data["day3_remaining"] = maxf(0,data["day3_remaining"]-maxf(0,delta))
	if bool(data["events"].get(STARTED,false)):
		data["final_remaining"] = maxf(0,minf(data["day3_remaining"],data["final_remaining"]-maxf(0,delta)))
		return data["final_remaining"]<=0
	return false

static func retry(data: Dictionary) -> void:
	normalize(data)
	data["events"].erase(TIMEOUT)
	data["final_remaining"] = data["final_budget"]
	data["day3_remaining"] = maxf(data["day3_remaining"],data["final_budget"])
