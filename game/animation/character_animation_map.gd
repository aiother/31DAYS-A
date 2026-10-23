class_name CharacterAnimationMap
extends Resource
## Keys are detailed animation_state().key, then its generic name.
@export var clips: Dictionary[String, Animation] = {}
@export var paths: Dictionary[String, String] = {}
@export var fallback: Animation

func resolve(state: Dictionary) -> Dictionary:
	for key: String in [str(state["key"]), str(state["name"])]:
		var clip: Animation = clips.get(key) as Animation
		var path: String = paths.get(key, "")
		if clip == null and not path.is_empty() and ResourceLoader.exists(path, "Animation"):
			clip = load(path) as Animation
		if clip != null:
			return {"clip": clip, "key": key, "fallback": false}
	return {"clip": fallback if fallback != null else placeholder(), "key": "fallback", "fallback": true}

static func placeholder() -> Animation:
	var clip: Animation = Animation.new()
	clip.length = 0.6
	clip.loop_mode = Animation.LOOP_LINEAR
	var track: int = clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(track, NodePath(".:scale"))
	clip.track_insert_key(track, 0.0, Vector2.ONE)
	clip.track_insert_key(track, 0.3, Vector2(1.015, 0.985))
	clip.track_insert_key(track, 0.6, Vector2.ONE)
	return clip
