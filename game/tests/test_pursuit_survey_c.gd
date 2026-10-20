# verify-suite: {"name": "all-Room pursuit survey C", "path": "res://tests/test_pursuit_survey_c.gd", "marker": "PURSUIT_SURVEY_C_TESTS checks=", "fixed_fps": 60, "timeout": 600}
extends "res://tests/pursuit_survey.gd"
func _initialize() -> void:
	shard = 2
	run.call_deferred()
