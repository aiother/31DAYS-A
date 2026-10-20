# verify-suite: {"name": "all-Room pursuit survey B", "path": "res://tests/test_pursuit_survey_b.gd", "marker": "PURSUIT_SURVEY_B_TESTS checks=", "fixed_fps": 60, "timeout": 600}
extends "res://tests/pursuit_survey.gd"
func _initialize() -> void:
	shard = 1
	run.call_deferred()
