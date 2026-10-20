# verify-suite: {"name": "all-Room pursuit survey D", "path": "res://tests/test_pursuit_survey_d.gd", "marker": "PURSUIT_SURVEY_D_TESTS checks=", "fixed_fps": 60, "timeout": 600}
extends "res://tests/pursuit_survey.gd"
func _initialize() -> void:
	shard = 3
	run.call_deferred()
