class_name GameAudio
extends RefCounted
## No actor/session types here: gameplay depends only on this tiny API.
## The autoload implementation may observe actors without a script cycle.
static func service(node: Node) -> Variant:
	return node.get_node_or_null("/root/AudioEvents") if is_instance_valid(node) and node.is_inside_tree() else null

static func emit_from(node: Node, event: StringName, at: Vector2 = Vector2.INF) -> void:
	var audio: Node = service(node)
	if audio != null:
		audio.call("play", event, at, node)
