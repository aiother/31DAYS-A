class_name DialogueConfig
extends Resource
@export var speaker: String = "7 · 临时台词"
@export var first_lines: PackedStringArray = ["这里是黄金麦湖。", "前面的镇子里，还有人在等人搭把手。", "先照顾好自己，再决定接下来要走的路。"]
@export var repeat_lines: PackedStringArray = ["镇子就在前面。若还有余力，就去看看吧。"]
@export var failed_lines: PackedStringArray = ["你又回来了。麦田还在。"]
@export var characters_per_second: float = 30.0
@export var hold_speed_multiplier: float = 4.0
@export var opening_duration: float = 2.0
@export var interaction_radius: float = 110.0
