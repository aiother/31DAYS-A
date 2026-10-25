extends RefCounted
## Test-only replacement content: no story, save or reward knowledge.
func begin(host: Node, _flow: RefCounted) -> void:
	host.set_meta("probe_begin",true)
func ready_to_tick(host: Node, _flow: RefCounted) -> bool:
	return host.player.is_on_floor()
func physics(host: Node, _flow: RefCounted, _delta: float) -> void:
	host.set_meta("probe_ticks",int(host.get_meta("probe_ticks",0))+1)
func finish(host: Node, _flow: RefCounted) -> void:
	host.set_meta("probe_finish",true)
