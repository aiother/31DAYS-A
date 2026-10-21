extends SceneTree
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var path: String = "res://tests/acceptance/completed_slots.gd"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--adapter="): path = argument.trim_prefix("--adapter=")
	var script: Script = load(path) as Script
	if script == null:
		quit(1)
		return
	var launcher: Node = script.new()
	root.add_child(launcher)
	launcher.connect("finished",quit)
	await launcher.call("run",OS.get_cmdline_user_args())
