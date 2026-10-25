class_name CinematicSequence
extends Resource
## Data only. Replacement presentations cannot commit gameplay by themselves.
@export var id: StringName
@export var locks_control: bool = true
@export var hides_hud: bool = false
@export var pauses_clock: bool = true
@export var story_music: bool = true
@export var skippable: bool = false
@export var completion_events: PackedStringArray = []
@export var continuation: StringName
@export var commit_point: StringName = &"finish"
@export var phases: PackedStringArray = []
@export var duration_override: float = -1.0
@export var presentation: Script = preload("res://systems/cinematics/placeholder_cinematics.gd")
