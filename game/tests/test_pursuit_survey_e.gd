extends "res://tests/pursuit_survey.gd"
func _initialize() -> void:
	shard = 4
	layouts_override = ["hd_20002_2_open","nszc_10002_2_return","nszc_10002_2_open","final_battlefield_open"]
	run.call_deferred()
