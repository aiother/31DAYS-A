# verify-suite: {"name": "all-Room pursuit gate-state survey E", "path": "res://tests/test_pursuit_survey_e.gd", "marker": "PURSUIT_SURVEY_E_TESTS checks=", "fixed_fps": 60, "timeout": 600}
extends "res://tests/pursuit_survey.gd"
func _initialize() -> void:
	shard = 4
	layouts_override = ["hd_20002_2_open","nszc_10002_2_return","nszc_10002_2_open","final_battlefield_open"]
	run.call_deferred()
