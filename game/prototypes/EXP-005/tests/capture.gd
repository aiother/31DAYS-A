extends SceneTree
## EXP-005 screenshots for the delivery record (needs a window, not headless):
## Godot --path game --resolution 1920x1080 --script res://prototypes/EXP-005/tests/capture.gd
## Each look gets three frames: strikes (swing, hit, enemy hurt), movement
## (dodge, poor dodge, spend, invulnerability) and outcomes (death, gain,
## heal, hurt, revive, reflect, bounce), each caught mid-animation.
var preview: Control

func _initialize() -> void:
	run.call_deferred()

func frames(count: int) -> void:
	for i: int in range(count):
		await process_frame

## screenshots/ sits beside tests/ in this prototype folder (as in EXP-004).
func folder() -> String:
	return (get_script() as Script).resource_path.get_base_dir().get_base_dir().path_join("screenshots")

func shot(name: String) -> void:
	await frames(2)
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder().path_join(name + ".png")))

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder()))
	preview = (load("res://prototypes/EXP-005/preview.tscn") as PackedScene).instantiate() as Control
	root.add_child(preview)
	await frames(3)
	preview.set("hitstop", false)
	preview.set("shake", false)
	var fx: Node2D = preview.get("effects")
	for style: int in range(4):
		preview.call("set_style", style)
		var y: float = 860.0 - 48.0
		# Strikes.
		fx.call("spawn", "swing", Vector2(660, y), Vector2.RIGHT)
		fx.call("spawn", "swing", Vector2(980, y), Vector2.UP)
		fx.call("spawn", "swing", Vector2(1300, y - 60), Vector2.DOWN)
		for x: float in [760.0, 1120.0, 1480.0]:
			fx.call("spawn", "hit", Vector2(x, y), Vector2.RIGHT)
			fx.call("spawn", "enemy_hurt", Vector2(x, y))
		await frames(4)
		await shot("style_%s_strikes" % "abcd"[style])
		fx.call("clear")
		# Movement and resources.
		fx.call("spawn", "dodge", Vector2(700, y), Vector2.RIGHT)
		fx.call("spawn", "poor_dodge", Vector2(1100, y), Vector2.RIGHT)
		fx.call("spawn", "spend", Vector2(1500, y))
		# Keep the preview from ending the loop (it follows the mock invulnerability).
		preview.set("invuln_left", 10.0)
		fx.call("spawn", "invuln", Vector2(1700, y))
		fx.call("spawn", "heal_loop", Vector2(400, y))
		await frames(6)
		await shot("style_%s_movement" % "abcd"[style])
		fx.call("clear")
		# Outcomes.
		fx.call("spawn", "enemy_death", Vector2(760, y))
		fx.call("spawn", "gain", Vector2(760, y))
		fx.call("spawn", "heal_done", Vector2(1000, y))
		fx.call("spawn", "hurt", Vector2(1240, y))
		fx.call("spawn", "revive", Vector2(1480, y))
		fx.call("spawn", "reflect", Vector2(1680, y - 80), Vector2.LEFT)
		fx.call("spawn", "bounce", Vector2(440, y))
		await frames(8)
		await shot("style_%s_outcomes" % "abcd"[style])
		fx.call("clear")
	print("CAPTURED")
	quit()
