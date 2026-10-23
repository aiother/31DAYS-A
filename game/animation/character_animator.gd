class_name CharacterAnimator
extends Node
## Presentation-only observer. Manual AnimationPlayer never clocks gameplay.
@export var mapping: CharacterAnimationMap = preload("res://animation/placeholder_map.tres")
var actor: Node
var visual: Node2D
var player: AnimationPlayer
var current: Dictionary = {}
var resolved: Dictionary = {}
var elapsed: float = 0.0
var takeoff_left: float = 0.0
var land_left: float = 0.0
var land_duration: float = 0.12
var hard_land: bool = false
var respawn_left: float = 0.0
var _grounded: bool = false
var _key: String = ""
var _clip: Animation
var _rest: Transform2D
var _restore_values: Array[Dictionary] = []
var _validations: Dictionary = {}
var _neutral: Animation = CharacterAnimationMap.placeholder()
var _empty_map: CharacterAnimationMap = CharacterAnimationMap.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_physics_priority = 100
	visual = get_parent() as Node2D
	actor = visual.get_parent()
	_rest = visual.transform
	player = AnimationPlayer.new()
	player.name = "Playback"
	player.root_node = NodePath("../..")
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	player.add_animation_library("", AnimationLibrary.new())
	add_child(player)
	if actor is PlayerController:
		actor.connect("landed", _landed)
		(actor.get_node("GameplayRoot/Life") as PlayerLife).respawned.connect(_respawned)

func _landed(_speed: float, hard: bool) -> void:
	hard_land = hard
	land_duration = (actor as PlayerController).movement.hard_landing_duration if hard else 0.12
	land_left = land_duration

func _respawned() -> void:
	respawn_left = 0.25
	takeoff_left = 0.0
	land_left = 0.0

## Reject callbacks, audio and any track that can escape the visual subtree.
func safe(clip: Animation) -> bool:
	if clip == null or clip.length <= 0.0: return false
	for i: int in range(clip.get_track_count()):
		if clip.track_get_type(i) not in [Animation.TYPE_VALUE, Animation.TYPE_BEZIER]: return false
		var path: NodePath = clip.track_get_path(i)
		if path.is_absolute(): return false
		if path.get_subname_count() != 1: return false
		for n: int in range(path.get_name_count()):
			if path.get_name(n) == "..": return false
		var target: Node = visual.get_node_or_null(NodePath(path.get_concatenated_names()))
		if not target is Node2D: return false
		var property: String = path.get_subname(0)
		if property not in ["position", "rotation", "scale", "modulate", "visible", "frame", "frame_coords", "texture"]: return false
		if not target.get_property_list().any(func(value: Dictionary) -> bool: return value["name"] == property): return false
	return true

func _physics_process(delta: float) -> void:
	if get_tree().paused: return
	if actor is PlayerController:
		var body: PlayerController = actor as PlayerController
		if _grounded and not body.is_on_floor() and body.velocity.y < 0.0: takeoff_left = 0.06
		_grounded = body.is_on_floor()
	current = actor.call("animation_state")
	var map: CharacterAnimationMap = mapping if mapping != null else _empty_map
	resolved = map.resolve(current)
	if resolved["fallback"] and map.fallback == null: resolved["clip"] = _neutral
	if not _validations.has(resolved["clip"]): _validations[resolved["clip"]] = safe(resolved["clip"])
	if not _validations[resolved["clip"]]:
		resolved = {"clip": _neutral, "key": "fallback", "fallback": true}
	var clip: Animation = resolved["clip"]
	if _key != current["key"] or _clip != clip:
		player.stop()
		for entry: Dictionary in _restore_values:
			var node: Node = (entry["node"] as WeakRef).get_ref() as Node
			if is_instance_valid(node): node.set(entry["property"], entry["value"])
		_restore_values.clear()
		visual.transform = _rest
		for i: int in range(clip.get_track_count()):
			var path: NodePath = clip.track_get_path(i)
			var node: Node = visual.get_node(NodePath(path.get_concatenated_names()))
			var property: StringName = path.get_subname(0)
			_restore_values.append({"node": weakref(node), "property": property, "value": node.get(property)})
		var library: AnimationLibrary = player.get_animation_library("")
		if library.has_animation("current"): library.remove_animation("current")
		library.add_animation("current", clip)
		player.play("current")
		_key = current["key"]
		_clip = clip
		elapsed = 0.0
	elapsed += delta
	if float(current["progress"]) >= 0.0:
		player.seek(minf(float(current["progress"]) * clip.length, clip.length - 0.000001), true)
	else:
		player.advance(delta)
	takeoff_left = maxf(0.0, takeoff_left - delta)
	land_left = maxf(0.0, land_left - delta)
	respawn_left = maxf(0.0, respawn_left - delta)
