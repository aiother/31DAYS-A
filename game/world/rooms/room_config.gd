class_name RoomConfig
extends Resource
@export var region_id: String = "Region_HD"
@export var scene_id: String = "Region_HD_Scene_10001"
@export var room_id: String = "HD_10001_1"
@export var display_name: String = "无顶深谷 · 起始区"
@export var next_room_id: String = "HD_10002_1"
@export var bounds: Rect2 = Rect2(0, 0, 1920, 1080)
@export var floor_row: int = 14
@export var ground_rows: int = 3
@export var fall_start: Vector2 = Vector2(224, 160)
# Graybox presentation tuning, not additional frozen balance rules.
@export var get_up_duration: float = 1.0
@export var guide_duration: float = 5.0
