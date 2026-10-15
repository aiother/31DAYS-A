class_name EnemyAttackCoordinator
extends Node
## Windup and active attacks share a small attack budget; recovery frees a slot.
@export var max_attackers: int = 1
@export var corpse_limit: int = 6
var _owners: Dictionary[int, WeakRef] = {}
var _corpses: Array[WeakRef] = []

func try_acquire(actor: Node) -> bool:
	for id: int in _owners.keys():
		if _owners[id].get_ref() == null:
			_owners.erase(id)
	var id: int = actor.get_instance_id()
	if _owners.has(id):
		return true
	if _owners.size() >= max_attackers:
		return false
	_owners[id] = weakref(actor)
	return true

func release(actor: Node) -> void:
	_owners.erase(actor.get_instance_id())

func keep_corpse(actor: Node) -> bool:
	var live: Array[WeakRef] = []
	for corpse: WeakRef in _corpses:
		if corpse.get_ref() != null:
			live.append(corpse)
	_corpses = live
	if _corpses.size() >= corpse_limit:
		return false
	_corpses.append(weakref(actor))
	return true
