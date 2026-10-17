class_name CampWaveConfig
extends Resource
@export var counts: PackedInt32Array = PackedInt32Array([2, 2, 3])
@export var monochrome_indices: PackedInt32Array = PackedInt32Array([-1, -1, 1])
@export var interval: float = 1.0
@export var warning: float = 0.6
@export var left_spawn: Vector2 = Vector2(592, 1280)
@export var right_spawn: Vector2 = Vector2(1328, 1280)
@export var air_spawn: Vector2 = Vector2(1248, 960)
