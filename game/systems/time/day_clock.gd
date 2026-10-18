class_name DayClock
extends RefCounted
const CONFIG: DayClockConfig = preload("res://data/world/day_clock.tres")
const TIMEOUT: String = "clock:day3_timeout"

static func normalize(data: Dictionary) -> void:
	# Legacy saves adopt a full current day without estimating prior play time.
	data["day_remaining"] = float(data.get("day_remaining",CONFIG.day_seconds))
	data["day3_remaining"] = float(data.get("day3_remaining",CONFIG.day_seconds))

static func remaining(data: Dictionary) -> float:
	return float(data.get("day3_remaining" if int(data.get("day",1))==3 else "day_remaining",CONFIG.day_seconds))

static func advance_to(data: Dictionary, requested: int) -> bool:
	normalize(data)
	var next: int = clampi(requested,1,3)
	if next<=int(data.get("day",1)):
		return false
	data["day"] = next
	data["day3_remaining" if next==3 else "day_remaining"] = CONFIG.day_seconds
	return true

static func tick(data: Dictionary, delta: float) -> Dictionary:
	normalize(data)
	var changed: Array[int] = []
	var left: float = maxf(0,delta) if is_finite(delta) else 0.0
	while int(data.get("day",1))<3:
		var available: float = float(data["day_remaining"])
		if left<available:
			data["day_remaining"] = available-left
			return {"days":changed,"third_delta":0.0}
		left -= available
		advance_to(data,int(data.get("day",1))+1)
		changed.append(int(data["day"]))
	# The existing final clock remains the sole consumer of third-day time.
	return {"days":changed,"third_delta":left}

static func expired(data: Dictionary) -> bool:
	var events: Dictionary = data.get("events",{})
	return int(data.get("day",1))==3 and remaining(data)<=0 and not bool(events.get(FinalClock.STARTED,false)) and not bool(events.get(FinalClock.WON,false))

static func retry(data: Dictionary) -> void:
	data["events"].erase(TIMEOUT)
	data["day3_remaining"] = CONFIG.day_seconds
