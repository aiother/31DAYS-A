class_name CinematicCatalog
extends RefCounted
## The shipped sequences all forbid skipping. Dialogue advance is not a skip.
const ITEMS: Dictionary = {
	"opening": {"events":["HD_10001_1_N001", "HD_10001_1_N003", "HD_10001_1_N002"], "next":"explore"},
	"boss.overlook": {"events":["HD_10004_1_N001:intro"], "commit":"entry", "next":"boss_combat"},
	"boss.parasite": {"events":["HD_20003_1_N001:intro"], "commit":"entry", "next":"boss_combat"},
	"seven.first": {"events":["TY_10001_1_N002", "TY_10001_1_N004"], "hud":true, "next":"explore", "phases":["opening", "dialogue"]},
	"seven.gaze": {"events":["TY_10001_1_N005", "TY_10001_1_N001"], "hud":true, "next":"explore"},
	"ten.rescue": {"events":["NSZC_10003_1_N002"], "hud":true, "next":"coop", "phases":["drop", "dialogue", "slash", "save", "aftermath", "reinforcements"]},
	"final.start": {"events":["NSZC_10003_1_N004:started"], "next":"final_combat"},
	"final.win": {"events":["NSZC_10003_1_N005:won"], "lock":false, "music":false, "next":"victory_interaction"},
	"final.talk": {"events":["NSZC_10003_1_N001"], "hud":true, "next":"ending"},
	"ending": {"events":["NSZC_10003_1_N006"], "hud":true, "next":"finished_sheet"},
	"ending.finished": {"events":[], "hud":true, "commit":"saved", "next":"title"},
	"world.save": {"events":[], "next":"explore"},
	"legacy.lock": {"events":[], "next":"explore"},
}
static func sequence(id: StringName) -> CinematicSequence:
	assert(ITEMS.has(String(id)), "Unknown cinematic")
	var item: Dictionary = ITEMS[String(id)]
	var value := CinematicSequence.new()
	value.id = id
	value.locks_control = bool(item.get("lock", true))
	value.hides_hud = bool(item.get("hud", false))
	value.story_music = bool(item.get("music", true))
	value.completion_events = PackedStringArray(item["events"])
	value.continuation = StringName(item["next"])
	value.commit_point = StringName(item.get("commit", "finish"))
	value.phases = PackedStringArray(item.get("phases", []))
	return value
