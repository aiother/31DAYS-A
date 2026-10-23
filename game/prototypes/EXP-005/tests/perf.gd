extends SceneTree
## EXP-005 frame times with real rendering (needs a window, not headless):
## Godot --path game --resolution 1920x1080 --script res://prototypes/EXP-005/tests/perf.gd
## For each look: a quiet baseline, then eight targets struck at once three
## times; prints average and peak frame time of the 30 frames after a strike.
var preview: Control

func _initialize() -> void:
	run.call_deferred()

func frames(count: int) -> void:
	for i: int in range(count):
		await process_frame

func run() -> void:
	preview = (load("res://prototypes/EXP-005/preview.tscn") as PackedScene).instantiate() as Control
	root.add_child(preview)
	await frames(30)
	for style: int in range(3):
		preview.call("set_style", style)
		await frames(30)
		var quiet: Array[float] = []
		var last: int = Time.get_ticks_usec()
		for i: int in range(30):
			await process_frame
			var now: int = Time.get_ticks_usec()
			quiet.append((now - last) / 1000.0)
			last = now
		var rounds: Array[String] = []
		for round: int in range(3):
			for target: Dictionary in preview.get("targets"):
				target["hp"] = 3
				target["dead"] = 0.0
			preview.set("perf", {})
			preview.call("stress")
			await frames(40)
			var perf: Dictionary = preview.get("perf")
			rounds.append("avg %.2f / peak %.2f" % [float(perf.get("avg_ms", -1.0)), float(perf.get("peak_ms", -1.0))])
		var total: float = 0.0
		for value: float in quiet: total += value
		print("PERF %s quiet avg %.2f ms | strike rounds: %s" % [preview.get("effects").STYLES[style], total / quiet.size(), "; ".join(rounds)])
	quit()
